extends Control

const World = preload("res://scripts/farm_world.gd")
var style := "male"
var row := 0
var motion := 0
var elapsed := 0.0
var pause_reasons := {}
var background: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background = _background()

func frame_index() -> int:
	if motion == 1:
		return int(elapsed * 9) % 4
	if motion == 2:
		var phase := fmod(elapsed, 0.9)
		return 4 + mini(3, int(phase / World.ACTION_DURATION * 4)) if phase < World.ACTION_DURATION else 0
	return 0

func _process(delta: float) -> void:
	if not pause_reasons.is_empty() or not is_finite(delta) or delta <= 0:
		return
	elapsed = fmod(elapsed + delta, 90.0)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		pause_reasons["application"] = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pause_reasons["focus"] = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		pause_reasons.erase("application")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		pause_reasons.erase("focus")

func _draw() -> void:
	draw_style_box(background, Rect2(Vector2.ZERO, size))
	var feet := Vector2(size.x / 2.0, size.y - 14)
	draw_ellipse_shadow(feet)
	var frame := frame_index()
	preload("res://scripts/approved_art.gd").hero(self,feet,style,row,frame,120,elapsed if motion==0 else -1)

func draw_ellipse_shadow(feet: Vector2) -> void:
	draw_set_transform(feet, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 26, Color("122d2580"))
	draw_set_transform(Vector2.ZERO)

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("315347")
	style.border_color = Color("728e70")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
