extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/estate-0.25-"+label+".png")
func frames(count: int = 24) -> void:
	for i in range(count): await process_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=game.State.new()
	game.state.money=800
	game.state.materials={"wood":100,"stone":100,"herb":30}
	game.state.life["irrigator"]=true
	game._mount_area()
	game._update_ui()
	game.estate_panels.hub()
	await shot("hub")
	await frames()
	game.estate_panels.facility(0,2)
	await shot("build-legal")
	await frames()
	game.state.journey["decor"][0]=1
	game.estate_panels.facility(0,2)
	await shot("build-blocked")
	await frames()
	game.state.journey["decor"][0]=0
	for site in range(3): game.state.ESTATE.build(game.state,site,[2,3,1][site])
	game._close_modal()
	game._mount_area()
	game._update_ui()
	await shot("farm")
	game.estate_panels.field()
	await shot("field")
	await frames()
	game.estate_panels.field_confirm("water")
	await shot("batch-preview")
	await frames()
	game.start_field_batch("water")
	var captured := false
	for i in range(320):
		game._process(1.0/30.0)
		if game.tool_action.active and not captured:
			await shot("watering")
			captured=true
		if not game.batch_running and not game.tool_action.active: break
		await process_frame
	game._sleep()
	game.state.area_id="farm"
	game._mount_area()
	game._update_ui()
	game.start_field_batch("harvest")
	captured=false
	for i in range(320):
		game._process(1.0/30.0)
		if game.tool_action.active and game.tool_action.elapsed>0.12 and not captured:
			await shot("harvest")
			captured=true
		if not game.batch_running and not game.tool_action.active: break
		await process_frame
	game.estate_panels.shipping()
	await shot("shipping")
	await frames()
	game.estate_panels.confirm_shipping()
	game.state.ranch["homes"][1]=true
	game.state.ranch["feed"]=2
	for id in ["rabbit","sheep"]:
		game.state.ranch["animals"][id]["owned"]=true
		game.state.ranch["animals"][id]["age"]=game.State.RANCH_DATA.SPECIES[id]["days"]
	game.state.area_id="ranch_meadow"
	game._mount_area("",false)
	game._update_ui()
	game.estate_panels.ranch_confirm("feed")
	await shot("ranch-preview")
	await frames()
	var plan: Dictionary=game.state.ESTATE.ranch_plan(game.state,"feed")
	game.estate_panels.ranch_apply("feed",plan["guard"])
	game._close_modal()
	await frames(45)
	await shot("ranch-fed")
	game.state.area_id="town"
	game.state.minute=540
	game.state.friendship=3
	game.state.player_position=game.State.RESIDENTS.position("npc",540,false)+Vector2(22,0)
	game._mount_area()
	game.estate_panels.activity_choices("npc")
	await shot("activity-choice")
	await frames()
	game.estate_panels.activity_preview("npc",2)
	await shot("activity")
	await frames()
	game.estate_panels.activity_finish("npc",2)
	game.state.day=3
	game.resident_panels.show("npc")
	await shot("remembered")
	await frames()
	game._close_modal()
	game.state.day=29
	game.state.minute=750
	game.state.area_id="culture_grove"
	game._mount_area("",false)
	game._update_ui()
	game.state.produce["berry"]=1
	game.estate_panels.summer_preview(0)
	await shot("summer-job")
	await frames()
	game.estate_panels.summer_finish(0)
	game.estate_panels.goals()
	await shot("goals")
	await frames()
	game._close_modal()
	game.free()
	quit()
