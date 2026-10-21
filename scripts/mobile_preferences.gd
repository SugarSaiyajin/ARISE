extends RefCounted
var stick_size := 148
var deadzone := 0.25
var tap_navigation := true
var path := "user://touch_preferences.cfg"
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path)!=OK: return
	var size_value: Variant=config.get_value("touch","size",148)
	var zone_value: Variant=config.get_value("touch","deadzone",0.25)
	var tap_value: Variant=config.get_value("touch","tap_navigation",true)
	stick_size=size_value if size_value is int and size_value in [148,160] else 148
	deadzone=zone_value if zone_value is float and zone_value in [0.25,0.35] else 0.25
	tap_navigation=tap_value if tap_value is bool else true
func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("touch","size",stick_size)
	config.set_value("touch","deadzone",deadzone)
	config.set_value("touch","tap_navigation",tap_navigation)
	return config.save(path)
