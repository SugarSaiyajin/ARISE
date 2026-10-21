extends RefCounted
const ART = preload("res://scripts/approved_art.gd")
const RULES = preload("res://scripts/estate_rules.gd")
static func facility(canvas: CanvasItem, site: int, kind: int, ghost: bool = false, legal: bool = true) -> void:
	if kind==0: return
	var point: Vector2=RULES.SITES[site]
	var texture: Texture2D=preload("res://scripts/summer_art.gd").FACILITIES
	var data: Array=preload("res://scripts/summer_frames.gd").FACILITIES[0][kind-1]
	var dimensions := Vector2(26,30) if kind==1 else Vector2(30,24) if kind==2 else Vector2(30,34)
	var tint := Color(0.65,1,0.65,0.6) if legal else Color(1,0.4,0.4,0.6)
	canvas.draw_texture_rect_region(texture,Rect2(point-Vector2(dimensions.x/2,dimensions.y-2),dimensions),preload("res://scripts/summer_art.gd").facility_region(data),tint if ghost else Color.WHITE)
	if ghost: canvas.draw_rect(RULES.FOOTPRINTS[site],Color(0.4,0.9,0.5,0.25) if legal else Color(0.95,0.3,0.3,0.3))
