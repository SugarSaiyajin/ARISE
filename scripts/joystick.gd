extends Control

signal engaged
signal released

var deadzone := 0.25
var direction := Vector2.ZERO
var finger := -1
var mouse_down := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().mouse_exited.connect(_mouse_left)

func _mouse_left() -> void:
	if mouse_down: release_pointer()

func update_pointer(p: Vector2) -> void:
	direction = (p - size / 2.0) / maxf(1.0, size.x * 0.34)
	if direction.length() > 1:
		direction = direction.normalized()
	var amount := direction.length()
	if amount < deadzone:
		direction = Vector2.ZERO
	else:
		direction = direction.normalized()*clampf((amount-deadzone)/(1.0-deadzone),0,1)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and finger < 0:
			finger = event.index
			engaged.emit()
			update_pointer(event.position)
		elif (not event.pressed or event.canceled) and event.index == finger:
			release_pointer()
		accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		update_pointer(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if finger >= 0:
			return
		mouse_down = event.pressed
		if mouse_down:
			engaged.emit()
			update_pointer(event.position)
		else:
			release_pointer()
		accept_event()
	elif event is InputEventMouseMotion and mouse_down:
		update_pointer(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	# GUI capture may lose a release after dragging outside the control or under a modal.
	if event is InputEventScreenDrag and event.index == finger:
		update_pointer(get_global_transform_with_canvas().affine_inverse()*event.position)
	elif event is InputEventScreenTouch and (not event.pressed or event.canceled) and event.index == finger:
		release_pointer()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and mouse_down:
		release_pointer()
	elif event is InputEventMouseMotion and mouse_down and not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		release_pointer()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_EXIT_TREE]:
		release_pointer()

func release_pointer() -> void:
	var had_control := finger >= 0 or mouse_down
	direction = Vector2.ZERO
	finger = -1
	mouse_down = false
	if had_control: released.emit()
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var radius := size.x * 0.46
	draw_circle(center, radius, Color("203d36dd"))
	draw_arc(center, radius - 1, 0, TAU, 48, Color("bcc9a9aa"), 2, true)
	for offset in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_circle(center + offset * radius * 0.72, 3, Color("d5d3adbb"))
	draw_circle(center + direction * radius * 0.58, radius * 0.40, Color("a7baa2"))
	draw_circle(center + direction * radius * 0.58 + Vector2(-3, -4), radius * 0.25, Color("c4cdb0"))
