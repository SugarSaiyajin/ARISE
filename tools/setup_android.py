#!/usr/bin/env python3
"""Install the verified, pinned Linux Android toolchain used by this prototype."""
import argparse
import hashlib
import os
from pathlib import Path
import platform
import re
import subprocess
import tarfile
import urllib.parse
import urllib.request
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3.stable"
GODOT_SHA512 = "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
SDK_SHA1 = "5fdcc763663eefb86a5b8879697aa6088b041e70"
GRADLE_SHA256 = "f397b287023acdba1e9f6fc5ea72d22dd63669d59ed4a289a29b1a76eee151c6"
JDK_SHA256 = "0c94cbb54325c40dcf026143eb621562017db5525727f2d9131a11250f72c450"

def download(url, path, algorithm, expected):
    path.parent.mkdir(parents=True, exist_ok=True)
    def verified(candidate):
        if not candidate.is_file():
            return False
        digest = hashlib.new(algorithm)
        with candidate.open("rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(block)
        return digest.hexdigest() == expected
    if verified(path):
        print("Verified cached", path.name, flush=True)
        return
    temporary = path.with_suffix(path.suffix + ".download")
    print("Downloading official", path.name, flush=True)
    with urllib.request.urlopen(url, timeout=90) as response, temporary.open("wb") as target:
        while block := response.read(1024 * 1024):
            target.write(block)
    if not verified(temporary):
        raise RuntimeError("Checksum mismatch: " + path.name)
    temporary.replace(path)

def extract(archive, destination, prefix=""):
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as source:
        for item in source.infolist():
            if prefix and not item.filename.startswith(prefix):
                continue
            name = item.filename[len(prefix):]
            if not name:
                continue
            output = destination / name
            if not output.resolve().is_relative_to(destination.resolve()):
                raise RuntimeError("Unsafe archive path")
            if item.is_dir():
                output.mkdir(parents=True, exist_ok=True)
            else:
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(source.read(item))
                output.chmod((item.external_attr >> 16) & 0o777 or 0o644)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--toolchain", type=Path, default=PROJECT.parent / "toolchains")
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() != "x86_64":
        parser.error("This installer targets Linux x86_64. See docs/ANDROID_TESTING.md for other hosts.")
    root = args.toolchain.resolve()
    cache = root / "downloads"
    sdk_zip = cache / "android-commandline-tools.zip"
    templates = cache / "godot-4.6.3-templates.tpz"
    gradle = cache / "gradle-8.11.1-bin.zip"
    jdk_archive = cache / "temurin-jdk17.tar.gz"
    download("https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip",
             sdk_zip, "sha1", SDK_SHA1)
    download("https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz",
             templates, "sha512", GODOT_SHA512)
    download("https://services.gradle.org/distributions/gradle-8.11.1-bin.zip",
             gradle, "sha256", GRADLE_SHA256)
    download("https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.18%2B8/OpenJDK17U-jdk_x64_linux_hotspot_17.0.18_8.tar.gz",
             jdk_archive, "sha256", JDK_SHA256)
    jdk = root / "jdk17"
    if not (jdk / "bin/javac").exists():
        with tarfile.open(jdk_archive) as archive:
            directory = archive.getmembers()[0].name.split("/")[0]
            archive.extractall(root, filter="data")
        jdk.symlink_to(root / directory, target_is_directory=True)
    sdk = root / "android-sdk"
    sdkmanager = sdk / "cmdline-tools/19.0/bin/sdkmanager"
    if not sdkmanager.exists():
        extract(sdk_zip, sdk / "cmdline-tools/19.0", "cmdline-tools/")
    env = os.environ.copy()
    env["JAVA_HOME"] = str(jdk)
    system_trust = Path("/etc/ssl/certs/java/cacerts")
    if system_trust.exists():
        env["JAVA_TOOL_OPTIONS"] = (env.get("JAVA_TOOL_OPTIONS", "") +
                                   " -Djavax.net.ssl.trustStore=" + str(system_trust)).strip()
    env["ANDROID_USER_HOME"] = str(root / "android-user")
    Path(env["ANDROID_USER_HOME"]).mkdir(parents=True, exist_ok=True)
    base = [str(sdkmanager), "--sdk_root=" + str(sdk)]
    print("Accepting Android SDK licenses for this development toolchain.", flush=True)
    subprocess.run([*base, "--licenses"], input="y\n" * 100, text=True, env=env, check=True)
    subprocess.run([*base, "platform-tools", "build-tools;36.1.0",
                    "platforms;android-36", "ndk;29.0.14206865"], env=env, check=True)
    target = root / "godot-data/godot/export_templates" / VERSION
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(templates) as source:
        for name in ("android_debug.apk", "android_release.apk", "version.txt"):
            (target / name).write_bytes(source.read("templates/" + name))
        source_zip = cache / "android_source.zip"
        source_zip.write_bytes(source.read("templates/android_source.zip"))
    build = PROJECT / "android/build"
    if not (build / "build.gradle").exists():
        extract(source_zip, build)
        (PROJECT / "android/.build_version").write_text(VERSION)
        (PROJECT / "android/.gdignore").touch()
    elif (PROJECT / "android/.build_version").read_text().strip() != VERSION:
        raise RuntimeError("Existing Android build has another version; preserve local changes before upgrading.")
    # Supported wrapper settings: use the locally verified official distribution.
    props = build / "gradle/wrapper/gradle-wrapper.properties"
    text = re.sub(r"(?m)^distributionUrl=.*$", "distributionUrl=" + gradle.as_uri(), props.read_text())
    text = re.sub(r"(?m)^distributionSha256Sum=.*\n?", "", text)
    props.write_text(text.rstrip() + "\ndistributionSha256Sum=" + GRADLE_SHA256 + "\n")
    gradle_user = root / "gradle"
    gradle_user.mkdir(exist_ok=True)
    config = ["org.gradle.workers.max=3", "org.gradle.jvmargs=-Xmx3072m -Dfile.encoding=UTF-8",
              "org.gradle.daemon=false"]
    if system_trust.exists():
        config.append("systemProp.javax.net.ssl.trustStore=" + str(system_trust))
    proxy = urllib.parse.urlparse(os.environ.get("HTTPS_PROXY", ""))
    if proxy.hostname:
        if proxy.username or proxy.password:
            raise RuntimeError("Do not persist proxy credentials; configure authenticated Java proxy access separately.")
        for protocol in ("http", "https"):
            config.extend([f"systemProp.{protocol}.proxyHost={proxy.hostname}",
                           f"systemProp.{protocol}.proxyPort={proxy.port or 80}"])
    (gradle_user / "gradle.properties").write_text("\n".join(config) + "\n")
    print("Toolchain prepared. Next: python3 tools/build_android.py", flush=True)

if __name__ == "__main__":
    main()
