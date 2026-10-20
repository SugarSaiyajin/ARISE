extends SceneTree

const World = preload("res://scripts/farm_world.gd")
const Director = preload("res://scripts/audio_director.gd")
const PREFS := "user://presentation_test_preferences.cfg"
var passed := 0
var failed := 0

func check(value: bool, description: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(PREFS + suffix):
			DirAccess.remove_absolute(PREFS + suffix)
	for pair in [[Vector2.DOWN, 0], [Vector2.LEFT, 1], [Vector2.RIGHT, 2], [Vector2.UP, 3]]:
		check(World.direction_row(pair[0]) == pair[1], "cardinal rows remain compatible")
	check(World.HERO_LAYOUT.FRAMES.size() == 8 and World.HERO_LAYOUT.FRAMES.all(func(row): return row.size() == 8), "hero atlas has eight rows and eight columns")
	check(World.QINGHE.get_size() == Vector2(256, 128), "resident uses same atlas convention")
	var hero: Image = World.HERO.get_image()
	check(hero.get_region(World.hero_region(0, 0)).get_data() != hero.get_region(World.hero_region(3, 0)).get_data(), "front and back silhouettes differ")
	check(hero.get_region(World.hero_region(0, 1)).get_data() != hero.get_region(World.hero_region(0, 3)).get_data(), "walk cycle alternates feet")
	check(World.GROUND.get_size() == Vector2(480, 270), "terrain matches navigation coordinates")
	var world := World.new()
	for tool in range(4):
		world.play_action(tool, Vector2(180, 150), "wheat")
		check(world.action_tool == tool and world.action_age == 0, "correct tool animation starts")
		world._process(0.15)
		check(world.action_age > 0 and world.action_age < World.ACTION_DURATION, "tool pose advances")
		world._process(1)
		check(world.action_age == World.ACTION_DURATION, "animation ends without accumulating")
	world.free()
	var director := Director.new()
	director.preferences_path = PREFS
	director.playback_enabled = false
	root.add_child(director)
	check(director.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music loops")
	check(is_equal_approx(director.music.stream.get_length(), 32), "music is 32 seconds")
	check(director.voices.size() == 6, "one-shot voice pool is bounded")
	for channel in ["music", "effects", "ambience"]:
		director.set_volume(channel, 0)
		check(director.volumes[channel] == 0, "channel can mute independently")
		director.set_volume(channel, 0.25)
		check(director.volumes[channel] == 0.25, "channel can restore volume")
	director.set_volume("music", 99)
	check(director.volumes["music"] == 1, "volume clamps to maximum")
	director.set_volume("effects", -5)
	check(director.volumes["effects"] == 0, "volume clamps to minimum")
	director.set_volume("music", NAN)
	check(director.volumes["music"] == 1, "invalid numeric volume is ignored")
	director.set_volume("music", 0.5)
	check(director.save_preferences() == OK, "audio preferences save separately")
	var restored := Director.new()
	restored.preferences_path = PREFS
	restored.load_preferences()
	check(restored.volumes == director.volumes, "audio preferences survive restart")
	restored.free()
	director.set_suspended("focus", true)
	director.set_suspended("application", true)
	check(director.pause_reasons.size() == 2, "background reasons tracked separately")
	director.set_suspended("focus", false)
	check(not director.pause_reasons.is_empty(), "focus alone cannot resume a background app")
	director.set_suspended("application", false)
	check(director.pause_reasons.is_empty(), "all pause reasons can clear")
	var garden: AudioStream = director.ambience.stream
	director.set_weather(true)
	check(director.ambience.stream != garden and director.rainy, "rain changes ambience")
	check(director.ambience.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "rain ambience loops")
	director.shutdown()
	director.free()
	var config := ConfigFile.new()
	config.set_value("audio", "music", "not a number")
	config.set_value("audio", "effects", -4)
	config.set_value("audio", "ambience", 0.75)
	config.save(PREFS)
	var invalid := Director.new()
	invalid.preferences_path = PREFS
	invalid.load_preferences()
	check(invalid.volumes["music"] == 0.5 and invalid.volumes["effects"] == 0.75, "invalid settings retain safe defaults")
	check(invalid.volumes["ambience"] == 0.75, "valid settings still load")
	invalid.free()
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(PREFS + suffix):
			DirAccess.remove_absolute(PREFS + suffix)
	print("PRESENTATION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
