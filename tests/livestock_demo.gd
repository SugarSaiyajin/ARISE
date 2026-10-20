extends SceneTree

# Staged construction stock and harvested wheat keep the capture concise.
# Construction, purchase, feeding, sleep, collection and shipping are real callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise08-" + name + ".png") == OK)

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
	game.state.money = 400
	game.state.materials = {"wood": 8, "stone": 6, "herb": 0}
	game.state.produce["wheat"] = 2
	game.state.player_position = game.World.COOP
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.World.COOP)
	await _capture("construction")
	await _wait(0.6)
	game._build_coop()
	game._buy_chicken()
	game._buy_chicken()
	assert(game.state.chickens == 2 and game.state.money == 140)
	await _capture("management")
	await _wait(0.7)
	game._feed_chickens()
	assert(game.state.fed_chickens == 2 and game.state.produce["wheat"] == 0)
	await _capture("fed")
	await _wait(0.6)
	game._close_modal()
	await _wait(0.8)
	await _capture("farm")
	await _walk(game.World.HOUSE - Vector2(0, 12))
	await _walk(game.AreaWorld.BED)
	await _wait(0.4)
	game._sleep()
	assert(game.state.nest_eggs == 2 and game.state.fed_chickens == 0)
	await _wait(0.4)
	await _walk(game.AreaWorld.HOUSE_EXIT)
	await _walk(game.World.COOP)
	await _capture("eggs-ready")
	await _wait(0.7)
	game._collect_eggs()
	assert(game.state.eggs == 2 and game.state.nest_eggs == 0)
	game._show_goods()
	await _capture("egg-bag")
	await _wait(0.7)
	game._close_modal()
	await _walk(game.World.BOX)
	assert(game.state.money == 252 and game.state.eggs == 0 and game.state.chickens == 2)
	await _wait(0.7)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("LIVESTOCK DEMO PASS: coop build, two hens, wheat feed, overnight eggs, collection, bag, 112-silver shipment")
	quit()
