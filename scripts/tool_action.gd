extends RefCounted

# A tool's effects commit once at its start. This transient state only owns
# the pose and movement lock; finishing or cancelling never grants items.
const DURATION := 0.30
var active := false
var elapsed := DURATION
var tool := 0
var target := Vector2.ZERO
var facing := Vector2.DOWN

func begin(new_tool: int, new_target: Vector2, new_facing: Vector2) -> bool:
	if active or new_tool < 0 or new_tool > 3 or not new_target.is_finite() or not new_facing.is_finite() or new_facing.is_zero_approx():
		return false
	tool = new_tool
	target = new_target
	facing = new_facing.normalized()
	elapsed = 0.0
	active = true
	return true

func advance(delta: float) -> void:
	if not active or not is_finite(delta) or delta <= 0:
		return
	elapsed = minf(elapsed + delta, DURATION)
	active = elapsed < DURATION

func finish() -> void:
	active = false
	elapsed = DURATION
