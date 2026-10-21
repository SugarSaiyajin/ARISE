extends SceneTree
var game: Node
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	_run.call_deferred()
func layout() -> bool:
	var card: Panel=game.modal.get_child(1)
	for child in card.get_children():
		if child is Control and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>card.size.x+1 or child.position.y+child.size.y>card.size.y+1): return false
	return true
func _run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game.testing_panels.archive.directory="user://panel_test_archives"
	var before: Dictionary=game.state.to_data()
	game.testing_panels.hub()
	check(layout(),"archive hub fits logical mobile viewport")
	game.testing_panels.guide()
	check(layout(),"revisitable onboarding fits")
	game.testing_panels.slot(1)
	check(layout(),"checkpoint confirmation fits")
	game.testing_panels.export_code()
	check(layout(),"selectable portable code fits")
	game.testing_panels.import_code()
	check(layout(),"import editor and buttons fit")
	game.testing_panels.confirm(before)
	check(game.state.to_data()==before,"protected save cannot be overwritten through restore")
	game.save_allowed=true
	game.testing_panels.confirm(before)
	check(layout(),"restore preview fits")
	game._show_menu()
	var card: Panel=game.modal.get_child(1)
	var linked := false
	for child in card.get_children():
		if child is Button and child.text=="存檔與試玩設定":
			child.pressed.emit()
			linked=true
	check(linked and game.modal.get_child(1).get_child_count()>8,"settings reachable from existing menu")
	var time: float=game.state.minute
	game._process(60)
	check(game.state.minute==time,"backup and settings menus pause simulation")
	check(game.state.to_data()==before,"browsing settings grants no resources and consumes no time")
	game.testing_panels.toggle_fps()
	check(Engine.max_fps==30,"60 FPS can switch to power-saving cap")
	var config := ConfigFile.new()
	check(config.load("user://display_preferences.cfg")==OK and config.get_value("display","fps")==30,"frame cap persists independently of save")
	game.testing_panels.toggle_fps()
	check(Engine.max_fps==60,"30 FPS can return to smooth cap")
	game._close_modal()
	game.save_allowed=false
	game.state=game.State.new()
	game._mount_area()
	var start: float=game.state.minute
	for i in range(30): game._process(1.0/30.0)
	var elapsed30: float=game.state.minute-start
	game.state.minute=start
	for i in range(60): game._process(1.0/60.0)
	check(is_equal_approx(elapsed30,game.state.minute-start),"30 and 60 FPS advance identical game time")
	game.queue_free()
	await process_frame
	print("TESTING PANELS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
