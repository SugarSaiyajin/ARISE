extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/living-0.27-"+name+".png")
func frames(count: int = 35) -> void:
	for i in range(count): await process_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=game.State.new()
	game.state.day=34
	game.state.area_id="town"
	game.state.player_position=Vector2(205,155)
	game.state.minute=605
	game._mount_area()
	game._update_ui()
	for i in range(60):
		game.state.minute+=0.15
		await process_frame
	await shot("town")
	for page in range(3):
		var card: Panel=game._open_modal("居民四向步態 %d /3" % (page+1),"桌面Godot實際渲染 · 開發檢視頁",460)
		var gallery := preload("res://tests/living_gallery.gd").new()
		gallery.position=Vector2(28,98)
		gallery.size=Vector2(424,312)
		gallery.page=page
		card.add_child(gallery)
		await frames(15)
		await shot("residents-%d" % (page+1))
		await frames(60)
	game._close_modal()
	game.state.area_id="house"
	game.state.player_position=game.state.HOME.STORAGE
	game.state.energy=68
	game.state.produce["tomato"]=8
	game.state.produce["eggplant"]=5
	game.state.produce["lotus"]=3
	game.state.produce["potato"]=2
	game.state.produce["wheat"]=2
	game.state.materials["herb"]=5
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("house")
	game.home_panels.storage(2,5)
	await shot("storage")
	game.state.HOME.transfer(game.state,"tomato",true,5)
	game.home_panels.storage(2,5)
	await frames()
	await shot("stored")
	game._show_cookbook(9)
	await shot("recipe")
	game._cook_meal("summer_stew",9)
	await frames()
	await shot("cooked")
	game._close_modal()
	game.state.player_position=game.state.HOME.CHAIR
	game.home_panels.tea_table()
	await shot("tea")
	game.home_panels.rest()
	game.home_panels.theme()
	await frames()
	await shot("rested")
	game._close_modal()
	game.state.area_id="ranch_meadow"
	game.state.ranch["homes"][1]=true
	for id in ["rabbit","sheep"]:
		game.state.ranch["animals"][id]["owned"]=true
		game.state.ranch["animals"][id]["age"]=4
		game.state.ranch["animals"][id]["ready"]=1
	game.state.player_position=Vector2(175,177)
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("animals")
	game.world.animate_animal("rabbit","feed")
	await frames(5)
	await shot("feeding")
	await frames(50)
	game._close_modal()
	game.state.area_id="town"
	game.state.player_position=Vector2(215,125)
	game.state.day=30
	game._mount_area()
	game._update_ui()
	game._interact("notice")
	await frames()
	await shot("summer-request")
	quit()
