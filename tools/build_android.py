#!/usr/bin/env python3
"""Test, export and verify the Android debug APK. No release signing is used."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import zipfile

PROJECT = Path(__file__).resolve().parents[1]

def run(command, env, timeout=600):
    result = subprocess.run(command, cwd=PROJECT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stdout[-12000:])
    return result.stdout

def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def verify_apk(apk, tools, env):
    signing = run([str(tools / "apksigner"), "verify", "--verbose", str(apk)], env)
    require("Verified using v2 scheme (APK Signature Scheme v2): true" in signing,
            "APK must have a verified v2 signature.")
    run([str(tools / "zipalign"), "-c", "-P", "16", "4", str(apk)], env)
    badging = run([str(tools / "aapt"), "dump", "badging", str(apk)], env)
    require("name='org.arise.cloudbridge'" in badging, "Unexpected package identity.")
    require("sdkVersion:'24'" in badging and "targetSdkVersion:'36'" in badging,
            "Expected Android API 24 minimum and API 36 target.")
    require("native-code: 'arm64-v8a'" in badging, "Expected ARM64 APK.")
    permissions = run([str(tools / "aapt"), "dump", "permissions", str(apk)], env)
    require("uses-permission" not in permissions, "Offline prototype must not request permissions.")
    manifest = run([str(tools / "aapt"), "dump", "xmltree", str(apk), "AndroidManifest.xml"], env)
    authorities = re.findall(r'android:authorities[^\n]*="([^"]+)"', manifest)
    require(len(authorities) >= 2 and len(authorities) == len(set(authorities)),
            "Provider authorities must be unique; use Gradle export, not legacy APK rewriting.")
    require("android.intent.category.LAUNCHER" in manifest and "android.intent.action.MAIN" in manifest,
            "Launcher intent is missing.")
    require("android:screenOrientation" in manifest, "Landscape orientation must be declared.")
    elf_report = {}
    with zipfile.ZipFile(apk) as archive:
        require(archive.testzip() is None, "APK ZIP integrity check failed.")
        names = archive.namelist()
        for resource in ("ranch_data", "ranch_rules", "ranch_world", "ranch_panels", "approved_art", "approved_m_frames", "approved_f_frames", "approved_ne_frames", "animal_frames", "residents_frames", "building_frames", "item_frames", "crop_data", "stock_rules", "spring_rules", "resident_data", "map_definition", "crop_visual", "inventory_panels", "resident_panels", "spring_panels", "game", "farm_state", "farm_world", "area_world", "forest_world", "forest_data", "processing_data", "request_data", "livestock_data", "exploration_data", "ruins_world", "fishing_data", "fishing_round", "fishing_view", "cooking_data", "tool_action", "hero_frames", "facing_filter", "character_preview", "mobile_layout", "joystick", "touch_button", "audio_director"):
            require("assets/scripts/" + resource + ".gdc" in names, "Missing game script: " + resource)
        for asset in ("hero_m_approved.png", "hero_f_approved.png", "hero_ne_approved.png", "animals_approved.png", "buildings_approved.png", "residents_approved.png", "items_approved.png", "terrain_approved.png", "hero_eight.png", "qinghe.png", "farmhouse.png", "ground.png", "meals.png",
                      "fish.png", "fishing_pond.png", "ruins_ground.png", "star_relic.png", "chicken_coop.png", "hen.png", "egg.png", "tea_memory.png", "drying_rack.png", "dried_goods.png", "forest_ground.png", "forage.png", "house_interior.png", "town_ground.png", "smithy.png", "clocktower.png", "merchant.png", "smith.png",
                      "cloudbridge_waltz.wav", "garden_ambience.wav", "rain_ambience.wav"):
            require(any(asset in name for name in names), "Missing presentation asset: " + asset)
        require("assets/assets/fonts/NOTO-LICENSE.txt" in names, "Missing font license.")
        require(not any(name.startswith(("assets/tests/", "assets/docs/", "assets/tools/", "assets/build/")) for name in names),
                "Development files must not ship in the APK.")
        for name in names:
            if not name.startswith("lib/arm64-v8a/") or not name.endswith(".so"):
                continue
            data = archive.read(name)
            require(data[:6] == b"\x7fELF\x02\x01", "Expected little-endian ELF64 library.")
            offset = struct.unpack_from("<Q", data, 32)[0]
            size, count = struct.unpack_from("<HH", data, 54)
            loads = [struct.unpack_from("<IIQQQQQQ", data, offset + i * size)
                     for i in range(count)]
            loads = [segment for segment in loads if segment[0] == 1]
            compatible = bool(loads) and all(s[7] >= 16384 and (s[3] - s[2]) % 16384 == 0 for s in loads)
            require(compatible, "Native library does not support 16 KB pages: " + name)
            elf_report[name] = {"load_segment_alignments": [s[7] for s in loads], "supports_16kb": True}
    return {
        "package": "org.arise.cloudbridge", "minimum_android_api": 24,
        "target_android_api": 36, "abi": "arm64-v8a", "permissions": [],
        "signature_verification": signing.strip().splitlines(),
        "zip_alignment_16kb": True, "provider_authorities": authorities,
        "native_libraries": elf_report, "zip_integrity": "passed",
        "development_files_excluded": True, "physical_device_tested": False,
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--toolchain", type=Path, default=PROJECT.parent / "toolchains")
    args = parser.parse_args()
    root = args.toolchain.resolve()
    engine = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    require(engine, "Godot is missing.")
    require("4.6.3.stable" in run([engine, "--version"], os.environ.copy()),
            "Use Godot 4.6.3 with its matching export templates.")
    sdk = root / "android-sdk"
    tools = sdk / "build-tools/36.1.0"
    require((tools / "apksigner").exists() and (PROJECT / "android/build/build.gradle").exists(),
            "Run python3 tools/setup_android.py first.")
    java = os.environ.get("JAVA_HOME")
    if not java and (root / "jdk17/bin/javac").exists():
        java = str(root / "jdk17")
    if not java:
        executable = shutil.which("java")
        require(executable, "JDK 17+ is required.")
        java = str(Path(executable).resolve().parents[1])
    require((Path(java) / "bin/javac").exists(), "A full JDK is required, not a JRE. Run setup_android.py.")
    env = os.environ.copy()
    env["JAVA_HOME"] = java
    system_trust = Path("/etc/ssl/certs/java/cacerts")
    if system_trust.exists():
        env["JAVA_TOOL_OPTIONS"] = (env.get("JAVA_TOOL_OPTIONS", "") +
                                   " -Djavax.net.ssl.trustStore=" + str(system_trust)).strip()
    for name, directory in {
        "XDG_CONFIG_HOME": root / "godot-config", "XDG_CACHE_HOME": root / "godot-cache",
        "XDG_DATA_HOME": root / "godot-data", "GRADLE_USER_HOME": root / "gradle",
        "ANDROID_USER_HOME": root / "android-user", "ANDROID_HOME": sdk,
    }.items():
        directory.mkdir(parents=True, exist_ok=True)
        env[name] = str(directory)
    keys = root / "keys"
    keys.mkdir(exist_ok=True)
    key = keys / "android-debug.keystore"
    if not key.exists():
        # The Android standard debug key/password is deliberately not a release secret.
        run([str(Path(java) / "bin/keytool"), "-genkeypair", "-noprompt", "-keystore", str(key),
             "-storepass", "android", "-alias", "androiddebugkey", "-keypass", "android",
             "-dname", "CN=Android Debug,O=ARISE,C=TW", "-keyalg", "RSA",
             "-keysize", "2048", "-validity", "10000", "-storetype", "JKS"], env)
        key.chmod(0o600)
    config = Path(env["XDG_CONFIG_HOME"]) / "godot/editor_settings-4.6.tres"
    config.parent.mkdir(parents=True, exist_ok=True)
    # A dedicated build-only settings directory; personal editor settings are untouched.
    config.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
                      + "export/android/java_sdk_path = " + json.dumps(java) + "\n"
                      + "export/android/android_sdk_path = " + json.dumps(str(sdk)) + "\n"
                      + "export/android/debug_keystore = " + json.dumps(str(key)) + "\n"
                      + 'export/android/debug_keystore_user = "androiddebugkey"\n'
                      + 'export/android/debug_keystore_pass = "android"\n')
    print("Running import, state, mobile and scene tests...", flush=True)
    print(run([sys.executable, "tests/run_tests.py"], env, timeout=240))
    preset = (PROJECT / "export_presets.cfg").read_text()
    version = re.search(r'version/name="([0-9.]+)"', preset).group(1)
    output = PROJECT / "build/android"
    output.mkdir(parents=True, exist_ok=True)
    temporary = output / ("arise-prototype-" + version + ".pending.apk")
    final = output / ("arise-prototype-" + version + ".apk")
    print("Building Android with the official Gradle template...", flush=True)
    log = run([engine, "--headless", "--path", str(PROJECT),
               "--export-debug", "Android", str(temporary)], env, timeout=900)
    (output / "export.log").write_text(log)
    require("ERROR:" not in log, "Godot reported export errors; see build/android/export.log.")
    report = verify_apk(temporary, tools, env)
    temporary.replace(final)
    sidecar = Path(str(temporary) + ".idsig")
    if sidecar.exists():
        sidecar.unlink()
    # Legacy builds may have left an optional v4 sidecar; this APK has verified v2 signing.
    sidecar = Path(str(final) + ".idsig")
    if sidecar.exists():
        sidecar.unlink()
    report.update({"version": version, "file": final.name, "size_bytes": final.stat().st_size,
                   "sha256": hashlib.sha256(final.read_bytes()).hexdigest()})
    (output / (final.name + ".validation.json")).write_text(json.dumps(report, indent=2) + "\n")
    (output / "SHA256SUMS.txt").write_text(report["sha256"] + "  " + final.name + "\n")
    print("Verified APK:", final)
    print("SHA256:", report["sha256"])
    print("Physical device testing remains pending.")

if __name__ == "__main__":
    main()
