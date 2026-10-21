extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Art = preload("res://scripts/approved_art.gd")
const ButtonScript = preload("res://scripts/touch_button.gd")
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

func card() -> Panel:
	return game.modal.get_child(1)

func layout() -> bool:
	var panel := card()
	for child in panel.get_children():
		if child is Button and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>panel.size.x+1 or child.position.y+child.size.y>panel.size.y+1): return false
	return true

func _run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled=false
	game.audio_system.playback_enabled=false
	game.simulation=true
	game.save_allowed=false
	game._close_modal()
	game.state=State.new()
	game._mount_area()
	var button := ButtonScript.new()
	button.position=Vector2(25,25)
	button.size=Vector2(100,50)
	button.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
	root.add_child(button)
	var count := [0]
	button.pressed.connect(func(): count[0]+=1)
	var press := InputEventScreenTouch.new()
	press.index=8
	press.pressed=true
	press.position=Vector2(10,10)
	button._gui_input(press)
	check(button.is_held() and count[0]==0,"release-action touch begins without premature activation")
	var release := InputEventScreenTouch.new()
	release.index=8
	release.pressed=false
	release.position=button.get_global_transform_with_canvas()*Vector2(10,10)
	button._input(release)
	check(not button.is_held() and count[0]==1,"global release activates the intended button exactly once")
	button._gui_input(release)
	check(count[0]==1,"GUI duplicate release cannot activate a second time")
	button._gui_input(press)
	release.position=Vector2(2000,2000)
	button._input(release)
	check(not button.is_held() and count[0]==1,"release outside button clears hold without activating")
	button._gui_input(press)
	release.canceled=true
	button._input(release)
	check(not button.is_held() and count[0]==1,"OS-cancelled button touch never activates")
	await process_frame
	var physical_press := InputEventScreenTouch.new()
	physical_press.index=9
	physical_press.pressed=true
	physical_press.position=button.get_global_transform_with_canvas()*Vector2(10,10)
	root.push_input(physical_press,true)
	await process_frame
	var physical_release := InputEventScreenTouch.new()
	physical_release.index=9
	physical_release.pressed=false
	physical_release.position=physical_press.position
	root.push_input(physical_release,true)
	await process_frame
	check(count[0]==2 and not button.is_held(),"real viewport touch dispatch activates once without native duplicate (count=%d)" % count[0])
	button.free()
	game._walk_to(Vector2(250,200),{})
	game._stop_moving()
	var position: Vector2 = game.state.player_position
	for i in range(30): game._process(1.0/60.0)
	check(game.state.player_position==position and game.path.is_empty(),"explicit stop cannot resume a stale destination")
	var snapshot: Dictionary = game.state.to_data()
	var scale_a := Art.idle_scale(0)
	var scale_b := Art.idle_scale(0.85)
	check(scale_a!=scale_b and scale_b.y>1 and scale_b.y<1.03,"idle breathing varies gently rather than freezing or jumping")
	game.world._process(0.85)
	check(game.state.to_data()==snapshot,"idle animation never changes logical location stamina or saved state")
	for index in range(4):
		game._close_modal()
		game.travel_lock=0
		game.state.minute=750
		game.state.day=5
		game.life_panels.travel(index)
		check(game.state.area_id==State.LIFE_DATA.AREAS[index],"travel reaches each actual culture map")
		for id in game.world.interactions():
			game._walk_to(game.world.interactions()[id],{})
			check(not game.path.is_empty(),"all culture exits workshops gathering and residents are navigable")
		game.life_panels.hub()
		check(layout(),"journey menu fits")
		game._close_modal()
	for page in range(3):
		game.life_panels.workshop(page)
		check(layout(),"all recipe pages fit")
	for id in State.LIFE_DATA.ORDER:
		game.life_panels.recipe(id)
		check(layout(),"all crafting detail pages fit")
	for page in range(2):
		game.life_panels.goods(page)
		check(layout(),"craft product inventory fits")
	game.life_panels.job()
	check(layout(),"empty work-order page fits")
	for id in State.RANCH_DATA.VISITORS:
		game._close_modal()
		game.state.minute=750
		game.state.day=5
		game.state.area_id=State.RANCH_DATA.CULTURES[id]
		game._mount_area()
		game.state.ranch["friends"][id]=3
		game.life_panels.resident(id)
		check(layout(),"each resident commission page fits")
		var money: int = game.state.money
		game.life_panels.story(id,0)
		game._close_modal()
		check(game.state.money==money and not game.state.life["events"][id],"closing story midway never grants a reward")
		game.life_panels.story(id,1)
		check(layout(),"story finale controls fit")
		game.life_panels.finish(id)
		check(game.state.life["events"][id] and game.state.money==money+50,"finale callback commits story once")
		game.life_panels.story(id,1,true)
		game._close_modal()
		check(game.state.money==money+50,"replaying story cannot grant currency")
	game.state.area_id="ranch_poultry"
	game.state.minute=660
	game._mount_area()
	check(not game.world.interactions().has("visitor:edric"),"residents leave ranch at scheduled time")
	game.state.minute=650
	game.world.queue_redraw()
	game._walk_to(game.world.interactions()["visitor:edric"],{"object":"visitor:edric"})
	game.state.minute=660
	game._process(0.01)
	check(game.path.is_empty() and game.pending.is_empty(),"visitor changing maps cancels obsolete pursuit instead of uncontrolled walking")
	game._close_modal()
	check(game.state._valid_data(game.state.to_data()),"complete expanded scene state remains valid")
	game.free()
	print("LIFE SCENE TESTS: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
