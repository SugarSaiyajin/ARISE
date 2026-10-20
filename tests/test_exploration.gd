extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Forest = preload("res://scripts/forest_world.gd")
const Ruins = preload("res://scripts/ruins_world.gd")
const SAVE := "user://exploration_test_only.json"
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
	s.day = 3
	s.materials = {"wood": 6, "stone": 4, "herb": 2}
	s.money = 160
	s.area_id = "forest"
	var before: Dictionary = s.to_data()
	check(not s.can_restore_route() and not s.restore_route()["ok"] and s.to_data() == before, "two resident commissions required")
	s.requests_completed = 2
	s.request_completed_day = 2
	s.money = 159
	before = s.to_data()
	check(not s.restore_route()["ok"] and s.to_data() == before, "not enough cash consumes nothing")
	s.money = 160
	s.materials["stone"] = 3
	before = s.to_data()
	check(not s.restore_route()["ok"] and s.to_data() == before, "not enough material consumes nothing")
	s.materials["stone"] = 4
	s.area_id = "town"
	check(not s.restore_route()["ok"], "must visit forest to restore")
	s.area_id = "forest"
	check(s.can_restore_route() and s.restore_route()["ok"] and s.route_restored, "road restoration succeeds")
	check(s.money == 0 and s.materials == {"wood": 0, "stone": 0, "herb": 2}, "exact road cost")
	before = s.to_data()
	check(not s.restore_route()["ok"] and s.to_data() == before, "cannot repeat construction costs")
	check(not s.recover_relic()["ok"], "relic recovery only inside ruins")
	s.area_id = "ruins"
	s.player_position = Ruins.RELIC
	check(s.save_game(SAVE) == OK, "save unlocked ruins position")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "reload unlocked ruins state")
	var seed_before: Dictionary = s.seeds.duplicate()
	s.seeds["wheat"] = 100000000
	before = s.to_data()
	check(not s.recover_relic()["ok"] and s.to_data() == before, "full seed stock preserves unrecovered relic")
	s.seeds = seed_before.duplicate()
	check(s.recover_relic()["ok"] and s.relic_recovered and s.money == 120, "relic discovery reward")
	for crop in State.CROP_ORDER:
		check(s.seeds[crop] == seed_before[crop] + 3, "three seeds per crop")
	check(s.requests_completed == 2 and s.harvested == 0 and s.total_earned == 0, "discovery does not count as crops, commissions or shipping")
	before = s.to_data()
	check(not s.recover_relic()["ok"] and s.to_data() == before, "reward only once")
	s.sleep()
	check(s.route_restored and s.relic_recovered and s.area_id == "house", "night in ruins returns home and preserves story")
	check(s.save_game(SAVE) == OK and loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "completed discovery persists")
	loaded.area_id = "ruins"
	check(not loaded.recover_relic()["ok"], "reload cannot duplicate reward")
	var forest := Forest.new()
	var gate_state := State.new()
	forest.state = gate_state
	check(forest.blocked(Vector2(468, 147)) and forest.edge_destination(Vector2(468, 147)) == "", "unrestored road blocks walking across gate")
	gate_state.route_restored = true
	check(not forest.blocked(Vector2(468, 147)) and forest.edge_destination(Vector2(468, 147)) == "ruins", "restoration unlocks walking edge")
	var returned: Vector2 = forest.entry_spawn("ruins")
	check(not forest.blocked(returned) and returned.distance_to(Forest.ROUTE) > 21, "return spawn outside automatic interaction radius")
	check(forest.interaction_hitbox("route").has_point(Vector2(439, 115)), "gate text clickable")
	forest.free()
	var ruins := Ruins.new()
	check(ruins.blocked(Vector2(260, 112)), "altar blocks walking")
	check(ruins.blocked(Vector2(390, 85)), "pool blocks walking")
	check(ruins.entry_spawn().distance_to(Ruins.EXIT) > 21, "ruins entry avoids held-action return")
	check(ruins.edge_destination(Vector2(12, 147)) == "forest", "ruins west edge exits")
	ruins.free()
	var legacy: Dictionary = State.new().to_data()
	legacy.erase("route_restored")
	legacy.erase("relic_recovered")
	check(s._valid_data(legacy), "0.8 saves accepted without new story flags")
	loaded._apply_data(legacy)
	check(not loaded.route_restored and not loaded.relic_recovered, "legacy restores empty chapter flags")
	for key in ["route_restored", "relic_recovered"]:
		for value in [null, "true", 1, []]:
			var bad: Dictionary = State.new().to_data()
			bad[key] = value
			check(not s._valid_data(bad), "invalid chapter flag rejected")
	var bad: Dictionary = State.new().to_data()
	bad["area"] = "ruins"
	check(not s._valid_data(bad), "locked ruins save rejected")
	bad["area"] = "farm"
	bad["relic_recovered"] = true
	check(not s._valid_data(bad), "recovered relic requires open road")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("EXPLORATION TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
