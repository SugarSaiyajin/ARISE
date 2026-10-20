extends SceneTree

const Filter = preload("res://scripts/facing_filter.gd")
const State = preload("res://scripts/farm_state.gd")
var game: Node
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)

func _initialize() -> void:
	_run.call_deferred()

func touch(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 1
		event.position = Vector2(20, 20)
		event.pressed = pressed
		button._gui_input(event)

func _run() -> void:
	for row in range(8):
		var filter := Filter.new()
		var angle: float = Filter.VECTORS[row].angle()
		check(filter.select(Filter.VECTORS[row]) == row, "first input selects correct facing")
		var held := true
		for offset in [21, 24, 22, 26, 23]:
			held = held and filter.select(Vector2.from_angle(angle + deg_to_rad(offset))) == row
		check(held, "small boundary jitter retains previous direction")
		var next: int = Filter.nearest(Vector2.from_angle(angle + PI / 4))
		check(filter.select(Vector2.from_angle(angle + deg_to_rad(28))) == next, "deliberate turn crosses hysteresis margin immediately")
		held = true
		for offset in [24, 21, 18, 26]:
			held = held and filter.select(Vector2.from_angle(angle + deg_to_rad(offset))) == next
		check(held, "return boundary jitter does not flip back")
		check(filter.select(Vector2.from_angle(angle + deg_to_rad(17))) == row, "deliberate return selects original direction")
		check(filter.select(-Filter.VECTORS[row]) == Filter.nearest(-Filter.VECTORS[row]), "reversing direction has no time delay")
		filter.select(Filter.VECTORS[row], true)
		var previous: int = Filter.nearest(Vector2.from_angle(angle - PI / 4))
		check(filter.select(Vector2.from_angle(angle - deg_to_rad(26))) == row and filter.select(Vector2.from_angle(angle - deg_to_rad(28))) == previous, "negative-angle boundary also has stable margin")
		filter.select(Filter.VECTORS[row], true)
		check(filter.select(Vector2.from_angle(angle + deg_to_rad(24)), true) == next, "explicit target facing bypasses margin")
	var filter := Filter.new()
	check(filter.select(Vector2.ZERO) == 0 and not filter.initialized, "empty input does not initialize filter")
	filter.select(Vector2.LEFT)
	check(filter.select(Vector2(NAN, 0)) == 1 and filter.select(Vector2(0, INF)) == 1 and filter.select(Vector2.ZERO) == 1, "invalid or stopped input retains valid facing")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled = false
	game.audio_system.playback_enabled = false
	game.save_allowed = false
	game._close_modal()
	game.state = State.new()
	game._mount_area()
	game.state.player_position = Vector2(232, 200)
	game.stick.direction = Vector2.RIGHT
	game._process(0.01)
	var start: Vector2 = game.state.player_position
	game.stick.direction = Vector2.from_angle(deg_to_rad(24))
	game._process(0.01)
	check(game.world.facing_filter.row == 2 and game.World.direction_row(game.facing) == 5, "render hysteresis does not quantize logical movement angle")
	check(game.state.player_position.is_equal_approx(start + Vector2.from_angle(deg_to_rad(24)) * game.SPEED * 0.01), "movement follows original stick vector")
	game.stick.release_pointer()
	game._process(0.01)
	check(game.world.facing_filter.row == 2 and not game.world.walking, "idle retains stabilized facing")
	game.state.player_position = game.world.plot_center(10) - Vector2.from_angle(deg_to_rad(24)) * 14
	game.selected_tool = 0
	game._work(10)
	check(game.world.facing_filter.row == 5 and game.tool_action.active, "working snaps to actual target direction")
	game._process(0.15)
	check(game.world.facing_filter.row == 5, "working maintains target pose")
	game._show_menu()
	var snapshot: Dictionary = game.state.to_data()
	var card: Panel = game.modal.get_child(1)
	var found := false
	for child in card.get_children():
		if child is Button and child.text == "角色外觀":
			touch(child)
			found = true
	check(found and is_instance_valid(game.hero_preview), "menu touch opens character preview")
	check(not game.tool_action.active and game.hero_preview.row == 5, "preview starts from current stabilized facing")
	check(game.hero_preview.mouse_filter == Control.MOUSE_FILTER_IGNORE, "preview image does not intercept direction controls")
	check(game.preview_buttons.size() == 8, "all eight directions have controls")
	for row in range(8):
		var button: Button = game.preview_buttons[row]
		check(button.size.x >= 76 and button.size.y >= 44 and button.position.x + button.size.x <= 452 and button.position.y + button.size.y <= 264, "direction controls fit with usable touch size")
		touch(button)
		check(game.hero_preview.row == row and game.preview_direction.text.contains(game.DIRECTION_NAMES[row]), "touch chooses matching preview direction")
		game.hero_preview._process(0.2)
		check(game.hero_preview.frame_index() == 0, "standing preview uses idle pose")
	check(game.state.to_data() == snapshot and game.world.facing_filter.row == 5, "preview direction never changes player data or world facing")
	game._choose_character_direction(-1)
	game._choose_character_direction(8)
	check(game.hero_preview.row == 7, "invalid preview selection ignored")
	touch(game.preview_mode_button)
	game.hero_preview._process(0.15)
	check(game.hero_preview.motion == 1 and game.hero_preview.frame_index() == 1 and game.preview_mode_button.text.contains("步行"), "walking preview advances through actual walk frames")
	touch(game.preview_mode_button)
	game.hero_preview._process(0.15)
	check(game.hero_preview.motion == 2 and game.hero_preview.frame_index() == 6 and game.preview_mode_button.text.contains("作業"), "working preview advances through actual work poses")
	game.hero_preview._process(0.2)
	check(game.hero_preview.frame_index() == 0, "working preview rests between swings")
	touch(game.preview_mode_button)
	check(game.hero_preview.motion == 0 and game.hero_preview.frame_index() == 0, "motion choices cycle back to standing")
	var view: Control = game.hero_preview
	view._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	view._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var elapsed: float = view.elapsed
	view._process(5)
	check(view.elapsed == elapsed, "background pauses preview animation")
	view._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	view._process(5)
	check(view.elapsed == elapsed, "one resume signal cannot override remaining focus pause")
	view._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	view._process(0.1)
	check(view.elapsed > elapsed, "all pause reasons cleared resumes preview")
	elapsed = view.elapsed
	for delta in [NAN, INF, -1]:
		view._process(delta)
	check(view.elapsed == elapsed, "invalid preview frame times ignored")
	game._process(20)
	check(game.state.to_data() == snapshot, "preview keeps day clock, money, stamina and inventory unchanged")
	game._smoke_request_layout()
	card = game.modal.get_child(1)
	found = false
	for child in card.get_children():
		if child is Button and child.text == "回到選單":
			touch(child)
			found = true
	check(found and game.hero_preview == null and is_instance_valid(game.modal), "return button discards preview and restores menu")
	game._show_character()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.hero_preview == null and game.preview_buttons.is_empty() and not is_instance_valid(game.modal), "Android back closes preview and clears controls")
	check(game.state.to_data() == snapshot, "closing preview grants no gameplay effects")
	game.queue_free()
	await process_frame
	print("CHARACTER PREVIEW TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
