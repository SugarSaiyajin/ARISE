extends "res://scripts/farm_world.gd"

const FOREST_DEF = preload("res://data/maps/forest.tres")
const GROUND_FOREST = preload("res://assets/pixel/forest_ground.png")
const FORAGE_SPRITES = preload("res://assets/pixel/forage.png")
const EXIT := Vector2(20, 147)
const ROUTE := Vector2(454, 147)
const FOREST_FISHING := Vector2(366, 116)
const TREES := [Vector2(22, 90), Vector2(56, 92), Vector2(149, 78), Vector2(178, 75), Vector2(282, 75), Vector2(324, 77), Vector2(448, 87), Vector2(465, 131), Vector2(40, 205), Vector2(83, 208), Vector2(239, 211), Vector2(427, 206), Vector2(466, 211)]

func display_name() -> String:
	return "霧杉林"

func interactions() -> Dictionary:
	var objects: Dictionary = FOREST_DEF.anchors.duplicate()
	for node_id in State.FORAGE.NODES:
		objects["gather:" + node_id] = State.FORAGE.NODES[node_id]["position"] + Vector2(0, 16)
	return objects

func interaction_hitbox(id: String) -> Rect2:
	if id == "fish":
		return Rect2(331, 53, 56, 74)
	if id == "route":
		return Rect2(418, 109, 53, 46)
	if id == "town":
		return Rect2(6, 100, 57, 63)
	var point: Vector2 = State.FORAGE.NODES[id.trim_prefix("gather:")]["position"]
	return Rect2(point - Vector2(14, 22), Vector2(28, 41))

func entry_spawn(from_area: String = "") -> Vector2:
	if from_area == "ruins":
		return Vector2(430, 147)
	return Vector2(36, 147)

func edge_destination(p: Vector2) -> String:
	if state != null and state.route_restored and p.x >= 465 and p.y > 132 and p.y < 156:
		return "ruins"
	return "town" if p.x <= 14 and p.y > 132 and p.y < 164 else ""

func plot_at(_p: Vector2) -> int:
	return -1

func blocked(p: Vector2) -> bool:
	if (state == null or not state.route_restored) and p.x > 461 and p.y > 132 and p.y < 156:
		return true
	if not FOREST_DEF.walkable.has_point(p):
		return true
	for rect in FOREST_DEF.obstacles:
		if rect.has_point(p):
			return true
	for point in TREES:
		if Rect2(point - Vector2(4, 4), Vector2(8, 8)).has_point(p):
			return true
	return false

func _draw() -> void:
	if state == null:
		return
	draw_texture(GROUND_FOREST, Vector2.ZERO)
	r(416, 140, 64, 15, "a99d78")
	if not state.route_restored:
		for x in [441, 453, 463]:
			r(x, 138, 8, 14, "778572")
			r(x + 1, 138, 6, 3, "b1b695")
	var layers: Array = [{"y": actor.y, "kind": "hero"}]
	for point in TREES:
		layers.append({"y": point.y, "kind": "tree", "position": point})
	for node_id in State.FORAGE.NODES:
		var node: Dictionary = State.FORAGE.NODES[node_id]
		layers.append({"y": node["position"].y, "kind": "node", "id": node_id})
	layers.sort_custom(func(a: Dictionary, b: Dictionary): return a["y"] < b["y"])
	for item in layers:
		match item["kind"]:
			"hero": person(actor)
			"tree": tree(item["position"])
			"node":
				var node: Dictionary = State.FORAGE.NODES[item["id"]]
				var point: Vector2 = node["position"]
				var spent: bool = state.gathered.has(item["id"])
				var column: int = State.FORAGE.ORDER.find(node["kind"])
				draw_texture_rect_region(FORAGE_SPRITES, Rect2(point - Vector2(16, 28), Vector2(32, 32)), Rect2(column * 32, 32 if spent else 0, 32, 32))
				if not spent:
					label_at(point - Vector2(0, 24), {"wood": "枯枝", "stone": "石料", "herb": "霧香草"}[node["kind"]])
	label_at(Vector2(31, 113), "← 雲橋鎮")
	label_at(Vector2(365, 55), "霧泉釣點")
	label_at(Vector2(444, 119), "舊驛 →" if state.route_restored else "待修驛路")
	for particle in particles:
		draw_rect(Rect2(particle["p"].floor(), Vector2(2, 2)), particle["color"])
	for i in range(16):
		var p := Vector2(fposmod(i * 39.0 + elapsed * 2, 480), 68 + fposmod(i * 23.0 + sin(elapsed + i) * 3, 144))
		r(p.x, p.y, 1, 1, "e3db9b99")
	if state.is_raining():
		draw_rect(Rect2(0, 40, 480, 185), Color("425b7b20"))
		for i in range(45):
			var x := fposmod(i * 37.0 - elapsed * 18, 480)
			var y := fmod(i * 23.0 + elapsed * 70, 175) + 42
			draw_line(Vector2(x, y), Vector2(x - 2, y + 4), Color("d0e4de66"), 1)
	if state.minute >= 1080:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.14, 0.18, 0.3, clampf((state.minute - 1080) / 240.0, 0, 1) * 0.36))
