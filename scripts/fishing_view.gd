extends Control

const POND = preload("res://assets/pixel/fishing_pond.png")
var elapsed := 0.0
var biting := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_texture(POND, Vector2.ZERO)
	var point := Vector2(225 + sin(elapsed * 2) * 2, 45 + (sin(elapsed * 18) * 4 if biting else sin(elapsed * 2) * 1.5)).floor()
	draw_line(Vector2(24, 49), Vector2(100, 10), Color("bba573"), 3)
	draw_line(Vector2(100, 10), point, Color("ddd9ac"), 1)
	draw_rect(Rect2(point - Vector2(3, 5), Vector2(6, 5)), Color("d18967"))
	draw_rect(Rect2(point, Vector2(3, 4)), Color("ecddb1"))
	if biting:
		draw_line(point + Vector2(-12, 4), point + Vector2(-6, 4), Color("e3dfb3"), 1)
		draw_line(point + Vector2(6, 4), point + Vector2(13, 4), Color("e3dfb3"), 1)
