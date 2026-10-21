extends SceneTree
const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/estate_rules.gd")
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
			printerr("Overflow ",child.name," ",child.position," ",child.size)
			return false
	return true
func walk_to_done(limit: int = 1800) -> void:
	var frames := 0
	while (game.batch_running or not game.path.is_empty() or game.tool_action.active) and frames<limit:
		game._process(1.0/30.0)
		frames+=1
	check(frames<limit,"navigation and field queue finish in bounded frames")
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
	for callback in [game.estate_panels.hub,game.estate_panels.field,game.estate_panels.ranch,game.estate_panels.shipping,game.estate_panels.construction,game.estate_panels.summer,game.estate_panels.goals]:
		var before: Dictionary=game.state.to_data()
		callback.call()
		check(layout(),"estate panel fits mobile card")
		game._process(5)
		check(game.state.to_data()==before,"estate browsing grants nothing and clock remains paused")
	for tool in ["water","harvest"]:
		game.estate_panels.field_confirm(tool)
		check(layout(),"field queue preview fits")
	for action in ["feed","care","collect"]:
		game.estate_panels.ranch_confirm(action)
		check(layout(),"empty or unavailable ranch preview fits")
	for index in range(4):
		game.estate_panels.summer_preview(index)
		check(layout(),"summer collaboration previews fit")
	for id in game.state.JOURNEY.PEOPLE:
		game.estate_panels.activity_choices(id)
		check(layout(),"shared activity choices fit for all residents")
		for choice in [1,2]:
			game.estate_panels.activity_preview(id,choice)
			check(layout(),"both activity branches fit")
	game.state.money=1000
	game.state.materials={"wood":50,"stone":50,"herb":10}
	game.state.life["irrigator"]=true
	for site in range(3):
		for kind in range(4):
			var before: Dictionary=game.state.to_data()
			game.estate_panels.facility(site,kind)
			check(layout() and game.state.to_data()==before,"legal/invalid construction preview is non-mutating and fits")
	game._close_modal()
	for configuration in [[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]:
		game.state.estate["fixtures"]=configuration.duplicate()
		game._mount_area()
		var start := Vector2i(game.state.player_position/8)
		for key in game.world.interactions():
			var anchor: Vector2=game.world.interactions()[key]
			check(not game.world.blocked(anchor),"facility configuration keeps every anchor clear")
			check(not game.navigation.get_point_path(start,Vector2i(anchor/8)).is_empty(),"facility configuration leaves every interaction reachable")
		for i in range(28):
			var target: Vector2=game.world.plot_center(i)
			check(not game.world.blocked(target) and not game.navigation.get_point_path(start,Vector2i(target/8)).is_empty(),"facility configuration leaves all crop plots reachable")
	game.state.player_position=Rules.ANCHORS[0]
	game._update_ui()
	check(game.action_button.text.begins_with("設施"),"new facility interaction is labelled as a facility rather than a farming tool")
	game.state=State.new()
	game._mount_area()
	game._close_modal()
	var initial_energy: int=game.state.energy
	game.start_field_batch("water")
	walk_to_done()
	check([0,1,7,8].all(func(i):return game.state.plots[i]["watered"]) and game.state.energy==initial_energy-8,"batch physically waters each inherited crop exactly once")
	check(not game.batch_running and game.field_queue.is_empty(),"completed field batch releases ownership")
	game.state.sleep()
	game.state.area_id="farm"
	game._mount_area()
	game.start_field_batch("harvest")
	walk_to_done()
	check(game.state.harvested==4 and game.state.produce["turnip"]==4,"batch harvest grants one unit per mature plot")
	game.state=State.new()
	game._mount_area()
	game.start_field_batch("water")
	for i in range(1500):
		game._process(1.0/30.0)
		if game.state.plots[0]["watered"]: break
	game._stop_moving()
	var committed: Dictionary=game.state.to_data()
	for i in range(120): game._process(1.0/30.0)
	check(not game.batch_running and game.field_queue.is_empty() and game.state.energy==committed["energy"],"stop retains committed crop and cannot resume remaining queue")
	game.state=State.new()
	game._mount_area()
	game.start_field_batch("water")
	game._show_menu()
	game._close_modal()
	for i in range(60): game._process(1.0/30.0)
	check(not game.batch_running and game.path.is_empty() and game.state.energy==100,"modal clears uncommitted route and queue")
	game.state=State.new()
	game._mount_area()
	game.state.produce["turnip"]=3
	game._click_world(game.World.BOX)
	walk_to_done()
	check(is_instance_valid(game.modal) and game.state.produce["turnip"]==3,"clicking actual shipping box only opens preview")
	var cash: int=game.state.money
	game.estate_panels.confirm_shipping()
	check(game.state.money==cash+54 and game.state.produce["turnip"]==0,"shipping quote stays valid on the exact arrival frame")
	game.estate_panels.confirm_shipping()
	check(game.state.money==cash+54,"repeating shipping callback cannot pay again")
	game._close_modal()
	game.queue_free()
	await process_frame
	print("ESTATE SCENE TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
