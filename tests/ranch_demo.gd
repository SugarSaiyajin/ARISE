extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://docs/ranch-0.21-"+name+".png")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled = false
	game.audio_system.playback_enabled = false
	game.save_allowed = false
	game._close_modal()
	game.state = game.State.new()
	game.state.money = 2500
	game.state.materials = {"wood":40,"stone":30,"herb":10}
	game.state.minute = 560
	game._mount_area()
	game._update_ui()
	await capture("farm")
	game._show_style()
	await capture("travelers")
	game._close_modal()
	for home in range(4):
		game.state.area_id = "farm"
		game.State.RANCH.build(game.state,home)
		game.travel_lock = 0
		game._change_area(game.State.RANCH_DATA.AREAS[home])
		for id in game.State.RANCH_DATA.ORDER:
			if game.State.RANCH_DATA.SPECIES[id]["home"]==home:
				game.State.RANCH.buy(game.state,id)
				if id!="hen": game.state.ranch["animals"][id]["age"] = game.State.RANCH_DATA.SPECIES[id]["days"]
		game.world.actor = game.state.player_position
		game.world.set_process(false)
		game._update_ui()
		await capture("habitat-"+str(home))
		if home==1:
			game.ranch_panels.animal("rabbit")
			await capture("rabbit")
			game._close_modal()
	game.ranch_panels.visitor("yunji")
	await capture("visitor")
	game._close_modal()
	game.ranch_panels.products(2)
	await capture("products")
	game._close_modal()
	game.state.hero_style = "female"
	game.world.queue_redraw()
	await capture("female")
	game.ranch_panels.hub()
	await capture("hub")
	game.free()
	quit()
