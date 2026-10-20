extends SceneTree

# Only initial crafting supplies are staged. Casting follows real frame time;
# catches, stamina, cancellation and shipping use production callbacks.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise010-" + name + ".png") == OK)

func _walk(point: Vector2) -> void:
	game._click_world(point)
	assert(not game.path.is_empty())
	var frames := 0
	while not game.path.is_empty() and frames < 600:
		await process_frame
		frames += 1
	assert(game.path.is_empty())
	await _wait(0.3)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game.state.materials = {"wood": 4, "stone": 2, "herb": 0}
	game.state.player_position = Vector2(282, 140)
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.World.FARM_FISHING)
	await _capture("rod")
	await _wait(0.7)
	game._craft_fishing_rod()
	assert(game.state.fishing_rod and game.state.money == 40)
	await _capture("intro")
	await _wait(0.7)
	game._begin_fishing()
	await _wait(0.6)
	await _capture("waiting")
	var frames := 0
	while game.fishing_round != null and not game.fishing_round.is_biting() and frames < 180:
		await process_frame
		frames += 1
	assert(game.fishing_round != null and game.fishing_round.is_biting())
	await _capture("bite")
	var reel: Button = game.fishing_reel
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.position = Vector2(40, 40)
	press.pressed = true
	reel._gui_input(press)
	press.pressed = false
	reel._gui_input(press)
	assert(game.state.fish["silver_carp"] == 1 and game.state.energy == 98)
	await _capture("caught")
	await _wait(0.8)
	game._show_fish_bag()
	await _capture("bag")
	await _wait(0.8)
	game._show_fishing()
	game._begin_fishing()
	game._reel_fishing()
	assert(game.state.energy == 96 and game.state.fish_caught_today == 1)
	await _capture("early")
	await _wait(0.8)
	game._show_fishing()
	game._begin_fishing()
	await _wait(0.4)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	await _wait(0.5)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	assert(game.fishing_round == null and not game.state._fishing_pending and game.state.energy == 94)
	await _capture("paused")
	await _wait(0.5)
	game._close_modal()
	await _walk(game.World.BOX)
	assert(game.state.money == 72 and game.state.fish["silver_carp"] == 0)
	await _wait(0.2)
	await _capture("shipped")
	await _wait(0.8)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("FISHING DEMO PASS: craft, real-time bite, touch reel, fish bag, early failure, background cancellation, shipping")
	quit()
