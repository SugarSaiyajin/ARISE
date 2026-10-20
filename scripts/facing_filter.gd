extends RefCounted

const MARGIN := deg_to_rad(5.0)
const VECTORS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP,
	Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]
var row := 0
var initialized := false

static func nearest(direction: Vector2) -> int:
	if not direction.is_finite() or direction.is_zero_approx():
		return 0
	var sector := posmod(int(floor((direction.angle() + PI / 8.0) / (PI / 4.0))), 8)
	return [2, 5, 0, 4, 1, 6, 3, 7][sector]

func select(direction: Vector2, snap: bool = false) -> int:
	if not direction.is_finite() or direction.is_zero_approx():
		return row
	if snap or not initialized:
		row = nearest(direction)
		initialized = true
		return row
	var difference := absf(wrapf(direction.angle() - VECTORS[row].angle(), -PI, PI))
	if difference > PI / 8.0 + MARGIN:
		row = nearest(direction)
	return row
