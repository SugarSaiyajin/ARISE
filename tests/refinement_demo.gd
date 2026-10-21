extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/refinement-0.22-"+label+".png")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled=false
	game.audio_system.playback_enabled=false
	game.save_allowed=false
	game._close_modal()
	game.state=game.State.new()
	for area in ["farm","house","town"]:
		game.state.area_id=area
		game.state.minute=570
		game._mount_area("",false)
		game._update_ui()
		await shot(area)
		if area=="farm":
			for n in range(100): await process_frame
		if area=="house":
			game._show_character()
			for n in range(110): await process_frame
			await shot("idle")
			game._close_modal()
	game.state.day=5
	game.state.minute=750
	for area in game.State.LIFE_DATA.AREAS:
		game.state.area_id=area
		game._mount_area("",false)
		game._update_ui()
		await shot(area)
		for n in range(40): await process_frame
	game.state.area_id="culture_grove"
	game._mount_area("",false)
	game._update_ui()
	game.state.ranch["stock"]["rabbit"]=1
	game.state.ranch["stock"]["worm"]=1
	game.life_panels.recipe("moon_cloth")
	await shot("recipe")
	game.State.LIFE.craft(game.state,"moon_cloth")
	game._close_modal()
	game.state.sleep()
	game.state.area_id="culture_grove"
	game.state.minute=750
	game._mount_area("",false)
	game._update_ui()
	game.State.LIFE.collect(game.state)
	game.life_panels.goods()
	await shot("crafts")
	game._close_modal()
	game.state.ranch["friends"]["lyria"]=3
	game.life_panels.story("lyria",0)
	await shot("story")
	for n in range(60): await process_frame
	game._close_modal()
	game.state.area_id="ranch_meadow"
	game.state.ranch["homes"][1]=true
	game.state.ranch["animals"]["rabbit"]["owned"]=true
	game.state.ranch["animals"]["rabbit"]["age"]=2
	game.state.ranch["animals"]["rabbit"]["fed"]=true
	game._mount_area("",false)
	game.world.animate_animal("rabbit","care")
	game._update_ui()
	await shot("care")
	for n in range(90): await process_frame
	game.free()
	quit()
