extends SceneTree

# Prior commission history and repair supplies are staged; all travel and rewards
# use production callbacks. No discovery or dialogue flag is pre-completed.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise09-" + name + ".png") == OK)

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
	game.state.day = 3
	game.state.requests_completed = 2
	game.state.request_completed_day = 2
	game.state.money = 200
	game.state.materials = {"wood": 6, "stone": 4, "herb": 0}
	game.state.area_id = "forest"
	game.state.player_position = Vector2(430, 147)
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.ForestWorld.ROUTE)
	await _capture("repair")
	await _wait(0.7)
	game._restore_route()
	assert(game.state.route_restored and game.state.money == 40)
	await _wait(0.5)
	game._enter_ruins()
	await _wait(0.5)
	assert(game.state.area_id == "ruins")
	await _capture("ruins")
	await _walk(game.RuinsWorld.INSCRIPTION)
	await _capture("inscription")
	await _wait(0.8)
	game._close_modal()
	await _walk(game.RuinsWorld.RELIC)
	await _capture("discovery-1")
	await _wait(0.8)
	game._show_relic(1)
	await _capture("discovery-2")
	await _wait(0.8)
	game._recover_relic()
	assert(game.state.relic_recovered and game.state.money == 160)
	await _wait(0.5)
	await _capture("recovered")
	await _walk(game.RuinsWorld.EXIT)
	assert(game.state.area_id == "forest")
	await _walk(game.ForestWorld.EXIT)
	await _walk(game.AreaWorld.FARM_EXIT)
	await _walk(game.World.HOUSE - Vector2(0, 12))
	await _walk(game.AreaWorld.JOURNAL)
	await _capture("journal")
	await _wait(0.5)
	game._show_route()
	await _capture("memory")
	await _wait(0.6)
	game._close_modal()
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("EXPLORATION DEMO PASS: repair, enter ruins, inscription, relic reward, return through forest and town, journal")
	quit()
