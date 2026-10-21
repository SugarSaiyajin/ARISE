extends Node2D
# Godot retains these draw commands. Moving actors no longer rebuild hundreds of ground tiles.
const ART = preload("res://scripts/approved_art.gd")
var area := "farm"
var layout := 0
func _ready() -> void:
	z_index=-10
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
	if area=="farm": ART.farm_ground(self,layout)
	elif area=="town": ART.ground(self,true)
	else: ART.calm_tile(self,0,Rect2(0,0,480,270))
