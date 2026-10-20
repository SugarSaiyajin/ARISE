extends SceneTree

# Direction showcase. The four tool beds and their crop stages are fixtures;
# movement, work locking and resource changes use production callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise013-" + name + ".png") == OK)

func _stick(direction: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = game.stick.size / 2 + direction.normalized() * 38
	event.pressed = pressed
	game.stick._gui_input(event)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game._mount_area()
	game.state.player_position = Vector2(180, 140)
	game.state.plots[3] = {"tilled": false, "crop": "", "growth": 0, "watered": false}
	game.state.plots[4] = {"tilled": true, "crop": "", "growth": 0, "watered": false}
	game.state.plots[5] = {"tilled": true, "crop": "turnip", "growth": 0, "watered": false}
	game.state.plots[6] = {"tilled": true, "crop": "turnip", "growth": 2, "watered": false}
	game._update_ui()
	await _wait(0.4)
	var directions := [Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1),
		Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1)]
	var names := ["east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"]
	for i in range(8):
		_stick(directions[i], true)
		await _wait(0.12)
		assert(game.world.walking and game.World.direction_row(game.facing) == game.World.direction_row(directions[i]))
		await _capture(names[i])
		await _wait(0.18)
		_stick(directions[i], false)
		await _wait(0.12)
		assert(not game.world.walking and game.World.direction_row(game.facing) == game.World.direction_row(directions[i]))
		await _capture(names[i] + "-idle")
	var diagonals := [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for i in range(4):
		var target: Vector2 = game.world.plot_center(i + 3)
		game.state.player_position = target - diagonals[i].normalized() * 14
		game._select_tool(i)
		game._work(i + 3)
		assert(game.tool_action.active and game.World.direction_row(game.world.facing) == i + 4)
		await _capture("tool-" + str(i))
		await _wait(0.5)
		assert(not game.tool_action.active)
	assert(game.state.energy == 94 and game.state.produce["turnip"] == 1)
	await _capture("farm")
	await _wait(0.5)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("DIRECTIONS DEMO PASS: eight walking and idle directions, four diagonal tool poses, stable movement lock, exact resource costs")
	quit()
