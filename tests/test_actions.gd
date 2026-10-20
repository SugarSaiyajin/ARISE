extends SceneTree

const Action = preload("res://scripts/tool_action.gd")
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

func reset() -> void:
	game._close_modal()
	game.state = State.new()
	game._mount_area()
	game.world.set_process(false)
	game.state.player_position = game.world.plot_center(10) + Vector2(0, 14)
	game.world.actor = game.state.player_position
	game.selected_tool = 0
	game.selected_crop = "turnip"
	game.work_cooldown = 0
	game.travel_lock = 0
	game.queued_click = null
	game._update_ui()

func touch(button: Button, pressed: bool, index: int = 1) -> void:
	var event := InputEventScreenTouch.new()
	event.position = Vector2(20, 20)
	event.index = index
	event.pressed = pressed
	button._gui_input(event)

func _run() -> void:
	var a := Action.new()
	check(not a.active and a.elapsed == Action.DURATION, "initial action is ready")
	for tool in [-1, 4]:
		check(not a.begin(tool, Vector2.ZERO, Vector2.DOWN) and not a.active, "invalid tool cannot lock actor")
	check(not a.begin(0, Vector2(INF, 0), Vector2.DOWN), "invalid target rejected")
	check(not a.begin(0, Vector2.ZERO, Vector2(NAN, 0)), "invalid facing rejected")
	check(not a.begin(0, Vector2.ZERO, Vector2.ZERO), "zero facing rejected")
	check(a.begin(2, Vector2(140, 130), Vector2(0, -2)) and a.active and a.elapsed == 0, "begin captures one action")
	check(a.tool == 2 and a.target == Vector2(140, 130) and a.facing == Vector2.UP, "snapshot normalizes facing")
	check(not a.begin(3, Vector2.ONE, Vector2.LEFT) and a.tool == 2 and a.target == Vector2(140, 130), "reentry cannot replace action")
	for delta in [0, -1, NAN, INF]:
		a.advance(delta)
	check(a.elapsed == 0 and a.active, "invalid deltas do not advance action")
	a.advance(0.15)
	check(a.active and is_equal_approx(a.elapsed, 0.15), "action remains locked halfway")
	a.advance(0.15)
	check(not a.active and a.elapsed == Action.DURATION, "exact duration releases action")
	a.advance(100)
	check(not a.active and a.elapsed == Action.DURATION, "finished action cannot restart")
	a.begin(0, Vector2.ZERO, Vector2.RIGHT)
	a.advance(10)
	check(not a.active and a.elapsed == Action.DURATION, "large frame safely completes one action")
	a.begin(1, Vector2.ZERO, Vector2.LEFT)
	a.finish()
	a.finish()
	check(not a.active and a.elapsed == Action.DURATION, "interruption is idempotent")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled = false
	game.audio_system.playback_enabled = false
	game.simulation = true
	game.save_allowed = false
	reset()
	game._work(10)
	check(game.state.plots[10]["tilled"] and game.state.energy == 98 and game.tool_action.active, "successful hoe commits once and locks")
	var before: Dictionary = game.state.to_data()
	game._work(11)
	game._act()
	check(game.state.to_data() == before and not game.state.plots[11]["tilled"], "repeat work and action button cannot double spend")
	var start: Vector2 = game.state.player_position
	var facing: Vector2 = game.facing
	game.stick.direction = Vector2.LEFT
	game._process(0.15)
	check(game.state.player_position == start and game.facing == facing and not game.world.walking, "joystick cannot move or turn mid-swing")
	check(is_equal_approx(game.world.action_age, 0.15), "render pose uses the same clock as movement lock")
	game.world._process(0.1)
	check(is_equal_approx(game.world.action_age, 0.15), "world animation does not advance action twice")
	game._select_tool(1)
	game._cycle_crop()
	check(game.selected_crop == "wheat" and game.tool_action.tool == 0 and game.world.action_tool == 0, "next tool selection does not replace current swing")
	game._process(0.15)
	check(not game.tool_action.active and game.state.player_position == start and game.facing == facing, "finishing frame remains stationary")
	game._process(0.05)
	check(game.state.player_position.x < start.x and game.facing == Vector2.LEFT, "held movement resumes after completion")
	game.stick.release_pointer()
	reset()
	game._work(10)
	var last_target: Vector2 = game.world.plot_center(12)
	game._click_world(game.world.plot_center(11))
	game._click_world(last_target)
	check(game.queued_click == last_target and game.path.is_empty(), "latest click replaces previous queued click")
	game._select_tool(1)
	game._process(Action.DURATION)
	check(game.queued_click == null and not game.path.is_empty() and game.pending.get("plot") == 12, "queued destination starts after swing")
	check(game.state.seeds["turnip"] == 8, "queuing never plants early")
	game._show_menu()
	check(game.path.is_empty() and game.queued_click == null and not game.tool_action.active, "menu clears queued movement")
	reset()
	game.state.plots[12]["tilled"] = true
	game._work(10)
	game._click_world(game.world.plot_center(11))
	game._click_world(game.world.plot_center(12))
	game._select_tool(1)
	game._process(Action.DURATION)
	var frames := 0
	while not game.path.is_empty() and frames < 300:
		game._process(1.0 / 30.0)
		frames += 1
	check(game.path.is_empty() and game.state.plots[12]["crop"] == "turnip" and game.state.plots[11]["crop"] == "", "latest queued plot executes once on actual arrival")
	check(game.state.energy == 97 and game.state.seeds["turnip"] == 7 and game.tool_action.tool == 1, "queued arrival uses selected next tool and exact resource cost")
	reset()
	game._work(10)
	start = game.state.player_position
	facing = game.facing
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game._process(0.15)
	check(game.state.player_position == start and game.facing == facing, "keyboard movement also waits during swing")
	game._process(0.15)
	game._process(0.05)
	check(game.state.player_position.x > start.x, "held keyboard resumes after swing")
	var release_key := InputEventKey.new()
	release_key.physical_keycode = KEY_D
	release_key.pressed = false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	reset()
	game._work(10)
	game._click_world(last_target)
	game._show_menu()
	check(not game.tool_action.active and game.world.action_age == Action.DURATION and game.queued_click == null, "menu ends pose and clears queued click")
	check(game.state.energy == 98 and game.state.plots[10]["tilled"], "menu retains committed work")
	game._close_modal()
	game._process(1)
	check(game.path.is_empty() and game.state.energy == 98, "closing menu cannot replay queued work")
	reset()
	game._work(10)
	game._click_world(last_target)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(not game.tool_action.active and game.queued_click == null and is_instance_valid(game.modal), "background ends pose and opens pause menu")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	game._close_modal()
	game._process(1)
	check(game.state.energy == 98 and game.path.is_empty(), "resume grants no second effect")
	reset()
	game._work(10)
	game._change_area("house")
	check(game.state.area_id == "house" and not game.tool_action.active and game.world.action_age == Action.DURATION, "area mount clears old action pose")
	check(game.state.energy == 98 and game.state.plots[10]["tilled"], "area change retains committed work")
	reset()
	game._work(10)
	game.state.minute = 1319.99
	game._process(0.02)
	check(game.state.day == 2 and game.state.area_id == "house" and not game.tool_action.active, "night sleep safely interrupts active swing")
	check(game.state.energy == 100 and game.state.plots[10]["tilled"], "sleep preserves work and restores stamina")
	reset()
	game.save_allowed = true
	game._work(10)
	var loaded := State.new()
	check(loaded.load_game("user://smoke_session.json") and loaded.energy == 98 and loaded.plots[10]["tilled"], "successful work immediately saves committed effects")
	check(not loaded.to_data().has("tool_action") and not loaded.to_data().has("queued_click"), "transient pose and input are not serialized")
	game.state = loaded
	game._mount_area()
	check(not game.tool_action.active and game.path.is_empty() and game.queued_click == null, "loading cannot replay or remain movement locked")
	game.save_allowed = false
	reset()
	before = game.state.to_data()
	game._work(9999)
	game._work(-1)
	check(game.state.to_data() == before and not game.tool_action.active, "invalid target has no effect or movement lock")
	game.state.energy = 0
	before = game.state.to_data()
	game._work(10)
	check(game.state.to_data() == before and not game.tool_action.active, "insufficient stamina never starts action")
	for tool in range(4):
		reset()
		game.selected_tool = tool
		if tool in [1, 2, 3]: game.state.plots[10]["tilled"] = true
		if tool in [2, 3]: game.state.plots[10]["crop"] = "turnip"
		if tool == 3: game.state.plots[10]["growth"] = 2
		game._work(10)
		check(game.tool_action.active and game.tool_action.tool == tool, "all four tools use action lock")
		game._process(Action.DURATION)
		var energy: int = game.state.energy
		game._work(10)
		check(not game.tool_action.active and game.state.energy == energy, "invalid repeat never restarts animation or spends stamina")
	# Hold a second-finger action press while the first finger moves the stick.
	reset()
	game.state.plots[10]["tilled"] = true
	game.state.player_position = game.world.plot_center(10) + Vector2(0, 14)
	game.facing = Vector2.UP
	game.selected_tool = 1
	game.action_button.touch_id = 1
	game.action_button.touch_inside = true
	game._process(0.01)
	check(game.tool_action.active and game.state.plots[10]["crop"] == "turnip" and game.state.seeds["turnip"] == 7, "held touch starts one seed action")
	game.stick.direction = Vector2.RIGHT
	game._process(0.15)
	check(game.state.player_position == game.world.plot_center(10) + Vector2(0, 14) and game.state.seeds["turnip"] == 7, "held joystick and action do not double plant")
	game._process(0.15)
	game._process(0.06)
	check(game.state.player_position.x > game.world.plot_center(10).x, "held joystick resumes between actions")
	game._process(0.14)
	check(game.state.plots[11]["crop"] == "" and game.state.seeds["turnip"] == 7, "unprepared adjacent tile does not consume seeds")
	game.action_button.cancel_touch()
	game.stick.release_pointer()
	reset()
	game.selected_tool = 2
	game.state.player_position = game.world.plot_center(0) - Vector2(0, 14)
	game.facing = Vector2.DOWN
	touch(game.action_button, true)
	check(game.state.plots[0]["watered"] and game.state.energy == 98 and game.tool_action.active, "touch-down waters immediately")
	game._process(0.3)
	game._process(0.01)
	check(game.state.energy == 98 and not game.tool_action.active, "holding on watered tile cannot repeat effect")
	touch(game.action_button, false)
	check(not game.action_button.is_held(), "touch release clears held action")
	reset()
	game.selected_tool = 2
	game.state.player_position = game.world.plot_center(0) - Vector2(0, 14)
	game.facing = Vector2.DOWN
	touch(game.action_button, true)
	game.stick.direction = Vector2.RIGHT
	game._process(0.3)
	game._process(0.02)
	check(game.state.plots[0]["watered"] and game.state.plots[1]["watered"] and game.state.energy == 96 and game.tool_action.active, "held two-finger movement waters next tile after first swing")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(not game.action_button.is_held() and game.stick.direction == Vector2.ZERO and not game.tool_action.active, "background clears both fingers and active action")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	reset()
	game.state.area_id = "forest"
	game._mount_area()
	game.world.set_process(false)
	game.state.player_position = game.world.interactions()["gather:wood_1"]
	game._gather("wood_1")
	check(not game.world.action_managed and game.world.action_age == 0, "forest gathering retains its independent animation clock")
	var wood: int = game.state.materials["wood"]
	game._process(0.1)
	game.world._process(0.1)
	check(is_equal_approx(game.world.action_age, 0.1), "controller does not overwrite forest gathering animation")
	game._gather("wood_1")
	check(game.state.materials["wood"] == wood and is_equal_approx(game.world.action_age, 0.1), "depleted gathering point does not restart animation or award wood")
	game._show_menu()
	check(game.world.action_age == Action.DURATION, "menu also clears gathering pose")
	game.queue_free()
	await process_frame
	print("ACTION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
