extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const SAVE := "user://processing_test_only.json"
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
	var snapshot: Dictionary = s.to_data()
	check(not s.build_dryer()["ok"] and s.to_data() == snapshot, "missing build materials changes nothing")
	s.materials = {"wood": 4, "stone": 2, "herb": 1}
	s.money = 59
	snapshot = s.to_data()
	check(not s.build_dryer()["ok"] and s.to_data() == snapshot, "insufficient silver is atomic")
	s.money = 120
	s.area_id = "town"
	check(not s.build_dryer()["ok"] and not s.rack_built, "construction only on farm")
	s.area_id = "farm"
	check(not s.start_processing("dried_turnip")["ok"], "must build first")
	check(s.build_dryer()["ok"] and s.rack_built, "build succeeds")
	check(s.materials == {"wood": 0, "stone": 0, "herb": 1} and s.money == 60, "exact build costs")
	snapshot = s.to_data()
	check(not s.build_dryer()["ok"] and s.to_data() == snapshot, "no repeat construction")
	check(not s.collect_processing()["ok"], "cannot collect idle rack")
	check(not s.start_processing("unknown")["ok"], "unknown recipe rejected")
	for amount in [-1, 0, 2, 4, 999]:
		check(not s.start_processing("dried_turnip", amount)["ok"], "invalid batch rejected")
	check(not s.start_processing("dried_turnip")["ok"] and s.seeds["turnip"] == 8, "seed stock cannot be processed")
	for recipe in State.PROCESSING.ORDER:
		for amount in [1, 3]:
			var crop: String = State.PROCESSING.RECIPES[recipe]["crop"]
			s.produce[crop] = amount
			var energy_before: int = s.energy
			check(s.start_processing(recipe, amount)["ok"], "recipe and batch accepted")
			check(s.produce[crop] == 0 and s.energy == energy_before, "input removed once without stamina cost")
			check(not s.processing_ready() and s.processing_job["ready_day"] == s.day + 1, "requires next game day")
			snapshot = s.to_data()
			check(not s.start_processing(recipe, amount)["ok"] and s.to_data() == snapshot, "busy rack cannot take more inputs")
			check(not s.collect_processing()["ok"] and s.to_data() == snapshot, "early collection changes nothing")
			check(s.save_game(SAVE) == OK, "save pending batch")
			var loaded := State.new()
			check(loaded.load_game(SAVE) and loaded.to_data() == s.to_data() and not loaded.processing_ready(), "reload retains pending state without fast-forward")
			s.sleep()
			check(s.processing_ready(), "sleep completes batch")
			s.sleep()
			check(s.processing_ready(), "ready batch does not expire")
			check(not s.collect_processing()["ok"], "collection requires returning to farm")
			s.area_id = "farm"
			var before: int = s.goods[recipe]
			check(s.collect_processing()["ok"] and s.goods[recipe] == before + amount, "receive correct recipe and count")
			snapshot = s.to_data()
			check(s.processing_job.is_empty() and not s.collect_processing()["ok"] and s.to_data() == snapshot, "cannot duplicate collected goods")
	var earnings := 0
	for recipe in State.PROCESSING.ORDER:
		earnings += s.goods[recipe] * State.PROCESSING.RECIPES[recipe]["price"]
	s.produce["turnip"] = 2
	earnings += 36
	var cash: int = s.money
	var stock: Dictionary = s.materials.duplicate()
	check(s.sell_all()["ok"] and s.money == cash + earnings and s.total_earned == earnings, "mixed raw and processed shipment pays exact value")
	check(s.goods.values().all(func(n): return n == 0) and s.materials == stock, "sale clears goods but preserves forest resources")
	check(not s.sell_all()["ok"] and s.money == cash + earnings, "shipment cannot repeat")
	s.produce["berry"] = 1
	s.goods["dried_berry"] = State.PROCESSING.MAX_STOCK
	snapshot = s.to_data()
	check(not s.start_processing("dried_berry")["ok"] and s.to_data() == snapshot, "full output storage preserves input")
	s.goods["dried_berry"] = 0
	s.start_processing("dried_berry")
	s.sleep()
	s.area_id = "farm"
	s.goods["dried_berry"] = State.PROCESSING.MAX_STOCK
	snapshot = s.to_data()
	check(not s.collect_processing()["ok"] and s.to_data() == snapshot, "storage full retains completed batch")
	s.goods["dried_berry"] = 0
	check(s.save_game(SAVE) == OK, "save ready batch")
	var restored := State.new()
	check(restored.load_game(SAVE) and restored.processing_ready() and restored.to_data() == s.to_data(), "ready batch survives restart")
	check(restored.collect_processing()["ok"] and restored.goods["dried_berry"] == 1, "loaded ready batch collected once")
	var legacy: Dictionary = State.new().to_data()
	for key in ["rack_built", "goods", "processing_job"]:
		legacy.erase(key)
	check(s._valid_data(legacy), "0.5 data accepted without processing fields")
	restored._apply_data(legacy)
	check(not restored.rack_built and restored.goods.values().all(func(n): return n == 0) and restored.processing_job.is_empty(), "legacy defaults reset previous in-memory processing")
	for key in ["day", "money", "energy", "harvested", "total_earned", "friendship"]:
		var bad: Dictionary = State.new().to_data()
		bad[key] += 0.5
		check(not s._valid_data(bad), "fractional integer field rejected: " + key)
	for value in [null, 1, "true"]:
		var bad: Dictionary = s.to_data()
		bad["rack_built"] = value
		check(not s._valid_data(bad), "malformed build flag rejected")
	for value in [null, [], {}, {"dried_turnip": -1, "dried_wheat": 0, "dried_berry": 0}, {"dried_turnip": 0.5, "dried_wheat": 0, "dried_berry": 0}]:
		var bad: Dictionary = s.to_data()
		bad["goods"] = value
		check(not s._valid_data(bad), "malformed goods rejected")
	for value in [null, [], {"recipe": "unknown", "amount": 1, "ready_day": 2}, {"recipe": "dried_turnip", "amount": 2, "ready_day": 2}, {"recipe": "dried_turnip", "amount": 1, "ready_day": 2.5}, {"recipe": "dried_turnip", "amount": 1, "ready_day": 999}, {"recipe": "dried_turnip"}]:
		var bad: Dictionary = s.to_data()
		bad["processing_job"] = value
		check(not s._valid_data(bad), "malformed job rejected")
	var impossible: Dictionary = s.to_data()
	impossible["rack_built"] = false
	check(not s._valid_data(impossible), "unbuilt rack cannot contain a job")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("PROCESSING TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
