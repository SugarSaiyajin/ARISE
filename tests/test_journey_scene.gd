extends SceneTree
const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/journey_rules.gd")
const Touch = preload("res://scripts/touch_button.gd")
var game: Node
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void: run.call_deferred()
func layout() -> bool:
	var panel: Panel=game.modal.get_child(1)
	for child in panel.get_children():
		if child is Control and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>panel.size.x+1 or child.position.y+child.size.y>panel.size.y+1):
			printerr("Overflow: ",child.name," ",child.position," ",child.size)
			return false
	return true
func navigation() -> void:
	var start := Vector2i(game.state.player_position/8)
	for key in game.world.interactions():
		var point: Vector2=game.world.interactions()[key]
		check(not game.world.blocked(point),"interaction anchor remains walkable")
		var path: PackedVector2Array=game.navigation.get_point_path(start,Vector2i(point/8))
		check(not path.is_empty(),"interaction remains reachable from entry")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled=false
	game.audio_system.playback_enabled=false
	game.save_allowed=false
	game._close_modal()
	game.state=State.new()
	game._mount_area()
	for callback in [game.journey_panels.controls,game.journey_panels.hub,game.journey_panels.tutorial,game.journey_panels.farm,game.journey_panels.view_farm,game.journey_panels.upgrade,game.journey_panels.economy,game.journey_panels.calendar,game.journey_panels.quests]:
		var before: Dictionary=game.state.to_data()
		callback.call()
		check(layout(),"new mobile panel fits its card")
		game._process(10)
		check(game.state.to_data()==before,"browsing cannot consume items or advance time")
	for page in range(3):
		game.journey_panels.people(page)
		check(layout(),"all nine residents fit paginated roster")
	for id in Rules.PEOPLE:
		game.journey_panels.person(id)
		check(layout(),"relationship and location fits for every resident")
		for page in range(4):
			game.journey_panels.gifts(id,page)
			check(layout(),"gift pages fit and can be read remotely")
	for slot in range(6):
		game.journey_panels.decor(slot)
		check(layout(),"all decor confirmations fit")
	for page in range(3):
		game.journey_panels.summer(page)
		check(layout(),"summer offerings fit even while festival is closed")
	game._close_modal()
	for choice in range(3):
		game.state.journey["layout"]=choice
		for slot in range(6): game.state.journey["decor"][slot]=slot%3+1
		game._mount_area()
		navigation()
		for index in range(28): check(not game.world.blocked(game.world.plot_center(index)),"all plots remain accessible under every layout")
	for area in State.LIFE_DATA.AREAS:
		game.state.area_id=area
		game.state.minute=750
		game._mount_area("",false)
		navigation()
		for clue in range(3):
			game.state.player_position=Rules.CLUES[clue]
			game._interact("journey_clue:%d" % clue)
			check(is_instance_valid(game.modal) and game.state.journey["clues"][State.LIFE_DATA.AREAS.find(area)] & (1<<clue),"actual interaction dispatch records each culture clue")
			game._close_modal()
		game.journey_panels.quest(State.LIFE_DATA.AREAS.find(area))
		check(layout(),"distinct culture quests fit")
		game._close_modal()
	game.state=State.new()
	game._mount_area()
	game.path=PackedVector2Array([Vector2(400,200)])
	var before: Vector2=game.state.player_position
	game._process(2)
	check(game.state.player_position.distance_to(before)<=6.61,"frame hitch cannot teleport through collision or across farm")
	game._stop_moving()
	game.stick.finger=1
	game.stick.direction=Vector2.RIGHT
	game._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	game._close_modal()
	before=game.state.player_position
	var time: float=game.state.minute
	game._process(30)
	check(game.state.player_position==before and game.state.minute==time and game.stick.finger==-1,"background state blocks simulation even if modal closes")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._close_modal()
	game._process(2)
	check(game.state.player_position==before and game.state.minute==time,"focus loss independently blocks input and time")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	game.stick.finger=2
	game.stick.direction=Vector2.RIGHT
	game.path=PackedVector2Array([Vector2(300,200)])
	game.queued_click=Vector2(100,100)
	game._apply_mobile_layout()
	check(game.stick.finger==-1 and game.stick.direction==Vector2.ZERO and game.path.is_empty() and game.queued_click==null,"safe-area resize releases held control and queued actions")
	var button := Touch.new()
	button.size=Vector2(120,44)
	root.add_child(button)
	var count := [0]
	button.pressed.connect(func(): count[0]+=1)
	var event := InputEventScreenTouch.new()
	event.pressed=true
	event.index=4
	event.position=Vector2(20,20)
	button._gui_input(event)
	event.canceled=true
	button._gui_input(event)
	check(not button.is_held() and count[0]==0,"canceled GUI touch cannot activate a release button")
	button.queue_free()
	game.stick._gui_input(event)
	check(game.stick.finger==-1,"canceled press cannot acquire joystick")
	game._close_modal()
	var original_touch_mode: bool=game.touch_mode
	game.touch_mode=true
	game.mobile_preferences.tap_navigation=false
	game.state.player_position=Vector2(232,200)
	game._click_world(game.world.plot_center(0))
	check(game.path.is_empty() and not game.state.plots[0]["watered"],"manual touch mode cannot start distant automatic movement")
	game.state.player_position=game.world.plot_center(0)+Vector2(0,10)
	game.selected_tool=2
	game._click_world(game.world.plot_center(0))
	check(game.path.is_empty() and game.state.plots[0]["watered"],"manual touch mode can work at close range")
	game.mobile_preferences.path="user://journey_scene_touch.cfg"
	game.journey_panels.change_control("size")
	check(game.stick.size.x==160 and game.stick.position.x+game.stick.size.x<172,"larger joystick leaves tool buttons clear")
	game.journey_panels.change_control("zone")
	check(is_equal_approx(game.stick.deadzone,0.35),"stronger deadzone applies to actual input control")
	var settings := preload("res://scripts/mobile_preferences.gd").new()
	settings.path=game.mobile_preferences.path
	settings.load_settings()
	check(settings.stick_size==160 and settings.deadzone==0.35 and not settings.tap_navigation,"touch preferences survive independent reload")
	game.mobile_preferences.tap_navigation=true
	game.touch_mode=original_touch_mode
	game._close_modal()
	var original: Dictionary = game.state.to_data()
	for day in [28,29,42,56,57]:
		game.state.day=day
		game._update_ui()
		check(game.clock_label.text.begins_with(Rules.season(day)),"HUD follows current season across both boundaries")
	game.state._apply_data(original)
	# Warm all map variants, then repeat 104 transitions and compare the same farm scene.
	var areas := ["farm","house","town","forest","ruins"]+State.RANCH_DATA.AREAS+State.LIFE_DATA.AREAS
	for area in areas:
		game.state.area_id=area
		game.state.route_restored=true
		game._mount_area("",false)
		await process_frame
	game.state.area_id="farm"
	game._mount_area("",false)
	await process_frame
	await process_frame
	var nodes := get_node_count()
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	for cycle in range(8):
		for area in areas:
			game.state.area_id=area
			game._mount_area("",false)
			await process_frame
	game.state.area_id="farm"
	game._mount_area("",false)
	await process_frame
	await process_frame
	check(get_node_count()==nodes,"repeated map changes do not accumulate nodes")
	var after_memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	check(after_memory-memory<8*1024*1024,"repeated map changes have bounded static memory growth")
	var report := {"map_transitions":areas.size()*8,"nodes_before":nodes,"nodes_after":get_node_count(),"static_memory_before":memory,"static_memory_after":after_memory,"physical_android_tested":false,"type":"desktop headless scene lifecycle, not mobile FPS or battery"}
	var file := FileAccess.open("res://build/checks/journey-soak-"+("mobile" if game.touch_mode else "desktop")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	game._close_modal()
	game.queue_free()
	await process_frame
	print("JOURNEY SCENE TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
