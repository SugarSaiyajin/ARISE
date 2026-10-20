extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Farm = preload("res://scripts/farm_world.gd")
const Area = preload("res://scripts/area_world.gd")
const Forest = preload("res://scripts/forest_world.gd")
const Ruins = preload("res://scripts/ruins_world.gd")
const SAVE := "user://area_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	for area_id in ["farm", "house", "town", "forest", "ruins"]:
		var world = Farm.new() if area_id == "farm" else (Forest.new() if area_id == "forest" else (Ruins.new() if area_id == "ruins" else Area.new()))
		world.area_id = area_id
		var spawn: Vector2 = world.entry_spawn()
		check(not world.blocked(spawn), area_id + " safe entry")
		check(world.edge_destination(spawn) == "", area_id + " no immediate return")
		var nav := AStarGrid2D.new()
		nav.region = Rect2i(0, 0, 60, 28)
		nav.cell_size = Vector2(8, 8)
		nav.offset = Vector2(4, 4)
		nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		nav.update()
		for y in range(28):
			for x in range(60):
				nav.set_point_solid(Vector2i(x, y), world.blocked(Vector2(x * 8 + 4, y * 8 + 4)))
		for key in world.interactions():
			var target: Vector2 = world.interactions()[key]
			check(not world.blocked(target), area_id + " anchor " + key)
			var route := nav.get_point_path(Vector2i(spawn / 8), Vector2i(target / 8))
			check(not route.is_empty(), area_id + " reachable " + key)
			check(world.interaction_hitbox(key).has_area(), area_id + " clickable " + key)
		var state := State.new()
		state.area_id = area_id
		state.route_restored = area_id == "ruins"
		state.player_position = spawn
		state.money = 345
		state.work(0, "water")
		check(state.save_game(SAVE) == OK, area_id + " saves")
		var restored := State.new()
		check(restored.load_game(SAVE), area_id + " loads")
		check(restored.to_data() == state.to_data(), area_id + " full progress roundtrip")
		if area_id == "town":
			check(world.blocked(Vector2(265, 110)), "river cannot be walked across")
			check(not world.blocked(Vector2(265, 147)), "bridge permits crossing")
			check(world.edge_destination(Vector2(12, 147)) == "farm", "town road exit")
		if area_id == "forest":
			check(world.interaction_hitbox("town").has_point(Vector2(31, 108)), "forest exit label is fully clickable")
		if area_id == "house":
			check(world.blocked(Vector2(325, 95)), "bed collision")
			check(world.blocked(Vector2(180, 60)), "house wall collision")
			check(world.edge_destination(Vector2(239, 206)) == "farm", "house door exit")
			check(world.plot_at(spawn) == -1, "no indoor farm plots")
		if area_id == "farm":
			check(world.edge_destination(Vector2(468, 116)) == "town", "farm road exit")
			check(not world.blocked(world.entry_spawn("town")), "town return point walkable")
			check(not world.blocked(world.entry_spawn("house")), "house return point walkable")
		world.free()
	var original := State.new()
	original.harvested = 7
	original.friendship = 3
	original.work(0, "water")
	var legacy: Dictionary = original.to_data()
	legacy.erase("area")
	check(original._valid_data(legacy), "0.3 version-1 save accepted without area")
	var loaded := State.new()
	loaded._apply_data(legacy)
	check(loaded.area_id == "farm" and loaded.to_data() == original.to_data(), "legacy migration preserves all progress")
	for bad in [null, 17, "cave", [], {}]:
		var data: Dictionary = original.to_data()
		data["area"] = bad
		check(not original._valid_data(data), "reject malformed area")
	loaded.sleep()
	check(loaded.area_id == "house" and loaded.player_position == Vector2(296, 120), "sleep wakes indoors")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	print("AREA TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
