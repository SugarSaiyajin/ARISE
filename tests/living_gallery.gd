extends Control
const ART=preload("res://scripts/approved_art.gd")
const FONT=preload("res://assets/fonts/CloudbridgeTC.otf")
var page := 0
var elapsed := 0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()
func _draw() -> void:
	for row in range(3):
		var index := page*3+row
		draw_string(FONT,Vector2(2,row*104+14),["青禾","洛安","雷恩","艾德里克","莉莉雅","博林","雲霽","素月","青麟"][index],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dfd6ad"))
		for column in range(4):
			var origin := Vector2(column*106,row*104+18)
			draw_rect(Rect2(origin,Vector2(100,82)),Color("304d42"))
			ART.resident(self,origin+Vector2(50,64),index,58,-1,elapsed,[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][column])
			draw_string(FONT,origin+Vector2(34,79),["前","左","右","後"][column],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dfd6ad"))
