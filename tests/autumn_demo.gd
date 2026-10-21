extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/autumn-0.29-"+name+".png")
func frames(count: int = 45) -> void:
	for i in range(count): await process_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=game.State.new()
	game.state.day=70
	game.state.area_id="farm"
	game.state.player_position=Vector2(272,180)
	for p in game.state.plots: p["crop"]=""
	for row in range(3):
		var id: String=game.State.CROP_DATA.AUTUMN[row]
		for col in range(4):
			game.state.plots[row*7+col+1]={"tilled":true,"crop":id,"growth":int(col*game.State.CROPS[id]["days"]/3.0),"watered":true}
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("farm")
	await frames()
	game.journey_panels.calendar()
	await shot("calendar")
	await frames()
	game.inventory_panels.shop(4)
	await shot("seeds")
	await frames()
	game.inventory_panels.bag(4)
	await shot("crops")
	await frames()
	game._close_modal()
	game.state.area_id="town"
	game.state.player_position=Vector2(210,191)
	game.state.minute=1020
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("town")
	await frames()
	game.autumn_panels.hub()
	await shot("fair")
	await frames()
	for id in game.State.CROP_DATA.AUTUMN:
		game.state.produce[id]=4
		game.autumn_panels.donate(id)
	game.autumn_panels.story()
	await shot("choice")
	await frames()
	game.autumn_panels.finish(2)
	await shot("memory")
	await frames()
	game.autumn_panels.workshop()
	await shot("workshop")
	await frames()
	game.autumn_panels.cook("grape_juice")
	await shot("juice")
	await frames()
	game._close_modal()
	game.state.area_id="house"
	game.state.player_position=Vector2(239,185)
	game._mount_area()
	game._update_ui()
	game._show_cookbook(game.State.COOKING.ORDER.find("harvest_soup"))
	await shot("recipe")
	await frames()
	game._close_modal()
	game.state.area_id="town"
	game.state.minute=1110
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("evening")
	await frames()
	print("AUTUMN DEMO COMPLETE: staged desktop Godot with mobile UI, no physical device footage")
	quit()
