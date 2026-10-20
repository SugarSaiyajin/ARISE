extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const SAVE := "user://livestock_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)

func _initialize() -> void:
	var s := State.new()
	var before: Dictionary = s.to_data()
	check(not s.build_coop()["ok"] and s.to_data() == before, "missing build stock changes nothing")
	check(not s.buy_chicken()["ok"] and not s.feed_chickens()["ok"] and not s.collect_eggs()["ok"], "must build first")
	s.materials = {"wood": 8, "stone": 6, "herb": 1}
	s.money = 99
	before = s.to_data()
	check(not s.build_coop()["ok"] and s.to_data() == before, "insufficient silver preserves materials")
	s.money = 500
	s.area_id = "town"
	check(not s.build_coop()["ok"], "building only on farm")
	s.area_id = "farm"
	check(s.build_coop()["ok"] and s.coop_built and s.money == 400 and s.materials == {"wood": 0, "stone": 0, "herb": 1}, "exact construction transaction")
	before = s.to_data()
	check(not s.build_coop()["ok"] and s.to_data() == before, "cannot rebuild for repeat costs")
	check(s.buy_chicken()["ok"] and s.chickens == 1 and s.money == 320, "purchase first hen")
	before = s.to_data()
	check(not s.feed_chickens()["ok"] and s.to_data() == before and s.seeds["wheat"] == 5, "wheat seeds cannot feed hens")
	s.produce["wheat"] = 6
	check(s.feed_chickens()["ok"] and s.produce["wheat"] == 5 and s.fed_chickens == 1 and s.nest_eggs == 0, "one feed per hen; eggs not immediate")
	before = s.to_data()
	check(not s.feed_chickens()["ok"] and s.to_data() == before, "no duplicate daily feeding")
	check(s.save_game(SAVE) == OK, "save fed hens")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data() == s.to_data() and not loaded.can_feed_chickens(), "feeding persists after reload")
	check(s.buy_chicken()["ok"] and s.chickens == 2 and s.fed_chickens == 1, "new hen not automatically fed")
	check(s.feed_chickens()["ok"] and s.produce["wheat"] == 4 and s.fed_chickens == 2, "only feed newly purchased hen")
	check(s.buy_chicken()["ok"] and s.chickens == 3 and s.money == 160, "third hen purchase")
	before = s.to_data()
	check(not s.buy_chicken()["ok"] and s.to_data() == before, "three-hen capacity is atomic")
	s.sleep()
	check(s.nest_eggs == 2 and s.fed_chickens == 0 and s.chickens == 3, "only fed hens lay overnight")
	check(not s.collect_eggs()["ok"] and not s.feed_chickens()["ok"] and not s.buy_chicken()["ok"], "animal interactions require farm")
	for i in range(3):
		s.sleep()
	check(s.chickens == 3 and s.nest_eggs == 2, "unfed hens survive; stored eggs never expire or multiply")
	s.area_id = "farm"
	check(s.save_game(SAVE) == OK and loaded.load_game(SAVE) and loaded.nest_eggs == 2, "nest eggs survive restart")
	check(s.collect_eggs()["ok"] and s.eggs == 2 and s.nest_eggs == 0, "collect all nest eggs")
	before = s.to_data()
	check(not s.collect_eggs()["ok"] and s.to_data() == before, "collection cannot repeat")
	s.produce["wheat"] = 2
	before = s.to_data()
	check(not s.feed_chickens()["ok"] and s.to_data() == before, "not enough wheat consumes nothing")
	s.produce["wheat"] = 3
	s.nest_eggs = 22
	before = s.to_data()
	check(not s.can_feed_chickens() and not s.feed_chickens()["ok"] and s.to_data() == before, "reserve tomorrow's nest space before charging feed")
	s.nest_eggs = 21
	check(s.feed_chickens()["ok"] and s.produce["wheat"] == 0, "feed when nest space exactly fits")
	s.sleep()
	check(s.nest_eggs == 24, "nest reaches capacity without loss")
	s.area_id = "farm"
	s.eggs = State.LIVESTOCK.MAX_EGGS
	before = s.to_data()
	check(not s.collect_eggs()["ok"] and s.to_data() == before, "full bag preserves nest eggs")
	check(s.sell_all()["ok"] and s.eggs == 0 and s.nest_eggs == 24, "shipping leaves unclaimed nest eggs")
	s.collect_eggs()
	check(s.eggs == 24 and s.nest_eggs == 0, "can collect after making bag space")
	s.eggs = 3
	s.produce["turnip"] = 1
	s.goods["dried_berry"] = 1
	var cash: int = s.money
	var earnings: int = s.total_earned
	var stock: Dictionary = s.materials.duplicate()
	check(s.sell_all()["ok"] and s.money == cash + 258 and s.total_earned == earnings + 258, "raw crops, processed goods and eggs ship together")
	check(s.eggs == 0 and s.materials == stock and s.chickens == 3, "shipping never sells materials or hens")
	before = s.to_data()
	check(not s.sell_all()["ok"] and s.to_data() == before, "empty repeated shipment pays nothing")
	check(s.save_game(SAVE) == OK and loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "animal ownership and empty shipment roundtrip")
	var legacy: Dictionary = State.new().to_data()
	for key in ["coop_built", "chickens", "fed_chickens", "nest_eggs", "eggs"]:
		legacy.erase(key)
	check(s._valid_data(legacy), "0.7 saves accepted without livestock fields")
	loaded._apply_data(legacy)
	check(not loaded.coop_built and loaded.chickens == 0 and loaded.fed_chickens == 0 and loaded.nest_eggs == 0 and loaded.eggs == 0, "legacy resets livestock defaults")
	for value in [null, 1, "true"]:
		var bad: Dictionary = State.new().to_data()
		bad["coop_built"] = value
		check(not s._valid_data(bad), "invalid coop flag rejected")
	for key in ["chickens", "fed_chickens", "nest_eggs", "eggs"]:
		for value in [null, "1", -1, 0.5, INF, 100000001]:
			var bad: Dictionary = State.new().to_data()
			bad[key] = value
			check(not s._valid_data(bad), "malformed animal count rejected")
	var bad: Dictionary = State.new().to_data()
	bad["chickens"] = 1
	check(not s._valid_data(bad), "unbuilt coop cannot own hen")
	bad["coop_built"] = true
	bad["fed_chickens"] = 2
	check(not s._valid_data(bad), "fed count cannot exceed hens")
	bad["fed_chickens"] = 1
	bad["nest_eggs"] = 24
	check(not s._valid_data(bad), "pending eggs cannot overflow nest")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("LIVESTOCK TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
