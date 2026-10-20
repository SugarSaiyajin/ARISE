extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const TEST_SAVE := "user://farm_test_only.json"
var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	_test_farming()
	_test_growth_and_weather()
	_test_economy_and_friendship()
	_test_persistence()
	_test_navigation_and_touch()
	_test_mobile_layout()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(TEST_SAVE + suffix):
			DirAccess.remove_absolute(TEST_SAVE + suffix)
	print("FARM TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_farming() -> void:
	var s = State.new()
	check(s.plots.size() == 28, "28 farm tiles")
	check(not s.work(-1, "hoe")["ok"], "reject out-of-range plot")
	check(not s.work(99, "water")["ok"], "reject out-of-range plot")
	check(not s.work(3, "seed")["ok"], "cannot plant unprepared soil")
	check(not s.work(3, "water")["ok"], "cannot water unprepared soil")
	check(s.energy == 100, "failed actions do not spend energy")
	check(s.work(3, "hoe")["ok"], "prepare soil")
	check(s.energy == 98, "tilling costs two energy")
	check(not s.work(3, "hoe")["ok"], "cannot till twice")
	check(not s.work(3, "seed", "unknown")["ok"], "unknown seeds rejected")
	check(s.work(3, "seed", "wheat")["ok"], "plant wheat")
	check(s.seeds["wheat"] == 4 and s.energy == 97, "plant consumes seed and energy")
	check(not s.work(3, "seed")["ok"], "occupied soil rejected")
	check(not s.work(3, "harvest")["ok"], "immature crop rejected")
	check(s.work(3, "water")["ok"], "water crop")
	check(not s.work(3, "water")["ok"], "watering twice rejected")
	check(s.energy == 95, "no energy lost for invalid work")
	s.energy = 0
	check(not s.work(4, "hoe")["ok"], "exhaustion blocks work")
	s.energy = 1
	check(not s.work(4, "hoe")["ok"], "insufficient energy blocks tilling")
	s.energy = 100
	s.work(4, "hoe")
	s.seeds["turnip"] = 0
	check(not s.work(4, "seed")["ok"], "empty seed inventory rejected")
	check(not s.work(4, "invalid")["ok"], "unknown tool rejected")

func _test_growth_and_weather() -> void:
	var s = State.new()
	s.sleep()
	check(s.plots[0]["growth"] == 1, "dry crops do not grow")
	check(s.day == 2 and s.energy == 100 and s.minute == 420, "new day resets clock and energy")
	s.work(0, "water")
	s.sleep()
	check(s.is_mature(s.plots[0]), "watered crop matures overnight")
	check(not s.plots[0]["watered"], "soil dries on sunny morning")
	check(s.work(0, "harvest")["ok"], "harvest mature crop")
	check(s.produce["turnip"] == 1 and s.harvested == 1, "harvest enters inventory and quest")
	check(s.plots[0]["tilled"] and s.plots[0]["crop"] == "", "harvest preserves tilled soil")
	check(not s.work(0, "harvest")["ok"], "no duplicate harvest")
	s.sleep()
	check(s.day == 4 and s.is_raining(), "fourth day is rainy")
	check(s.plots[1]["watered"], "rain waters existing field")
	s.work(20, "hoe")
	check(s.plots[20]["watered"], "rain also waters newly prepared soil")
	s.sleep()
	check(s.is_mature(s.plots[1]), "rain contributes a growth day")
	for crop in State.CROP_ORDER:
		var farm = State.new()
		farm.work(3, "hoe")
		farm.work(3, "seed", crop)
		for n in range(State.CROPS[crop]["days"] - 1):
			farm.work(3, "water")
			farm.sleep()
		check(not farm.is_mature(farm.plots[3]), "%s not mature early" % crop)
		farm.work(3, "water")
		farm.sleep()
		check(farm.is_mature(farm.plots[3]), "%s matures on schedule" % crop)

func _test_economy_and_friendship() -> void:
	var s = State.new()
	check(not s.sell_all()["ok"] and s.money == 120, "empty shipping earns nothing")
	check(s.buy("berry", 3)["ok"], "buy three seed packs")
	check(s.money == 78 and s.seeds["berry"] == 6, "purchase accounting")
	check(not s.buy("berry", 99)["ok"] and s.money == 78, "cannot overspend")
	check(not s.buy("berry", -2)["ok"], "negative quantities rejected")
	check(not s.buy("berry", 0)["ok"], "zero quantities rejected")
	check(not s.buy("invalid")["ok"], "unknown shop item rejected")
	s.produce = {"turnip": 2, "wheat": 1, "berry": 3}
	check(s.sell_all()["ok"], "mixed produce shipment")
	check(s.money == 290 and s.total_earned == 212, "exact shipment value")
	check(s.produce.values().all(func(n): return n == 0), "shipping clears inventory")
	check(not s.sell_all()["ok"], "shipping cannot double sell")
	s.talk()
	s.talk()
	check(s.friendship == 1, "one friendship increment per day")
	s.harvested = 5
	s.talk()
	check(s.reward_claimed and s.money == 370, "quest grants eighty silver")
	s.talk()
	check(s.money == 370, "quest reward cannot repeat")
	s.sleep()
	s.talk()
	check(s.friendship == 2, "friendship can advance next day")

func _test_persistence() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(TEST_SAVE + suffix):
			DirAccess.remove_absolute(TEST_SAVE + suffix)
	var s = State.new()
	check(not s.load_game(TEST_SAVE) and s.load_notice == "", "missing save starts fresh")
	s.work(0, "water")
	s.player_position = Vector2(198, 177)
	s.friendship = 4
	s.money = 254
	check(s.save_game(TEST_SAVE) == OK, "write save")
	var restored = State.new()
	check(restored.load_game(TEST_SAVE), "read save")
	check(restored.to_data() == s.to_data(), "full state roundtrip")
	s.money = 300
	check(s.save_game(TEST_SAVE) == OK, "repeat save")
	check(FileAccess.file_exists(TEST_SAVE + ".bak"), "previous save backed up")
	var bad := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	bad.store_string("{broken")
	bad.close()
	check(restored.load_game(TEST_SAVE), "recover from corrupt primary")
	check(restored.money == 254 and restored.load_notice != "", "recovered previous valid state")
	for payload in [[], {"version": 99}, {"version": 1}]:
		check(not s._valid_data(payload), "reject malformed save")
	var data: Dictionary = s.to_data()
	data["seeds"]["turnip"] = -10
	check(not s._valid_data(data), "reject negative saved stock")
	data = s.to_data()
	data["plots"][0]["crop"] = "unknown"
	check(not s._valid_data(data), "reject unknown saved crop")
	data = s.to_data()
	data["player"] = ["oops", 10]
	check(not s._valid_data(data), "reject nonnumeric position")
	data = s.to_data()
	data["player"] = [9999, 10]
	check(not s._valid_data(data), "reject out-of-bounds position")
	data = s.to_data()
	data["energy"] = 200
	check(not s._valid_data(data), "reject invalid saved energy")
	data = s.to_data()
	data["plots"][0]["growth"] = 4
	check(not s._valid_data(data), "reject impossible crop growth")

func _test_navigation_and_touch() -> void:
	var world = load("res://scripts/farm_world.gd").new()
	check(world.blocked(Vector2(60, 100)), "house blocks walking")
	check(world.blocked(Vector2(280, 80)), "pond blocks walking")
	check(not world.blocked(Vector2(232, 200)), "spawn is walkable")
	check(world.plot_at(world.plot_center(27)) == 27, "last plot coordinate maps correctly")
	check(world.plot_at(Vector2.ZERO) == -1, "outside field has no plot")
	world.free()
	var stick = load("res://scripts/joystick.gd").new()
	stick.size = Vector2(112, 112)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(100, 56)
	touch.pressed = true
	stick._gui_input(touch)
	check(stick.direction.x == 1 and stick.direction.y == 0, "touch joystick normalizes direction")
	var other := InputEventScreenTouch.new()
	other.index = 1
	other.pressed = false
	stick._gui_input(other)
	check(stick.direction.x == 1, "second finger release does not cancel movement")
	touch.pressed = false
	stick._gui_input(touch)
	check(stick.direction == Vector2.ZERO, "active finger release stops movement")
	stick.free()
	var button = load("res://scripts/touch_button.gd").new()
	button.size = Vector2(104, 91)
	var presses := [0]
	button.pressed.connect(func(): presses[0] += 1)
	touch.index = 1
	touch.position = Vector2(40, 40)
	touch.pressed = true
	button._gui_input(touch)
	touch.pressed = false
	button._gui_input(touch)
	check(presses[0] == 1, "second finger can activate action button")
	touch.pressed = true
	button._gui_input(touch)
	touch.pressed = false
	touch.position = Vector2(-50, -50)
	button._gui_input(touch)
	check(presses[0] == 1, "releasing outside cancels touch button")
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	touch.position = Vector2(40, 40)
	touch.pressed = true
	button._gui_input(touch)
	check(presses[0] == 2 and button.is_held(), "action button activates immediately on touch")
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(-10, -10)
	button._gui_input(drag)
	check(not button.is_held(), "dragging outside stops repeated actions")
	drag.position = Vector2(40, 40)
	button._gui_input(drag)
	check(button.is_held(), "dragging back resumes hold")
	touch.pressed = false
	button._gui_input(touch)
	check(presses[0] == 2 and not button.is_held(), "press-mode release cannot duplicate action")
	touch.pressed = true
	button._gui_input(touch)
	button.cancel_touch()
	check(not button.is_held(), "background/modal cancellation clears held touch")
	button.free()

func _test_mobile_layout() -> void:
	var layout = load("res://scripts/mobile_layout.gd")
	for screen in [Vector2(960, 540), Vector2(2400, 1080), Vector2(1920, 1080), Vector2(1280, 800)]:
		for inset in [0, 24, 80]:
			var safe := Rect2(Vector2(inset, 0), screen - Vector2(inset * 2, inset))
			var frame: Rect2 = layout.fit_safe_frame(screen, safe)
			check(is_equal_approx(frame.size.x / frame.size.y, 16.0 / 9.0), "layout retains aspect ratio")
			check(safe.encloses(frame), "controls stay within simulated display safe area")
	var fallback: Rect2 = layout.fit_safe_frame(Vector2(960, 540), Rect2())
	check(fallback == Rect2(0, 0, 960, 540), "invalid safe area falls back to viewport")
