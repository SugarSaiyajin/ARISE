extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const SAVE := "user://forage_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	var s := State.new()
	check(not s.gather("wood_1")["ok"], "cannot gather outside forest")
	s.area_id = "forest"
	check(not s.gather("unknown")["ok"], "unknown node rejected")
	s.energy = 0
	check(not s.gather("wood_1")["ok"] and s.gathered.is_empty() and s.materials["wood"] == 0, "exhaustion changes nothing")
	s.energy = 100
	for node_id in State.FORAGE.NODES:
		var before: int = s.energy
		var kind: String = State.FORAGE.NODES[node_id]["kind"]
		check(s.gather(node_id)["ok"], "first gather succeeds: " + node_id)
		check(s.energy == before - State.FORAGE.MATERIALS[kind]["energy"], "gather energy cost")
		var snapshot: Dictionary = s.to_data()
		check(not s.gather(node_id)["ok"] and snapshot == s.to_data(), "no duplicate rewards or energy use")
	check(s.materials == {"wood": 6, "stone": 4, "herb": 3} and s.energy == 77, "daily material and stamina totals")
	s.player_position = Vector2(36, 147)
	check(s.save_game(SAVE) == OK, "save collected forest")
	var restored := State.new()
	check(restored.load_game(SAVE) and restored.to_data() == s.to_data(), "collected nodes persist across restart")
	check(not restored.gather("wood_1")["ok"], "restart cannot renew nodes")
	s.area_id = "town"
	s.area_id = "forest"
	check(not s.gather("stone_1")["ok"], "map reentry cannot renew nodes")
	s.sleep()
	check(s.gathered.is_empty() and s.materials == {"wood": 6, "stone": 4, "herb": 3}, "sleep renews nodes and retains stock")
	s.area_id = "forest"
	check(s.gather("wood_1")["ok"] and s.materials["wood"] == 8, "new day can gather again")
	check(not s.repair_fence()["ok"] and not s.fence_repaired, "repair only at farm")
	s.area_id = "farm"
	s.materials["stone"] = 3
	var before_repair: Dictionary = s.to_data()
	check(not s.repair_fence()["ok"] and before_repair == s.to_data(), "insufficient repair materials consumed atomically")
	s.materials["stone"] = 4
	check(s.repair_fence()["ok"] and s.fence_repaired, "repair completes")
	check(s.materials == {"wood": 2, "stone": 0, "herb": 3}, "exact repair cost")
	var after_repair: Dictionary = s.to_data()
	check(not s.repair_fence()["ok"] and after_repair == s.to_data(), "repair cannot repeat")
	check(not s.brew_tea()["ok"], "tea requires house")
	s.area_id = "house"
	var herbs: int = s.materials["herb"]
	s.energy = 100
	check(not s.brew_tea()["ok"] and s.materials["herb"] == herbs, "full energy does not consume herb")
	s.energy = 95
	check(s.brew_tea()["ok"] and s.energy == 100 and s.materials["herb"] == herbs - 1, "tea caps at maximum")
	s.energy = 23
	check(s.brew_tea()["ok"] and s.energy == 43, "tea restores twenty")
	s.materials["herb"] = 0
	check(not s.brew_tea()["ok"] and s.energy == 43, "missing herb does not restore energy")
	s.produce["turnip"] = 1
	var stock: Dictionary = s.materials.duplicate()
	s.sell_all()
	check(s.materials == stock, "shipping never sells materials")
	check(s.save_game(SAVE) == OK and restored.load_game(SAVE) and restored.to_data() == s.to_data(), "repair and stock survive restart")
	var legacy: Dictionary = State.new().to_data()
	for key in ["materials", "gathered", "fence_repaired"]:
		legacy.erase(key)
	check(s._valid_data(legacy), "0.4 save accepted without forage fields")
	restored._apply_data(legacy)
	check(restored.materials == {"wood": 0, "stone": 0, "herb": 0} and restored.gathered.is_empty() and not restored.fence_repaired, "legacy initializes fresh forage fields")
	for bad in [null, [], {"wood": 0}, {"wood": -1, "stone": 0, "herb": 0}, {"wood": 0.5, "stone": 0, "herb": 0}, {"wood": INF, "stone": 0, "herb": 0}]:
		var data: Dictionary = s.to_data()
		data["materials"] = bad
		check(not s._valid_data(data), "malformed materials rejected")
	for bad in [null, {}, ["unknown"], ["wood_1", "wood_1"], [1]]:
		var data: Dictionary = s.to_data()
		data["gathered"] = bad
		check(not s._valid_data(data), "malformed collected nodes rejected")
	for bad in [null, 1, "true"]:
		var data: Dictionary = s.to_data()
		data["fence_repaired"] = bad
		check(not s._valid_data(data), "malformed repair state rejected")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("FORAGE TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
