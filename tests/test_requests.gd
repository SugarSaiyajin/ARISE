extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const SAVE := "user://requests_test_only.json"
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
	check(not s.accept_request()["ok"], "accept only in town")
	s.area_id = "town"
	check(s.daily_request_id() == "tea_vegetables" and s.accept_request()["ok"], "day-one request accepted")
	var before: Dictionary = s.to_data()
	check(not s.accept_request()["ok"] and s.to_data() == before, "only one active request")
	check(not s.deliver_request("smith")["ok"] and s.to_data() == before, "wrong recipient changes nothing")
	s.produce["turnip"] = 1
	before = s.to_data()
	check(not s.can_deliver_request("npc") and not s.deliver_request("npc")["ok"] and s.to_data() == before, "insufficient stock changes nothing")
	s.produce["turnip"] = 3
	sleep_pending(s)
	check(s.active_request == "tea_vegetables" and s.day == 2, "accepted request survives new daily posting")
	s.area_id = "town"
	check(s.save_game(SAVE) == OK, "save pending accepted request")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "pending delivery survives reload")
	var cash: int = loaded.money
	check(loaded.deliver_request("npc")["ok"], "deliver carried request on later day")
	check(loaded.produce["turnip"] == 1 and loaded.money == cash + 50 and loaded.friendship == 1, "exact raw items, reward and friendship")
	check(loaded.requests_completed == 1 and loaded.request_completed_day == 2 and loaded.active_request == "", "completed request clears and records day")
	before = loaded.to_data()
	check(not loaded.deliver_request("npc")["ok"] and loaded.to_data() == before, "delivery cannot duplicate rewards")
	check(not loaded.accept_request()["ok"] and not loaded.cancel_request()["ok"], "daily completion limit survives cancellation")
	check(loaded.save_game(SAVE) == OK and s.load_game(SAVE) and not s.accept_request()["ok"], "daily limit survives reload")
	s.sleep()
	s.area_id = "town"
	check(s.daily_request_id() == "caravan_treats" and s.accept_request()["ok"], "next day unlocks another commission")
	before = s.to_data()
	check(not s.deliver_request("shop")["ok"] and s.to_data() == before, "unclaimed processed product not in inventory")
	s.goods["dried_berry"] = 2
	cash = s.money
	check(s.deliver_request("shop")["ok"] and s.goods["dried_berry"] == 1 and s.money == cash + 100, "merchant accepts processed goods")
	check(s.friendship == 1 and s.total_earned == 0 and s.harvested == 0, "commissions do not count as shipping or crop harvesting")
	s.sleep()
	s.sleep()
	s.area_id = "town"
	check(s.daily_request_id() == "bridge_repairs" and s.accept_request()["ok"], "three-day posting rotation")
	s.materials = {"wood": 4, "stone": 1, "herb": 3}
	before = s.to_data()
	check(not s.deliver_request("smith")["ok"] and s.to_data() == before, "multi-material requirement is atomic")
	s.materials["stone"] = 3
	cash = s.money
	check(s.deliver_request("smith")["ok"] and s.materials == {"wood": 0, "stone": 1, "herb": 3} and s.money == cash + 50, "smith exact material consumption")
	s.sleep()
	s.area_id = "town"
	s.accept_request()
	var stock: Dictionary = s.goods.duplicate()
	check(s.cancel_request()["ok"] and s.active_request == "" and s.goods == stock, "cancel returns to empty without consumption")
	check(s.accept_request()["ok"], "cancel permits accepting today's posting again")
	check(not s.tea_event_available() and not s.finish_tea_event()["ok"], "tea event requires friendship")
	s.friendship = 3
	s.area_id = "house"
	check(s.tea_event_available() and not s.finish_tea_event()["ok"], "first tea event requires town")
	s.area_id = "town"
	s.materials["herb"] = 100000000
	before = s.to_data()
	check(not s.finish_tea_event()["ok"] and s.to_data() == before, "full herb storage preserves unseen event")
	s.materials["herb"] = 3
	check(s.finish_tea_event()["ok"] and s.tea_event_seen and s.friendship == 4 and s.materials["herb"] == 5, "tea event gift and friendship")
	before = s.to_data()
	check(not s.tea_event_available() and not s.finish_tea_event()["ok"] and s.to_data() == before, "tea event reward only once")
	check(s.save_game(SAVE) == OK and loaded.load_game(SAVE) and loaded.to_data() == s.to_data(), "event and daily state survive save")
	check(not loaded.finish_tea_event()["ok"], "reloading cannot reclaim event")
	var legacy: Dictionary = State.new().to_data()
	for key in ["active_request", "request_completed_day", "requests_completed", "tea_event_seen"]:
		legacy.erase(key)
	check(s._valid_data(legacy), "0.6 data accepts absent new fields")
	loaded._apply_data(legacy)
	check(loaded.active_request == "" and loaded.request_completed_day == 0 and loaded.requests_completed == 0 and not loaded.tea_event_seen, "legacy resets previous in-memory request and event fields")
	for value in [null, 1, [], "unknown"]:
		var bad: Dictionary = State.new().to_data()
		bad["active_request"] = value
		check(not s._valid_data(bad), "malformed request rejected")
	for key in ["request_completed_day", "requests_completed"]:
		for value in [null, "1", -1, 0.5, INF, 99]:
			var bad: Dictionary = State.new().to_data()
			bad[key] = value
			check(not s._valid_data(bad), "invalid request counter rejected")
	for value in [null, "true", 1]:
		var bad: Dictionary = State.new().to_data()
		bad["tea_event_seen"] = value
		check(not s._valid_data(bad), "invalid event flag rejected")
	var impossible: Dictionary = State.new().to_data()
	impossible["request_completed_day"] = 1
	check(not s._valid_data(impossible), "completion day requires completed count")
	impossible["requests_completed"] = 1
	impossible["active_request"] = "tea_vegetables"
	check(not s._valid_data(impossible), "completed-today cannot also have active commission")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("REQUEST TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func sleep_pending(s: RefCounted) -> void:
	s.sleep()
