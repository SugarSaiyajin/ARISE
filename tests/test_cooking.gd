extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const SAVE := "user://cooking_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)

func stocked() -> RefCounted:
	var s := State.new()
	s.area_id = "house"
	s.produce = {"turnip": 2, "wheat": 1, "berry": 4}
	s.materials = {"wood": 5, "stone": 4, "herb": 2}
	s.eggs = 1
	s.fish["silver_carp"] = 1
	s.fish["mist_trout"] = 1
	return s

func _initialize() -> void:
	var s = stocked()
	var before: Dictionary = s.to_data()
	check(not s.cook("unknown")["ok"] and s.to_data() == before, "unknown recipe is atomic")
	check(not s.eat_meal("unknown")["ok"] and s.to_data() == before, "unknown dish is atomic")
	for area in ["farm", "forest", "town", "ruins"]:
		s.area_id = area
		before = s.to_data()
		check(not s.can_cook("turnip_soup") and not s.cook("turnip_soup")["ok"] and s.to_data() == before, "cooking requires farmhouse")
	s = stocked()
	s.materials["herb"] = 0
	before = s.to_data()
	check(not s.cook("turnip_soup")["ok"] and s.to_data() == before, "missing second ingredient does not consume first")
	s = stocked()
	s.produce["turnip"] = 1
	before = s.to_data()
	check(not s.cook("turnip_soup")["ok"] and s.to_data() == before, "two turnips required")
	s = stocked()
	s.produce["wheat"] = 0
	before = s.to_data()
	check(not s.cook("egg_flatbread")["ok"] and s.to_data() == before and s.seeds["wheat"] > 0, "wheat seeds are not cooking ingredients")
	s = stocked()
	s.eggs = 0
	s.nest_eggs = 3
	s.coop_built = true
	s.chickens = 1
	before = s.to_data()
	check(not s.cook("egg_flatbread")["ok"] and s.to_data() == before, "uncollected nest eggs cannot cook")
	s = stocked()
	s.fish["silver_carp"] = 0
	before = s.to_data()
	check(not s.cook("herb_fish")["ok"] and s.to_data() == before, "other fish species are not silently substituted")
	s = stocked()
	s.energy = 0
	check(s.cook("turnip_soup")["ok"] and s.meals["turnip_soup"] == 1, "cooking at zero stamina works")
	check(s.produce["turnip"] == 0 and s.materials["herb"] == 1 and s.energy == 0 and s.money == 120, "soup consumes exact ingredients without stamina or silver")
	check(s.cook("egg_flatbread")["ok"] and s.produce["wheat"] == 0 and s.eggs == 0 and s.meals["egg_flatbread"] == 1, "bread consumes wheat harvest and collected egg")
	check(s.cook("herb_fish")["ok"] and s.fish["silver_carp"] == 0 and s.materials["herb"] == 0 and s.meals["herb_fish"] == 1, "grilled fish consumes carp and herb")
	check(s.produce["berry"] == 4 and s.fish["mist_trout"] == 1 and s.materials["wood"] == 5, "unrelated inventories retained")
	before = s.to_data()
	check(not s.cook("herb_fish")["ok"] and s.to_data() == before, "repeat cook cannot reuse spent ingredients")
	check(s.eat_meal("turnip_soup")["ok"] and s.energy == 35 and s.meals["turnip_soup"] == 0, "soup restores 35 stamina")
	before = s.to_data()
	check(not s.eat_meal("turnip_soup")["ok"] and s.to_data() == before, "same serving cannot be eaten twice")
	s.area_id = "forest"
	check(s.eat_meal("egg_flatbread")["ok"] and s.energy == 80, "bread portable and restores 45")
	s.area_id = "farm"
	check(s.eat_meal("herb_fish")["ok"] and s.energy == 100 and s.meals["herb_fish"] == 0, "food restoration caps at 100")
	s.meals["herb_fish"] = 1
	before = s.to_data()
	check(not s.eat_meal("herb_fish")["ok"] and s.to_data() == before, "full stamina does not consume food")
	s.energy = 0
	check(s.eat_meal("herb_fish")["ok"] and s.energy == 40, "grilled fish restores 40")
	s.meals["turnip_soup"] = 2
	s.meals["herb_fish"] = 1
	var meals_before: Dictionary = s.meals.duplicate()
	check(s.sell_all()["ok"] and s.money == 360 and s.meals == meals_before, "mixed shipping sells berry and trout but retains meals")
	before = s.to_data()
	check(not s.sell_all()["ok"] and s.to_data() == before, "food alone is not shipped")
	s.sleep()
	check(s.meals == meals_before and s.energy == 100, "sleep retains food")
	s.energy = 22
	check(s.save_game(SAVE) == OK, "save food inventory")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "food and energy round trip")
	loaded.eat_meal("turnip_soup")
	check(s.meals["turnip_soup"] == 2 and loaded.meals["turnip_soup"] == 1, "loaded inventory independent")
	var legacy: Dictionary = s.to_data()
	legacy.erase("meals")
	check(s._valid_data(legacy), "old saves accepted")
	loaded._apply_data(legacy)
	check(loaded.meals.values().all(func(n): return n == 0) and loaded.money == s.money, "legacy defaults empty food and preserves economy")
	for bad in [null, [], "food", 3, true, {}, {"turnip_soup": 0, "egg_flatbread": 0}, {"turnip_soup": 0, "egg_flatbread": 0, "herb_fish": 0, "unknown": 1}]:
		var data: Dictionary = s.to_data()
		data["meals"] = bad
		check(not s._valid_data(data), "invalid food inventory rejected")
	for bad in [-1, 0.5, "1", true, null, NAN, INF, State.COOKING.MAX_STOCK + 1]:
		var data: Dictionary = s.to_data()
		data["meals"]["turnip_soup"] = bad
		check(not s._valid_data(data), "invalid food count rejected")
	s = stocked()
	s.meals["turnip_soup"] = State.COOKING.MAX_STOCK
	before = s.to_data()
	check(not s.cook("turnip_soup")["ok"] and s.to_data() == before, "food inventory cap blocks ingredient charge")
	s.meals["turnip_soup"] -= 1
	check(s.cook("turnip_soup")["ok"] and s.meals["turnip_soup"] == State.COOKING.MAX_STOCK and s._valid_data(s.to_data()), "last inventory slot can be filled and saved")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("COOKING TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
