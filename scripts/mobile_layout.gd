extends RefCounted

const DESIGN_SIZE := Vector2(960, 540)

static func fit_safe_frame(viewport_size: Vector2, safe_area: Rect2) -> Rect2:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	var safe := bounds.intersection(safe_area)
	if not safe.has_area():
		safe = bounds
	var factor := minf(safe.size.x / DESIGN_SIZE.x, safe.size.y / DESIGN_SIZE.y)
	var fitted := DESIGN_SIZE * factor
	return Rect2(safe.position + (safe.size - fitted) / 2.0, fitted)
