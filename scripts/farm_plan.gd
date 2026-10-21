extends Control
const ART = preload("res://scripts/approved_art.gd")
const RULES = preload("res://scripts/journey_rules.gd")
var state: RefCounted
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
	if state==null: return
	draw_set_transform(Vector2(25,0),0,Vector2.ONE*0.78)
	ART.farm_ground(self,state.journey["layout"])
	ART.building(self,0,Rect2(36,49,96,74))
	ART.building(self,1,Rect2(354,65,80,62))
	ART.building(self,5,Rect2(315,141,56,48))
	ART.building(self,2,Rect2(377,146,52,42))
	draw_rect(Rect2(150,122,119,68),Color("9a7951"))
	for i in range(6):
		var point: Vector2=RULES.SLOTS[i]
		draw_circle(point,11,Color("d9c68c"))
		if get_theme_default_font()!=null: draw_string(get_theme_default_font(),point+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("233d33"))
	draw_set_transform(Vector2.ZERO)
