extends SceneTree

# Staged starting crop/material stock keeps the showcase focused on processing.
# All transactions, overnight progress, navigation and shipping are real callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise06-" + name + ".png") == OK)

func _walk(point: Vector2) -> void:
	game._click_world(point)
	assert(not game.path.is_empty())
	var frames := 0
	while not game.path.is_empty() and frames < 600:
		await process_frame
		frames += 1
	assert(game.path.is_empty())
	await _wait(0.45)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game.state.materials = {"wood": 4, "stone": 2, "herb": 0}
	game.state.produce["turnip"] = 3
	game.state.player_position = game.World.DRYER
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.World.DRYER)
	await _capture("construction")
	await _wait(0.5)
	game._build_dryer()
	assert(game.state.rack_built and game.state.money == 60)
	await _capture("recipes")
	await _wait(0.5)
	game._start_processing("dried_turnip", 3)
	assert(game.state.produce["turnip"] == 0 and not game.state.processing_ready())
	await _capture("pending")
	await _wait(0.5)
	game._close_modal()
	await _capture("working-farm")
	await _walk(game.World.HOUSE - Vector2(0, 12))
	assert(game.state.area_id == "house")
	await _walk(game.AreaWorld.BED)
	await _wait(0.4)
	game._sleep()
	assert(game.state.processing_ready() and game.state.day == 2)
	await _wait(0.4)
	await _walk(game.AreaWorld.HOUSE_EXIT)
	assert(game.state.area_id == "farm")
	await _walk(game.World.DRYER)
	await _capture("ready")
	await _wait(0.5)
	game._collect_processing()
	assert(game.state.goods["dried_turnip"] == 3)
	game._show_goods()
	await _capture("goods")
	await _wait(0.7)
	game._close_modal()
	await _walk(game.World.BOX)
	assert(game.state.money == 144 and game.state.goods["dried_turnip"] == 0)
	assert(game.audio_system.music.playing)
	await _wait(0.7)
	await _capture("shipped")
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("PROCESSING DEMO PASS: build, three-unit batch, real overnight, collect, ledger, shipment")
	quit()
