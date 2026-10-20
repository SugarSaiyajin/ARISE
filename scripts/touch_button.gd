extends Button

# Native Buttons use mouse events. Explicit touch handling allows a second
# finger to operate tools while the first finger holds the joystick.
var touch_id := -1
var touch_inside := false

func is_held() -> bool:
	return (touch_id >= 0 and touch_inside) or is_pressed()

func cancel_touch() -> void:
	touch_id = -1
	touch_inside = false
	modulate = Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_touch()
