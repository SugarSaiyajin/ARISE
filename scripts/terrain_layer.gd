extends Node2D
# Godot retains these draw commands. Moving actors no longer rebuild hundreds of ground tiles.
const ART = preload("res://scripts/approved_art.gd")
var autumn := false
var area := "farm"
var layout := 0
func _ready() -> void:
	z_index=-10
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
	if area=="farm": ART.farm_ground(self,layout)
	elif area=="town": ART.ground(self,true)
	else: ART.calm_tile(self,0,Rect2(0,0,480,270))
	if autumn:
		draw_rect(Rect2(0,0,480,270),Color("c5a66412"))
		for point in [Vector2(25,108),Vector2(449,104),Vector2(55,216),Vector2(438,216)]:
			preload("res://scripts/autumn_art.gd").object(self,7,point,10)
