extends "res://scripts/farm_world.gd"

const RUINS_DEF = preload("res://data/maps/ruins.tres")
const RUINS_GROUND = preload("res://assets/pixel/ruins_ground.png")
const RELIC_SPRITE = preload("res://assets/pixel/star_relic.png")
const EXIT := Vector2(20, 147)
const RELIC := Vector2(258, 145)
const INSCRIPTION := Vector2(160, 165)
const RUINS_FISHING := Vector2(387, 125)
const BLOCKS := [Rect2(142, 63, 77, 19), Rect2(285, 63, 55, 19), Rect2(214, 70, 10, 37), Rect2(282, 70, 10, 37), Rect2(244, 97, 32, 27), Rect2(148, 131, 24, 22), Rect2(355, 66, 71, 45), Rect2(98, 77, 18, 12), Rect2(333, 111, 18, 12), Rect2(366, 195, 18, 12), Rect2(350, 156, 23, 18), Rect2(312, 173, 22, 14)]

func display_name() -> String:
	return "星潮舊驛"

func interactions() -> Dictionary:
	return RUINS_DEF.anchors.duplicate()

func interaction_hitbox(id: String) -> Rect2:
	match id:
		"fish": return Rect2(355, 54, 71, 80)
		"forest": return Rect2(6, 106, 57, 57)
		"relic": return Rect2(235, 75, 48, 79)
		"inscription": return Rect2(139, 117, 43, 56)
	return Rect2()

func entry_spawn(_from_area: String = "") -> Vector2:
	return Vector2(44, 147)

func edge_destination(p: Vector2) -> String:
	return "forest" if p.x <= 14 and p.y > 132 and p.y < 164 else ""

func plot_at(_p: Vector2) -> int:
	return -1

func blocked(p: Vector2) -> bool:
	if not RUINS_DEF.walkable.has_point(p):
		return true
	for rect in RUINS_DEF.obstacles:
		if rect.grow(3).has_point(p):
			return true
	return false

func _draw() -> void:
	if state == null:
		return
	draw_texture(RUINS_GROUND, Vector2.ZERO)
	if not state.relic_recovered:
		var p := Vector2(248, 86 + sin(elapsed * 2) * 2)
		draw_texture(RELIC_SPRITE, p.floor())
	person(actor)
	label_at(Vector2(390, 65), "星泉釣點")
	label_at(Vector2(32, 116), "← 霧杉林")
	label_at(Vector2(160, 128), "雙語碑文")
	label_at(Vector2(258, 86), "殘片已收藏" if state.relic_recovered else "星紋石台")
	for i in range(18):
		var p := Vector2(fposmod(i * 31.0 + elapsed * 3, 480), 58 + fposmod(i * 19.0 + sin(elapsed + i) * 3, 150))
		r(p.x, p.y, 1, 1, "dfdfb0aa")
	if state.is_raining():
		draw_rect(Rect2(0, 40, 480, 185), Color("425b7b20"))
		for i in range(40):
			var x := fposmod(i * 37.0 - elapsed * 18, 480)
			var y := fmod(i * 23.0 + elapsed * 70, 175) + 42
			draw_line(Vector2(x, y), Vector2(x - 2, y + 4), Color("d0e4de66"), 1)
	if state.minute >= 1080:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.14, 0.18, 0.3, clampf((state.minute - 1080) / 240.0, 0, 1) * 0.36))
