extends "res://scripts/farm_world.gd"

const HOUSE_DEF = preload("res://data/maps/house.tres")
const TOWN_DEF = preload("res://data/maps/town.tres")
const RESIDENT_TEXTURES := {"npc": preload("res://assets/pixel/qinghe_eight.png"), "shop": preload("res://assets/pixel/merchant_eight.png"), "smith": preload("res://assets/pixel/smith_eight.png")}
const RESIDENT_FRAMES := {"npc": preload("res://scripts/qinghe_frames.gd"), "shop": preload("res://scripts/merchant_frames.gd"), "smith": preload("res://scripts/smith_frames.gd")}
const Residents = preload("res://scripts/resident_data.gd")
const INTERIOR = preload("res://assets/pixel/house_interior.png")
const TOWN_GROUND = preload("res://assets/pixel/town_ground.png")
const SMITHY = preload("res://assets/pixel/smithy.png")
const CLOCK = preload("res://assets/pixel/clocktower.png")
const MERCHANT = preload("res://assets/pixel/merchant.png")
const SMITH = preload("res://assets/pixel/smith.png")
const BED := Vector2(312, 120)
const JOURNAL := Vector2(172, 120)
const HOUSE_EXIT := Vector2(239, 197)
const FARM_EXIT := Vector2(20, 147)
const QINGHE_POS := Vector2(108, 144)
const MERCHANT_POS := Vector2(367, 144)
const SMITH_POS := Vector2(331, 181)
const NOTICE := Vector2(215, 116)
const FOREST_GATE := Vector2(454, 147)
const HEARTH := Vector2(146, 158)
const HOUSE_BLOCKS := [Rect2(305, 81, 45, 30), Rect2(146, 84, 49, 25), Rect2(112, 136, 23, 33), Rect2(218, 137, 30, 18)]
const TOWN_BLOCKS := [Rect2(65, 80, 78, 44), Rect2(340, 96, 60, 37), Rect2(348, 166, 63, 39), Rect2(148, 174, 29, 34), Rect2(202, 80, 28, 25)]

func display_name() -> String:
	return HOUSE_DEF.title if area_id == "house" else TOWN_DEF.title

func resident_position(id: String, at_minute: float = -1) -> Vector2:
	return Residents.position(id, at_minute if at_minute >= 0 else (state.minute if state != null else 420.0), state.is_raining() if state != null else false)

func resident_anchor(id: String) -> Vector2:
	var p := resident_position(id)
	var preferred := Vector2(22,0) if id == "npc" else Vector2(-22,0)
	for offset in [preferred, Vector2(22,0), Vector2(-22,0), Vector2(0,22), Vector2(0,-22)]:
		if not blocked(p + offset):
			return p + offset
	return p

func interactions() -> Dictionary:
	if area_id == "house":
		return HOUSE_DEF.anchors.duplicate()
	var result: Dictionary = TOWN_DEF.anchors.duplicate()
	for id in Residents.ORDER:
		result[id] = resident_anchor(id)
	return result

func interaction_hitbox(id: String) -> Rect2:
	if area_id == "house":
		return HOUSE_DEF.hitboxes.get(id, Rect2())
	if id in Residents.ORDER:
		var p := resident_position(id)
		if p.distance_to(Residents.HOMES[id]) < 1:
			return TOWN_DEF.hitboxes[id]
		return Rect2(p - Vector2(16,32), Vector2(32,44))
	return TOWN_DEF.hitboxes.get(id, Rect2(interactions()[id] - Vector2(15,30), Vector2(30,40)))

func entry_spawn(from_area: String = "") -> Vector2:
	if from_area == "forest":
		return Vector2(440, 147)
	return Vector2(239, 185) if area_id == "house" else Vector2(36, 147)

func edge_destination(p: Vector2) -> String:
	if area_id == "house":
		return "farm" if p.y >= 204 and p.x > 225 and p.x < 254 else ""
	if p.x >= 465 and p.y > 132 and p.y < 164:
		return "forest"
	return "farm" if p.x <= 14 and p.y > 132 and p.y < 164 else ""

func plot_at(_p: Vector2) -> int:
	return -1

func blocked(p: Vector2) -> bool:
	if area_id == "house":
		if not HOUSE_DEF.walkable.has_point(p):
			return true
		for rect in HOUSE_DEF.obstacles:
			if rect.grow(3).has_point(p):
				return true
		return false
	if not TOWN_DEF.walkable.has_point(p):
		return true
	if p.x > 247 and p.x < 284 and (p.y < 138 or p.y > 156):
		return true
	for rect in TOWN_DEF.obstacles:
		if rect.grow(3).has_point(p):
			return true
	return false

func draw_resident(id: String, p: Vector2) -> void:
	ApprovedArt.resident(self,p,{"npc":0,"shop":1,"smith":2}[id])

func _draw() -> void:
	if state == null:
		return
	if area_id == "house":
		draw_texture(INTERIOR, Vector2.ZERO)
		person(actor)
		label_at(Vector2(329, 75), "床鋪")
		label_at(Vector2(170, 78), "莊園手札")
		label_at(Vector2(136, 134), "爐灶")
		label_at(Vector2(239, 210), "出門 ↓")
		var glow := 0.12 + sin(elapsed * 5) * 0.025
		draw_rect(Rect2(114, 147, 22, 22), Color(0.9, 0.58, 0.26, glow))
		return
	ApprovedArt.ground(self,true)
	for shadow in [Rect2(66,119,77,7),Rect2(343,131,59,6),Rect2(347,202,65,7),Rect2(149,204,29,7)]:
		draw_rect(shadow,Color("314a3e38"))
	if state.SPRING.festival_open(state):
		for x in range(181,242,12):
			draw_line(Vector2(x,83),Vector2(x+12,83),Color("8b7651"),1)
			draw_colored_polygon(PackedVector2Array([Vector2(x,84),Vector2(x+8,84),Vector2(x+4,91)]),Color("e2bc78" if x%24<12 else "b57660"))
		for x in [183,210,237]:
			r(x,168,18,8,"805c42")
			r(x,166,18,3,"d5c297")
			r(x+4,164,4,2,"8fad75")
	var qinghe: Vector2 = resident_position("npc")
	var merchant: Vector2 = resident_position("shop")
	var smith: Vector2 = resident_position("smith")
	var layers: Array = [
		{"y": 127.0, "kind": "tea"}, {"y": 137.0, "kind": "market"},
		{"y": 209.0, "kind": "smithy"}, {"y": 210.0, "kind": "clock"},
		{"y": qinghe.y, "kind": "npc"}, {"y": merchant.y, "kind": "merchant"},
		{"y": smith.y, "kind": "smith"}, {"y": actor.y, "kind": "hero"},
	]
	for p in [Vector2(25, 92), Vector2(445, 84), Vector2(465, 180), Vector2(60, 207)]:
		layers.append({"y": p.y, "kind": "tree", "p": p})
	layers.sort_custom(func(a: Dictionary, b: Dictionary): return a["y"] < b["y"])
	for item in layers:
		match item["kind"]:
			"tea": ApprovedArt.building(self,2,Rect2(52,44,116,83))
			"market": ApprovedArt.building(self,1,Rect2(330,76,80,61))
			"smithy": ApprovedArt.building(self,3,Rect2(342,144,80,65))
			"clock": ApprovedArt.building(self,4,Rect2(139,142,43,68))
			"npc": draw_resident("npc", qinghe)
			"merchant": draw_resident("shop", merchant)
			"smith": draw_resident("smith", smith)
			"hero": person(actor)
			"tree": tree(item["p"])
	label_at(Vector2(108, 72), "青禾茶館")
	label_at(Vector2(371, 93), "行旅種子鋪")
	label_at(Vector2(216, 80), "公告牌")
	label_at(Vector2(382, 164), "雷恩鍛冶鋪")
	label_at(qinghe - Vector2(0, 34), "青禾")
	label_at(merchant - Vector2(0, 34), "洛安")
	label_at(smith - Vector2(0, 34), "雷恩")
	label_at(Vector2(35, 129), "← 莊園")
	label_at(Vector2(444, 132), "林地 →")
	if (state.harvested >= 5 and not state.reward_claimed) or state.tea_event_available():
		label_at(qinghe - Vector2(0, 48), "！")
	if state.active_request != "":
		var recipient: String = State.REQUESTS.REQUESTS[state.active_request]["recipient"]
		var point: Vector2 = resident_position(recipient)
		label_at(point - Vector2(0, 48), "委託")
	for i in range(10):
		r(258 + sin(elapsed + i) * 3, 55 + i * 16, 5, 1, "bbd7c280")
	if state.is_raining():
		draw_rect(Rect2(0, 40, 480, 185), Color("425b7b20"))
		for i in range(50):
			var x := fposmod(i * 37.0 - elapsed * 18, 480)
			var y := fmod(i * 23.0 + elapsed * 70, 175) + 42
			draw_line(Vector2(x, y), Vector2(x - 2, y + 4), Color("d0e4de66"), 1)
	if state.minute >= 1080:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.14, 0.18, 0.3, clampf((state.minute - 1080) / 240.0, 0, 1) * 0.36))
