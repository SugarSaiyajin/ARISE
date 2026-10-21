extends Button

# Native Buttons use mouse events. Explicit touch handling allows a second
# finger to operate tools while the first finger holds the joystick.
var mouse_held := false
var touch_id := -1
var touch_inside := false

func is_held() -> bool:
	return (touch_id >= 0 and touch_inside) or mouse_held

func cancel_touch() -> void:
	mouse_held = false
	touch_id = -1
	touch_inside = false
	modulate = Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_held = event.pressed
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and touch_id < 0:
			touch_id = event.index
			touch_inside = true
			modulate = Color(1.15, 1.15, 1.05)
			if action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS:
				pressed.emit()
			accept_event()
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			touch_inside = false
			modulate = Color.WHITE
			if action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE and Rect2(Vector2.ZERO, size).has_point(event.position):
				pressed.emit()
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_inside = Rect2(Vector2.ZERO, size).has_point(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == touch_id and (not event.pressed or event.canceled):
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		var activate: bool = not disabled and not event.canceled and touch_inside and Rect2(Vector2.ZERO,size).has_point(local) and action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE
		cancel_touch()
		if activate: pressed.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_inside = Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		mouse_held = false
	elif event is InputEventMouseMotion and not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		mouse_held = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_touch()
