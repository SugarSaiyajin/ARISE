extends Control
const LAYOUT=preload("res://scripts/interior_layout.gd")
var layout: Array=[]
var selected := 0
var legal := true
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("263b35"))
	var factor := minf(size.x/280,size.y/145)
	draw_set_transform(Vector2((size.x-264*factor)/2,3),0,Vector2.ONE*factor)
	draw_rect(Rect2(0,0,264,135),Color("98754d"))
	draw_set_transform(Vector2.ZERO)
