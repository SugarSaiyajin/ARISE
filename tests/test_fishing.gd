extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Round = preload("res://scripts/fishing_round.gd")
const SAVE := "user://fishing_test_only.json"
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
	check(not s.craft_fishing_rod()["ok"] and s.to_data() == before, "missing crafting materials is atomic")
	check(not s.begin_fishing()["ok"] and s.energy == 100, "must own rod before fishing")
	s.materials = {"wood": 4, "stone": 2, "herb": 1}
	s.money = 79
	before = s.to_data()
	check(not s.craft_fishing_rod()["ok"] and s.to_data() == before, "insufficient silver consumes nothing")
	s.money = 120
	s.area_id = "town"
	check(not s.craft_fishing_rod()["ok"], "craft only at supported fishing ground")
	s.area_id = "farm"
	check(s.craft_fishing_rod()["ok"] and s.fishing_rod and s.money == 40 and s.materials == {"wood": 0, "stone": 0, "herb": 1}, "exact rod construction transaction")
	before = s.to_data()
	check(not s.craft_fishing_rod()["ok"] and s.to_data() == before, "rod crafted once")
	s.energy = 1
	check(not s.can_begin_fishing() and not s.begin_fishing()["ok"] and s.energy == 1, "insufficient energy consumes nothing")
	s.energy = 100
	s.area_id = "ruins"
	check(not s.begin_fishing()["ok"], "locked ruins cannot be a fishing ground")
	s.area_id = "farm"
	check(s.begin_fishing()["ok"] and s.energy == 98 and s._fishing_pending, "cast charges two stamina")
	check(not s.begin_fishing()["ok"] and s.energy == 98, "one pending cast at a time")
	check(s.save_game(SAVE) == OK, "save mid-cast")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.energy == 98 and not loaded._fishing_pending, "reload preserves cost but cancels unfinished cast")
	check(not loaded.finish_fishing(true)["ok"] and loaded.fish["silver_carp"] == 0, "reload cannot claim unearned fish")
	s.cancel_fishing()
	check(not s.finish_fishing(true)["ok"] and s.fish_caught_today == 0, "cancel cannot grant fish")
	s.begin_fishing()
	check(not s.finish_fishing(false)["ok"] and s.fish_caught_today == 0, "failure does not consume daily catch slot")
	check(s.energy == 96, "failure still pays cast cost")
	s.begin_fishing()
	s.area_id = "forest"
	check(not s.finish_fishing(true)["ok"] and not s._fishing_pending and s.fish_caught_today == 0, "changing area cancels reward")
	s.route_restored = true
	for area in ["farm", "forest", "ruins"]:
		s.area_id = area
		var species: String = State.FISHING.GROUNDS[area]["fish"]
		check(s.begin_fishing()["ok"] and s.finish_fishing(true)["ok"] and s.fish[species] == 1, "ground yields its own species")
		before = s.to_data()
		check(not s.finish_fishing(true)["ok"] and s.to_data() == before, "same cast cannot pay twice")
	check(s.fish_caught_today == 3 and not s.can_begin_fishing(), "three-fish daily limit shared by all grounds")
	before = s.to_data()
	check(not s.begin_fishing()["ok"] and s.to_data() == before, "daily limit blocks cost")
	check(s.save_game(SAVE) == OK and loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "fish inventory and daily limit persist")
	var cash: int = s.money
	var stock: Dictionary = s.materials.duplicate()
	s.produce["turnip"] = 1
	s.eggs = 1
	s.goods["dried_berry"] = 1
	check(s.sell_all()["ok"] and s.money == cash + 298 and s.total_earned == 298, "fish, crops, goods and egg mixed shipping")
	check(s.fish.values().all(func(n): return n == 0) and s.materials == stock and s.fishing_rod, "shipping clears fish and preserves rod and resources")
	check(not s.sell_all()["ok"], "fish shipping cannot repeat")
	s.sleep()
	check(s.fish_caught_today == 0 and s.fishing_rod and s.energy == 100, "sleep resets daily quota, not gear")
	s.area_id = "farm"
	s.fish["silver_carp"] = State.FISHING.MAX_STOCK
	before = s.to_data()
	check(not s.begin_fishing()["ok"] and s.to_data() == before, "full fish stock blocks cast without cost")
	s.fish["silver_carp"] = 0
	s.begin_fishing()
	s.sleep()
	check(not s._fishing_pending and not s.finish_fishing(true)["ok"], "new day cancels stale cast")
	var legacy: Dictionary = State.new().to_data()
	for key in ["fishing_rod", "fish", "fish_caught_today"]:
		legacy.erase(key)
	check(s._valid_data(legacy), "0.9 save accepted without fishing fields")
	loaded._apply_data(legacy)
	check(not loaded.fishing_rod and loaded.fish_caught_today == 0 and loaded.fish.values().all(func(n): return n == 0), "legacy initializes empty fishing state")
	for key in ["fishing_rod", "fish_caught_today", "fish"]:
		for value in [null, "bad", []]:
			var bad: Dictionary = State.new().to_data()
			bad[key] = value
			check(not s._valid_data(bad), "wrong field type rejected")
	for value in [-1, 0.5, INF, 4]:
		var bad: Dictionary = State.new().to_data()
		bad["fish_caught_today"] = value
		bad["fishing_rod"] = true
		check(not s._valid_data(bad), "invalid catch count rejected")
	for value in [-1, 0.5, INF, 100000001]:
		var bad: Dictionary = State.new().to_data()
		bad["fish"]["silver_carp"] = value
		check(not s._valid_data(bad), "invalid inventory count rejected")
	var bad: Dictionary = State.new().to_data()
	bad["fish_caught_today"] = 1
	check(not s._valid_data(bad), "no catches without rod")
	var round := Round.new()
	check(round.reel() == "early", "early reaction fails")
	round.advance(100)
	check(round.result == "early", "resolved round cannot change outcome")
	for area in State.FISHING.GROUNDS:
		round = Round.new()
		round.bite_window = State.FISHING.GROUNDS[area]["window"]
		round.advance(State.FISHING.WAIT_SECONDS)
		check(round.is_biting() and round.reel() == "caught", "bite start is catchable")
		round = Round.new()
		round.bite_window = State.FISHING.GROUNDS[area]["window"]
		round.advance(State.FISHING.WAIT_SECONDS + round.bite_window)
		check(not round.is_biting() and round.result == "late" and round.reel() == "late", "window end is too late")
		round = Round.new()
		round.bite_window = State.FISHING.GROUNDS[area]["window"]
		round.advance(State.FISHING.WAIT_SECONDS + round.bite_window - 0.001)
		check(round.reel() == "caught", "last instant inside window is catchable")
	round = Round.new()
	for delta in [-1, NAN, INF]:
		round.advance(delta)
	check(round.elapsed == 0 and round.result == "", "invalid frame times ignored")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("FISHING TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
