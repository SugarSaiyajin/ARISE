extends SceneTree

# Staged starting positions keep this engine-rendered showcase short.
# Travel, collision, UI, sleep and playback use the production callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _walk(point: Vector2) -> void:
	game._click_world(point)
	assert(not game.path.is_empty())
	var frames := 0
	while not game.path.is_empty() and frames < 600:
		await process_frame
		frames += 1
	assert(game.path.is_empty())
	await _wait(0.45)

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise-04-" + name + ".png") == OK)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _capture("farm")
	game.state.player_position = Vector2(100, 145)
	await _walk(game.World.HOUSE - Vector2(0, 12))
	assert(game.state.area_id == "house")
	assert(game.audio_system.interior)
	await _walk(game.AreaWorld.JOURNAL)
	await _wait(0.8)
	game._close_modal()
	await _walk(game.AreaWorld.BED)
	await _wait(0.7)
	game._sleep()
	assert(game.state.day == 2 and game.state.area_id == "house")
	await _wait(0.5)
	await _capture("house")
	await _walk(game.AreaWorld.HOUSE_EXIT)
	assert(game.state.area_id == "farm")
	game.state.player_position = Vector2(423, 116)
	await _walk(game.World.TOWN_GATE)
	assert(game.state.area_id == "town" and not game.audio_system.interior)
	await _walk(game.AreaWorld.QINGHE_POS)
	await _wait(1.0)
	game._close_modal()
	await _walk(game.AreaWorld.NOTICE)
	await _wait(0.7)
	game._close_modal()
	await _walk(game.AreaWorld.MERCHANT_POS)
	assert(is_instance_valid(game.modal))
	await _wait(0.8)
	game._close_modal()
	await _walk(game.AreaWorld.SMITH_POS)
	await _wait(1)
	await _capture("smith-dialogue")
	game._close_modal()
	await _wait(0.4)
	await _capture("town")
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("TRAVEL DEMO PASS: three areas, house journal and bed, town bridge, all residents, indoor ambience")
	quit()
