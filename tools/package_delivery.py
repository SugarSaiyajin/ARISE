#!/usr/bin/env python3
"""Create a portable, verified delivery bundle; this does not publish a URL."""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

from PIL import Image

from build_android import verify_apk
import os


def main():
    project = Path(__file__).resolve().parents[1]
    version = "0.25.0"  # Last completed build; do not label unfinished work as released.
    source = project / "build/android" / f"arise-prototype-{version}.apk"
    env = os.environ.copy()
    toolchain = project.parent / "toolchains"
    env["JAVA_HOME"] = str(toolchain / "jdk17")
    env["PATH"] = env["JAVA_HOME"] + "/bin:" + env["PATH"]
    report = verify_apk(source, toolchain / "android-sdk/build-tools/36.1.0", env)
    previous = json.loads(Path(str(source) + ".validation.json").read_text())
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != previous["sha256"]:
        raise RuntimeError("APK differs from its original validation record")
    destination = project / "build/delivery" / f"arise-{version}"
    destination.mkdir(parents=True, exist_ok=True)
    files = [(source, f"arise-{version}.apk"),
             (project / "docs/estate-0.25-hub.png", "hub.png"),
             (project / "docs/estate-0.25-build-legal.png", "build-preview.png"),
             (project / "docs/estate-0.25-farm.png", "farm.png")]
    for original, name in files:
        if original.suffix == ".png":
            with Image.open(original) as picture:
                picture.verify()
        shutil.copyfile(original, destination / name)
    report.update(version=version, sha256=digest, size_bytes=source.stat().st_size,
                  original_hash_matches=True, screenshot_decode="passed",
                  delivery_url_verified=False)
    (destination / "validation.json").write_text(json.dumps(report, indent=2) + "\n")
    (destination / "README.txt").write_text(
        "異鄉田園 Android 試玩版 0.25.0\n\n"
        "解壓後將 arise-0.25.0.apk 傳到 Android 手機並安裝。\n"
        "需求：Android 7.0+、ARM64、OpenGL ES 3.0；不適用 iPhone。\n"
        "更新請覆蓋安裝，先勿解除安裝，以免刪除存檔。\n"
        "hub.png / build-preview.png / farm.png 為獨立展示存檔的實際遊戲畫面。\n"
        "右上手札 → 經營總覽，提供批量照料、出貨預覽、施工、夏季協作與目標。\n"
        "本包已檢查簽章與完整性，尚未於實體手機安裝驗證。\n"
        "工作區路徑不是公開網址；本工具只打包，不宣稱已發布下載連結。\n",
        encoding="utf-8")
    manifest = []
    for path in sorted(destination.iterdir()):
        if path.name != "SHA256SUMS.txt":
            manifest.append(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name)
    (destination / "SHA256SUMS.txt").write_text("\n".join(manifest) + "\n")
    bundle = destination.parent / (destination.name + ".zip")
    with zipfile.ZipFile(bundle, "w", compression=zipfile.ZIP_STORED) as archive:
        for path in sorted(destination.iterdir()):
            archive.write(path, destination.name + "/" + path.name)
    with zipfile.ZipFile(bundle) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Delivery ZIP integrity check failed")
    # Make only the deliverables and their ancestor directories traversable/readable.
    for directory in [project, project / "build", destination.parent, destination]:
        directory.chmod(0o755)
    for path in [*destination.iterdir(), bundle]:
        path.chmod(0o644)
    print(json.dumps({"bundle": str(bundle), "size_bytes": bundle.stat().st_size,
                      "apk_sha256": digest, "zip_integrity": "passed",
                      "published": False}, indent=2))


if __name__ == "__main__":
    main()
