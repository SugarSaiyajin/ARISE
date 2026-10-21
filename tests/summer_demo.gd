extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/summer-0.26-"+label+".png")
func frames(n: int = 30) -> void:
	for i in range(n): await process_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_allowed=false
	game.audio_system.shutdown()
	game._close_modal()
	game.state=game.State.new()
	game.state.day=34
	game.state.money=1500
	game.state.materials={"wood":100,"stone":100,"herb":20}
	game.state.life["irrigator"]=true
	game.state.estate["fixtures"]=[2,3,1]
	game.state.summer_garden={"built":true,"planted":true,"growth":7}
	for i in range(12):
		var crop: String="tomato" if i%2==0 else "eggplant"
		game.state.plots[i]={"tilled":true,"crop":crop,"growth":game.State.CROPS[crop]["days"] if i<7 else 2,"watered":true}
	game.state.player_position=Vector2(282,130)
	game._mount_area()
	game._update_ui()
	await frames()
	await shot("farm")
	game.state.player_position=game.state.SUMMER_GARDEN.ANCHOR
	game._update_ui()
	game._interact("lotus_tub")
	await shot("lotus")
	await frames(45)
	game.estate_panels.water_garden_apply("harvest")
	await shot("harvest")
	game.inventory_panels.bag(3)
	await shot("items")
	await frames(30)
	game.inventory_panels.shop(3)
	await shot("seeds")
	await frames(45)
	game.estate_panels.facility(0,2)
	await shot("facilities")
	await frames(45)
	game._close_modal()
	for id in ["edric","suyue"]:
		game.state.minute=470
		game.state.area_id="ranch_poultry"
		game.state.player_position=Vector2(190,205)
		game._mount_area()
		game._update_ui()
		for i in range(60):
			game.state.minute+=0.2
			await process_frame
		await shot(id)
		game.ranch_panels.visitor(id)
		await frames(30)
		game._close_modal()
	var card: Panel=game._open_modal("艾德里克與素月 · 行走方向","桌面Godot實際渲染 · 正面、左右側面與背面",460)
	var gallery := preload("res://tests/summer_gallery.gd").new()
	gallery.position=Vector2(28,98)
	gallery.size=Vector2(424,290)
	card.add_child(gallery)
	await frames(12)
	await shot("residents")
	await frames(90)
	quit()
