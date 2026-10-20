extends SceneTree

# Starting harvest and prior friendship are staged for a concise showcase.
# Acceptance, delivery, story rewards and journal replay use production callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise07-" + name + ".png") == OK)

func _walk(point: Vector2) -> void:
	game._click_world(point)
	assert(not game.path.is_empty())
	var frames := 0
	while not game.path.is_empty() and frames < 600:
		await process_frame
		frames += 1
	assert(game.path.is_empty())
	await _wait(0.4)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game.state.area_id = "town"
	game.state.player_position = game.AreaWorld.NOTICE
	game.state.produce["turnip"] = 2
	game.state.friendship = 1
	game._mount_area()
	game._update_ui()
	await _wait(0.4)
	await _walk(game.AreaWorld.NOTICE)
	await _capture("board")
	await _wait(0.8)
	game._accept_request()
	assert(game.state.active_request == "tea_vegetables")
	await _wait(0.5)
	game._close_modal()
	await _walk(game.AreaWorld.QINGHE_POS)
	await _capture("delivery")
	await _wait(0.8)
	game._deliver_request("npc")
	assert(game.state.money == 170 and game.state.produce["turnip"] == 0)
	await _capture("receipt")
	await _wait(0.7)
	game._close_modal()
	await _walk(game.AreaWorld.QINGHE_POS)
	assert(game.state.friendship == 3)
	for page in range(3):
		game._show_tea_event(page, false)
		await _wait(1.2)
		await _capture("tea-" + str(page + 1))
	game._finish_tea_event()
	assert(game.state.tea_event_seen and game.state.materials["herb"] == 2 and game.state.friendship == 4)
	await _wait(0.5)
	await _capture("town")
	await _walk(game.AreaWorld.FARM_EXIT)
	await _walk(game.World.HOUSE - Vector2(0, 12))
	await _walk(game.AreaWorld.JOURNAL)
	await _capture("journal")
	await _wait(0.8)
	var snapshot: Dictionary = game.state.to_data()
	game._show_tea_event(0, true)
	await _wait(0.6)
	game._close_modal()
	assert(game.state.to_data() == snapshot)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("REQUESTS DEMO PASS: accept, explicit delivery, reward, tea event, journal, replay without duplicate gift")
	quit()
