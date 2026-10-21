extends Control
const Art=preload("res://scripts/summer_art.gd")
const FONT=preload("res://assets/fonts/CloudbridgeTC.otf")
var elapsed := 0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()
func _draw() -> void:
	for row in range(2):
		for col in range(4):
			var origin := Vector2(col*106,row*145)
			draw_rect(Rect2(origin,Vector2(100,135)),Color("304d42"))
			Art.resident(self,origin+Vector2(50,105),3 if row==0 else 7,82,-1,elapsed,[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][col])
			draw_string(FONT,origin+Vector2(30,125),["正面","左側","右側","背面"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dfd6ad"))
