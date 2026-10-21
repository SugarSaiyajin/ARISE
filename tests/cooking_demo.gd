extends SceneTree

# Only raw harvests, a collected egg and a carp are staged; no finished food.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise011-" + name + ".png") == OK)

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
	game.state.area_id = "house"
	game.state.player_position = Vector2(172, 170)
	game.state.energy = 10
	game.state.produce = {"turnip": 4, "wheat": 1, "berry": 1}
	game.state.materials["herb"] = 3
	game.state.eggs = 1
	game.state.fish["silver_carp"] = 1
	game._mount_area()
	game._update_ui()
	await _wait(0.5)
	await _walk(game.AreaWorld.HEARTH)
	await _capture("hearth")
	await _wait(0.8)
	for i in range(game.State.COOKING.ORDER.size()):
		game._show_cookbook(i)
		await _capture("recipe-" + str(i))
		await _wait(0.8)
		game._cook_meal(game.State.COOKING.ORDER[i], i)
		await _wait(0.5)
	game._cook_meal("turnip_soup", 0)
	assert(game.state.meals["turnip_soup"] == 2)
	game._show_meals()
	await _capture("meals")
	await _wait(0.8)
	game._close_modal()
	await _walk(game.AreaWorld.HOUSE_EXIT)
	game._show_meals()
	var card: Panel = game.modal.get_child(1)
	var eat: Button
	for child in card.get_children():
		if child is Button and child.text == "食用" and eat == null:
			eat = child
	assert(eat != null)
	var touch := InputEventScreenTouch.new()
	touch.index = 1
	touch.position = Vector2(20, 20)
	touch.pressed = true
	eat._gui_input(touch)
	touch.pressed = false
	eat._gui_input(touch)
	assert(game.state.energy == 45 and game.state.meals["turnip_soup"] == 1)
	await _capture("eaten")
	await _wait(0.7)
	game._eat_meal("egg_flatbread")
	assert(game.state.energy == 90)
	await _wait(0.7)
	game._eat_meal("herb_fish")
	assert(game.state.energy == 100)
	game._eat_meal("turnip_soup")
	assert(game.state.meals["turnip_soup"] == 1)
	await _capture("full")
	await _wait(0.7)
	game._close_modal()
	await _walk(game.World.BOX)
	game.estate_panels.confirm_shipping()
	assert(game.state.money == 168 and game.state.meals["turnip_soup"] == 1)
	game._show_meals()
	await _capture("retained")
	await _wait(0.7)
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("COOKING DEMO PASS: farmhouse hearth, three recipes, cooking, portable touch eating, full stamina guard, shipping retains food")
	quit()
