extends SceneTree

# Paced showcase and audio integration check. Run with Godot Movie Maker and
# isolated XDG_DATA_HOME to inspect the actual mixed output, not just WAV files.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game.audio_system.preferences_path = "user://presentation_demo_audio.cfg"
	game._close_modal()
	for channel in ["music", "effects", "ambience"]:
		game.audio_system.set_volume(channel, 0.5)
	await _wait(0.6)
	assert(game.audio_system.music.playing and game.audio_system.ambience.playing)
	for key in [KEY_A, KEY_W, KEY_D, KEY_S]:
		var input := InputEventKey.new()
		input.physical_keycode = key
		input.pressed = true
		Input.parse_input_event(input)
		await _wait(0.36)
		input.pressed = false
		Input.parse_input_event(input)
		await _wait(0.1)
	game.state.player_position = game.world.plot_center(10) + Vector2(0, 14)
	game.state.plots[10] = {"tilled": false, "crop": "", "growth": 0, "watered": false}
	for tool in range(4):
		# Showcase fixture: fast-forward only the displayed crop before harvesting.
		# Production crop growth rules are exercised by the farm suite.
		if tool == 3:
			game.state.plots[10]["growth"] = 2
		game._select_tool(tool)
		await process_frame
		game._work(10)
		assert(game.world.action_tool == tool and game.world.action_age < 0.1)
		assert(game.audio_system.voices.any(func(voice): return voice.playing))
		await _wait(0.5)
	assert(game.state.produce["turnip"] == 1)
	game._show_audio_settings()
	game._cycle_volume("music")
	assert(is_equal_approx(game.audio_system.music.volume_linear, 0.75 * 0.55))
	await _wait(0.9)
	game.audio_system.set_suspended("focus", true)
	game.audio_system.set_suspended("application", true)
	assert(game.audio_system.music.stream_paused and game.audio_system.ambience.stream_paused)
	var before: int = game.audio_system.next_voice
	game.audio_system.play_effect("coin")
	assert(game.audio_system.next_voice == before)
	await _wait(0.3)
	game.audio_system.set_suspended("focus", false)
	assert(game.audio_system.music.stream_paused)
	game.audio_system.set_suspended("application", false)
	assert(not game.audio_system.music.stream_paused)
	game._close_modal()
	game.audio_system.set_weather(true)
	await _wait(0.4)
	game.audio_system.set_weather(false)
	game.audio_system.set_volume("music", 0)
	assert(game.audio_system.music.stream_paused)
	await _wait(0.2)
	game.audio_system.set_volume("music", 0.5)
	assert(not game.audio_system.music.stream_paused)
	await _wait(0.6)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("PRESENTATION DEMO PASS: paced movement, all tools, actual audio players, mute, nested background pause, weather")
	quit(0)
