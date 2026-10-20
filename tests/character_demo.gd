extends SceneTree

# The starting location is staged; all facing and preview controls are production.
var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _capture(name: String) -> void:
	game.toast_time = 0
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/arise014-" + name + ".png") == OK)

func _touch(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 1
		event.position = Vector2(20, 20)
		event.pressed = pressed
		button._gui_input(event)

func _stick(angle: float, pressed: bool = true) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = game.stick.size / 2 + Vector2.from_angle(deg_to_rad(angle)) * 38
	# After the initial press, use drag to update the same held finger.
	if pressed and game.stick.finger == 0:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = event.position
		game.stick._gui_input(drag)
	else:
		event.pressed = pressed
		game.stick._gui_input(event)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game._mount_area()
	game.state.player_position = Vector2(220, 180)
	game._update_ui()
	await _wait(0.4)
	_stick(0)
	await _wait(0.1)
	for angle in [21, 24, 20, 26, 23]:
		_stick(angle)
		await _wait(0.12)
		assert(game.world.facing_filter.row == 2)
	await _capture("stable")
	_stick(28)
	await _wait(0.12)
	assert(game.world.facing_filter.row == 5)
	await _capture("turned")
	for angle in [26, 23, 19]:
		_stick(angle)
		await _wait(0.12)
		assert(game.world.facing_filter.row == 5)
	_stick(17)
	await _wait(0.12)
	assert(game.world.facing_filter.row == 2)
	_stick(17, false)
	game._show_menu()
	var card: Panel = game.modal.get_child(1)
	for child in card.get_children():
		if child is Button and child.text == "角色外觀":
			_touch(child)
	assert(game.hero_preview != null)
	var minute: float = game.state.minute
	var names := ["front", "left", "right", "back", "front-left", "front-right", "back-left", "back-right"]
	for row in [0, 5, 2, 7, 3, 6, 1, 4]:
		_touch(game.preview_buttons[row])
		await _wait(0.18)
		await _capture(names[row])
		assert(game.hero_preview.row == row)
	_touch(game.preview_buttons[5])
	_touch(game.preview_mode_button)
	await _wait(0.18)
	await _capture("walking")
	await _wait(0.4)
	_touch(game.preview_mode_button)
	await _wait(0.1)
	await _capture("working")
	await _wait(0.7)
	assert(game.state.minute == minute and game.state.energy == 100 and game.state.money == 120)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	game.hero_preview._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	var elapsed: float = game.hero_preview.elapsed
	await _wait(0.3)
	assert(game.hero_preview.elapsed == elapsed)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	game.hero_preview._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	card = game.modal.get_child(1)
	for child in card.get_children():
		if child is Button and child.text == "回到選單":
			_touch(child)
	assert(game.hero_preview == null)
	game._close_modal()
	await _wait(0.3)
	assert(game.path.is_empty() and game.state.energy == 100)
	await _capture("farm")
	game.audio_system.shutdown()
	await _wait(0.2)
	game.queue_free()
	await process_frame
	print("CHARACTER DEMO PASS: boundary stability, deliberate turn, eight preview directions, walking and working poses, paused world, background, return")
	quit()
