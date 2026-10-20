extends RefCounted

const Data = preload("res://scripts/fishing_data.gd")
var elapsed := 0.0
var bite_window := 1.6
var result := ""

func advance(delta: float) -> void:
	if result != "" or not is_finite(delta) or delta <= 0:
		return
	elapsed += delta
	if elapsed >= Data.WAIT_SECONDS + bite_window:
		result = "late"

func is_biting() -> bool:
	return result == "" and elapsed >= Data.WAIT_SECONDS and elapsed < Data.WAIT_SECONDS + bite_window

func reel() -> String:
	if result == "":
		result = "caught" if is_biting() else "early"
	return result
