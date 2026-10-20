extends SceneTree

const World = preload("res://scripts/farm_world.gd")
const State = preload("res://scripts/farm_state.gd")
const DIRECTIONS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP,
	Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]
var passed := 0
var failed := 0
var game: Node

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
	game.state.player_position = Vector2(232, 200)
	game.world.actor = game.state.player_position
	game.work_cooldown = 0
	game.travel_lock = 0

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	for i in range(DIRECTIONS.size()):
		check(World.direction_row(DIRECTIONS[i]) == i, "eight directions select independent atlas rows")
		check(World.direction_row(DIRECTIONS[i] * 0.4) == i and World.direction_row(DIRECTIONS[i] * 100) == i, "direction selection independent of stick magnitude")
	check(World.direction_row(Vector2.ZERO) == 0, "zero direction safely defaults south")
	check(World.direction_row(Vector2(NAN, 0)) == 0 and World.direction_row(Vector2(0, INF)) == 0, "nonfinite direction safely defaults south")
	for sector in range(8):
		var center: float = sector * PI / 4.0
		var middle := Vector2.from_angle(center)
		check(World.direction_row(Vector2.from_angle(center - PI / 8 + 0.001)) == World.direction_row(middle), "lower sector boundary inside correct direction")
		check(World.direction_row(Vector2.from_angle(center + PI / 8 - 0.001)) == World.direction_row(middle), "upper sector boundary inside correct direction")
		check(World.direction_row(Vector2.from_angle(center + PI / 8 + 0.001)) == World.direction_row(Vector2.from_angle(center + PI / 4)), "crossing sector boundary changes to adjacent direction")
	for pair in [[Vector2.DOWN, 0], [Vector2.LEFT, 1], [Vector2.RIGHT, 2], [Vector2.UP, 3]]:
		check(World.cardinal_row(pair[0]) == pair[1], "existing resident atlas rows remain valid")
	var sheet: Image = World.HERO.get_image()
	check(World.HERO_LAYOUT.FRAMES.size() == 8 and World.HERO_LAYOUT.FRAMES.all(func(row): return row.size() == 8), "hero layout contains eight by eight poses")
	check(sheet.detect_alpha() != Image.ALPHA_NONE, "hero sheet supports transparent background")
	for row in range(8):
		var complete := true
		for frame in range(8):
			var source := World.hero_region(row, frame)
			var rect := sheet.get_region(source).get_used_rect()
			var data: Array = World.HERO_LAYOUT.FRAMES[row][frame]
			complete = complete and rect.has_area() and Rect2i(Vector2i.ZERO, sheet.get_size()).encloses(source) and data[4] > 0 and data[4] < source.size.x and data[5] > 0 and data[5] < source.size.y
		check(complete, "each direction supplies all eight nonempty poses")
		check(sheet.get_region(World.hero_region(row, 1)).get_data() != sheet.get_region(World.hero_region(row, 3)).get_data(), "walk cycle has different left and right steps")
	for row in range(4, 8):
		var pixels := sheet.get_region(World.hero_region(row, 0)).get_data()
		check(pixels != sheet.get_region(World.hero_region(0, 0)).get_data() and pixels != sheet.get_region(World.hero_region(3, 0)).get_data(), "diagonal artwork is distinct from front and back")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled = false
	game.audio_system.playback_enabled = false
	game.save_allowed = false
	for i in range(8):
		reset()
		var start: Vector2 = game.state.player_position
		game.stick.direction = DIRECTIONS[i]
		game._process(0.1)
		check(is_equal_approx(game.state.player_position.distance_to(start), game.SPEED * 0.1), "cardinal and diagonal movement cover identical distance")
		check(World.direction_row(game.facing) == i and game.world.walking, "moving character uses matching direction")
		game.stick.release_pointer()
		game._process(0.1)
		check(World.direction_row(game.facing) == i and not game.world.walking, "stopping retains last facing and idle pose")
		reset()
		start = game.state.player_position
		game.stick.direction = DIRECTIONS[i].normalized() * 0.5
		game._process(0.1)
		check(is_equal_approx(game.state.player_position.distance_to(start), game.SPEED * 0.05), "analog half deflection gives equal speed in all directions")
	reset()
	var start: Vector2 = game.state.player_position
	key(KEY_D, true)
	key(KEY_S, true)
	game._process(0.1)
	check(World.direction_row(game.facing) == 5 and is_equal_approx(game.state.player_position.distance_to(start), game.SPEED * 0.1), "keyboard diagonal uses southeast artwork without extra speed")
	key(KEY_D, false)
	key(KEY_S, false)
	for i in range(4, 8):
		reset()
		var target: Vector2 = game.world.plot_center(10)
		game.state.player_position = target - DIRECTIONS[i].normalized() * 14
		game.selected_tool = 0
		game._work(10)
		check(game.tool_action.active and World.direction_row(game.world.facing) == i, "diagonal work selects matching tool pose")
		start = game.state.player_position
		game.stick.direction = -DIRECTIONS[i]
		game._process(0.15)
		check(game.state.player_position == start and World.direction_row(game.world.facing) == i, "diagonal tool pose retains locked direction")
		game.stick.release_pointer()
		game._process(0.15)
		game._process(0.01)
		check(not game.tool_action.active and World.direction_row(game.facing) == i and game.state.energy == 98, "diagonal work finishes once and preserves facing")
	reset()
	game.state.player_position = Vector2(469, 200)
	game.stick.direction = Vector2.RIGHT
	game._process(0.1)
	check(game.state.player_position == Vector2(469, 200) and not game.world.walking, "eight-direction movement retains map collisions")
	game.queue_free()
	await process_frame
	print("EIGHT DIRECTION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
