extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/journey-0.24-"+label+".png")
func pause_frames(count: int = 25) -> void:
	for i in range(count): await process_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=game.State.new()
	game.state.money=600
	game.state.materials={"wood":50,"stone":50,"herb":50}
	for slot in range(6): game.state.JOURNEY.decorate(game.state,slot,slot%3+1)
	game.state.journey["layout"]=2
	game._mount_area()
	game._update_ui()
	await shot("farm")
	await pause_frames()
	game.journey_panels.controls()
	await shot("controls")
	await pause_frames()
	game.journey_panels.tutorial()
	await shot("tutorial")
	await pause_frames()
	game.journey_panels.view_farm()
	await shot("plan")
	await pause_frames()
	game.journey_panels.upgrade()
	await shot("upgrade")
	game._close_modal()
	game.state.area_id="town"
	game.state.player_position=game.State.RESIDENTS.position("npc",game.state.minute,false)+Vector2(22,0)
	game._mount_area()
	game.state.friendship=10
	game.state.produce["tea"]=2
	game.journey_panels.person("npc")
	await shot("relationship")
	await pause_frames()
	game.journey_panels.gifts("npc",0)
	await shot("gift")
	await pause_frames()
	game.journey_panels.give("npc","produce:tea")
	await pause_frames()
	game.journey_panels.event("npc",1,0)
	await shot("memory")
	await pause_frames()
	game._close_modal()
	game.state.area_id="culture_ember"
	game.state.minute=750
	game._mount_area("",false)
	game._update_ui()
	await shot("culture")
	await pause_frames()
	for clue in range(3):
		game.state.player_position=game.state.JOURNEY.CLUES[clue]
		game.state.JOURNEY.inspect_clue(game.state,clue)
	game.journey_panels.quest(1)
	await shot("quest")
	await pause_frames()
	game._close_modal()
	game.state.day=42
	game.state.area_id="farm"
	game._mount_area()
	game._update_ui()
	await shot("summer")
	await pause_frames()
	game.journey_panels.calendar()
	await shot("calendar")
	await pause_frames()
	game._close_modal()
	game.state.area_id="town"
	game._mount_area("",false)
	for crop in ["turnip","wheat","berry"]:
		game.state.produce[crop]=1
		game.state.JOURNEY.summer_donate(game.state,crop)
	game.journey_panels.summer_story(0)
	await shot("festival")
	await pause_frames()
	game._show_character()
	game.hero_preview.set_process(false)
	game.hero_preview.elapsed=4.8
	await shot("idle-open")
	game.hero_preview.elapsed=5.0
	game.hero_preview.queue_redraw()
	await shot("idle-blink")
	for i in range(65):
		game.hero_preview.elapsed=10.4+i/40.0
		game.hero_preview.queue_redraw()
		await process_frame
	await shot("idle-stretch")
	game._close_modal()
	game.state.hero_style="female"
	game._show_character()
	game.hero_preview.set_process(false)
	game.hero_preview.elapsed=4.8
	await shot("female-open")
	game.hero_preview.elapsed=5.0
	game.hero_preview.queue_redraw()
	await shot("female-blink")
	game._close_modal()
	game.state.area_id="ranch_meadow"
	game.state.ranch["homes"][1]=true
	for id in ["rabbit","sheep"]:
		game.state.ranch["animals"][id]["owned"]=true
		game.state.ranch["animals"][id]["age"]=game.State.RANCH_DATA.SPECIES[id]["days"]
	game._mount_area("",false)
	game._update_ui()
	game.world.animate_animal("rabbit","feed")
	game.world.animate_animal("sheep","care")
	await shot("animals")
	await pause_frames(100)
	game.free()
	quit()
