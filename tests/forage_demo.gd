extends SceneTree

# Engine capture with staged starting positions to shorten return journeys.
# Gathering, gates, repair, brewing and sleep use production callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise-05-" + name + ".png") == OK)

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
	game.state.player_position = Vector2(432, 147)
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.AreaWorld.FOREST_GATE)
	assert(game.state.area_id == "forest")
	await _capture("forest")
	for node_id in game.State.FORAGE.NODES:
		await _walk(game.State.FORAGE.NODES[node_id]["position"])
	assert(game.state.materials == {"wood": 6, "stone": 4, "herb": 3})
	game._show_materials()
	await _wait(0.6)
	await _capture("materials")
	game._close_modal()
	await _capture("depleted")
	# Stage the westward journeys, still passing through both real exit gates.
	game.state.player_position = Vector2(42, 147)
	await _walk(game.ForestWorld.EXIT)
	assert(game.state.area_id == "town")
	game.state.player_position = Vector2(40, 147)
	await _walk(game.AreaWorld.FARM_EXIT)
	assert(game.state.area_id == "farm")
	game.state.player_position = Vector2(321, 196)
	await _walk(game.World.FENCE)
	await _wait(0.6)
	await _capture("repair-menu")
	game._repair_fence()
	assert(game.state.fence_repaired)
	await _wait(0.4)
	await _capture("repaired-farm")
	game.state.player_position = Vector2(91, 137)
	await _walk(game.World.HOUSE - Vector2(0, 12))
	await _walk(game.AreaWorld.HEARTH)
	await _capture("tea-menu")
	var before: int = game.state.energy
	game._brew_tea()
	assert(game.state.energy == mini(100, before + 20))
	await _wait(0.5)
	game._sleep()
	assert(game.state.gathered.is_empty() and game.state.fence_repaired)
	await _wait(0.4)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("FORAGE DEMO PASS: forest travel, eight nodes, resource bag, repair, tea, daily reset")
	quit()
