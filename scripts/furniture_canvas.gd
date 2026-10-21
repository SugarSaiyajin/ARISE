extends Node2D
var layout: Array=[]
var selected := 0
var legal := true
func _draw() -> void:
	var rules=preload("res://scripts/interior_layout.gd")
	for i in [7,0,1,2,3,4,5,6]: rules.draw(self,layout,i,Color.WHITE if legal else Color(1,0.65,0.65))
	draw_rect(rules.shape(layout,selected).grow(2),Color("b7d48f") if legal else Color("e88170"),false,1)
	draw_rect(Rect2(224,201,32,8),Color("a9c4a0"))
