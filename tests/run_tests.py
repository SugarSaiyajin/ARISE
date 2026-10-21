#!/usr/bin/env python3
"""Import and test with real Godot; fail on errors even if Godot exits 0."""
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
if not ENGINE:
    sys.exit("Godot 4.6+ is required; set GODOT_BIN to its executable.")

env = os.environ.copy()
for name, folder in (
    ("XDG_CONFIG_HOME", "test-config"),
    ("XDG_CACHE_HOME", "test-cache"),
    ("XDG_DATA_HOME", "test-data"),
):
    directory = ROOT / ".godot" / folder
    directory.mkdir(parents=True, exist_ok=True)
    env[name] = str(directory)

commands = [
    (["--editor", "--import", "--quit"], None),
    (["--script", "res://tests/test_testing_panels.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_testing_panels.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_journey.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_journey_scene.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_journey_scene.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_archives.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_farm.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_presentation.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_areas.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_forage.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_processing.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_requests.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_livestock.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_exploration.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_fishing.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_cooking.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_actions.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_actions.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_eight_directions.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_eight_directions.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_character_preview.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_character_preview.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_life.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_life_scene.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_life_scene.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_ranch.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_ranch_scene.gd"], "passed, 0 failed"),
    (["--script", "res://tests/test_ranch_scene.gd", "--", "--mobile-ui"], "passed, 0 failed"),
    (["--script", "res://tests/test_spring.gd"], "passed, 0 failed"),
    (["--", "--smoke"], "SCENE SMOKE PASS"),
    (["--", "--smoke", "--mobile-ui"], "SCENE SMOKE PASS"),
]
for args, marker in commands:
    print(f"\nRunning Godot {' '.join(args)}", flush=True)
    try:
        result = subprocess.run(
            [ENGINE, "--headless", "--path", str(ROOT), *args],
            env=env, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, timeout=60,
        )
    except subprocess.TimeoutExpired as exc:
        print(exc.stdout.decode() if isinstance(exc.stdout, bytes) else exc.stdout or "")
        sys.exit("FAIL: Godot timed out.")
    print(result.stdout)
    if result.returncode or "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout:
        sys.exit(result.returncode or 1)
    if marker and marker not in result.stdout:
        sys.exit(f"FAIL: Missing completion marker: {marker}")
print("All import, state, touch and scene checks passed.")
subprocess.run([sys.executable, str(ROOT / "tests/check_audio_files.py")], env=env, check=True)
