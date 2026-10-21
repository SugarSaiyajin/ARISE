extends SceneTree

# Initial location and the second sowing bed are staged. The displayed crop is
# fast-forwarded only before harvest; normal multi-day growth has scene tests.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise012-" + name + ".png") == OK)

func _walk(point: Vector2) -> void:
	game._click_world(point)
	var frames := 0
	while (game.tool_action.active or not game.path.is_empty() or game.queued_click != null) and frames < 600:
		await process_frame
		frames += 1
	assert(frames < 600)

func _touch(control: Control, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	control._gui_input(event)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game._mount_area()
	game.state.player_position = game.world.plot_center(0) - Vector2(0, 14)
	game.facing = Vector2.DOWN
	game.state.plots[12]["tilled"] = true
	game._update_ui()
	await _wait(0.4)
	var start: Vector2 = game.state.player_position
	_touch(game.action_button, 1, Vector2(30, 30), true)
	_touch(game.stick, 0, game.stick.size / 2 + Vector2(38, 0), true)
	await _wait(0.1)
	assert(game.tool_action.active and game.state.player_position == start)
	await _capture("watering")
	await _wait(0.9)
	_touch(game.action_button, 1, Vector2(30, 30), false)
	_touch(game.stick, 0, game.stick.size / 2, false)
	assert(game.state.plots[0]["watered"] and game.state.plots[1]["watered"])
	await _wait(0.4)
	game._select_tool(0)
	await _walk(game.world.plot_center(10))
	assert(game.state.plots[10]["tilled"])
	# Start another real hoe action, then retain only the latest queued target.
	await _walk(game.world.plot_center(11))
	game._work(18)
	assert(game.tool_action.active)
	game._click_world(game.world.plot_center(13))
	game._click_world(game.world.plot_center(12))
	game._select_tool(1)
	assert(game.tool_action.tool == 0)
	await _capture("hoe")
	var frames := 0
	while not game.path.is_empty() or game.queued_click != null or game.tool_action.tool != 1:
		await process_frame
		frames += 1
		assert(frames < 600)
	assert(game.state.plots[12]["crop"] == "turnip" and game.state.plots[13]["crop"] == "")
	await _capture("sowing")
	await _wait(0.5)
	game._select_tool(2)
	game._work(12)
	await _capture("water-pose")
	await _wait(0.5)
	game.state.plots[12]["growth"] = 2
	game._select_tool(3)
	game._work(12)
	assert(game.state.produce["turnip"] == 1)
	await _capture("harvest")
	await _wait(0.5)
	game._select_tool(0)
	game._work(13)
	assert(game.tool_action.active and game.state.plots[13]["tilled"])
	game._click_world(game.World.BOX)
	var energy: int = game.state.energy
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	assert(not game.tool_action.active and game.queued_click == null)
	await _wait(0.4)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	await _capture("paused")
	await _wait(0.6)
	game._close_modal()
	await _wait(0.4)
	assert(game.path.is_empty() and game.state.energy == energy)
	await _walk(game.World.BOX)
	game.estate_panels.confirm_shipping()
	assert(game.state.money == 138 and game.state.produce["turnip"] == 0)
	await _capture("farm")
	await _wait(0.8)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("ACTIONS DEMO PASS: two-finger watering, four tool poses, latest click queue, background clears work, shipping")
	quit()
