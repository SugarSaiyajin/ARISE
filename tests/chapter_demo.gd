extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/chapter-0.28-"+name+".png")
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
	game._mount_area()
	game._update_ui()
	game.chapter_panels.hub()
	await shot("hub")
	await frames()
	game.state.area_id="town"
	game.state.friendship=5
	game.state.player_position=game.state.RESIDENTS.position("npc",420,false)
	game._mount_area()
	game._update_ui()
	game.chapter_panels.story("npc",0)
	await shot("story")
	await frames()
	game.chapter_panels.story("npc",1)
	await shot("choice")
	await frames()
	game.chapter_panels.choose_story("npc",2)
	await shot("remembered")
	await frames()
	game._close_modal()
	game.state.area_id="house"
	game.state.player_position=Vector2(239,185)
	game._mount_area()
	game._update_ui()
	game.chapter_panels.furnishings()
	game.chapter_panels.furniture_select(6)
	for i in range(4): game.chapter_panels.furniture_move(Vector2(8,0))
	await shot("furniture-preview")
	await frames()
	game.chapter_panels.furniture_select(1)
	game.chapter_panels.furniture_rotate()
	await shot("rotation")
	await frames()
	game.chapter_panels.furniture_apply()
	game._close_modal()
	await frames()
	await shot("room")
	game.chapter_panels.furnishings()
	game.chapter_panels.furniture[0]=[224,185,0]
	game.chapter_panels.furniture_page()
	await shot("blocked")
	await frames()
	game._close_modal()
	game.state.area_id="ranch_meadow"
	game.state.money=1000
	game.state.materials={"wood":30,"stone":30,"herb":0}
	game.state.ranch["homes"][1]=true
	game.state.RANCH.buy(game.state,"rabbit")
	game.state.RANCH.buy_feed(game.state)
	game.state.RANCH.buy_feed(game.state)
	for day in range(14):
		game.state.area_id="ranch_meadow"
		game.state.RANCH.feed(game.state,"rabbit")
		game.state.RANCH.care(game.state,"rabbit")
		game.state.GROWTH.interact(game.state,"rabbit")
		game.state.sleep()
	game.state.area_id="ranch_meadow"
	game.state.player_position=Vector2(175,177)
	game._mount_area()
	game._update_ui()
	game.chapter_panels.animal("rabbit")
	await shot("growth")
	await frames()
	game.chapter_panels.growth_claim("rabbit",2)
	await shot("milestone")
	game._close_modal()
	game.state.area_id="culture_grove"
	game.state.player_position=game.state.JOURNEY.CLUES[0]
	game._mount_area()
	game._update_ui()
	game.chapter_panels.journey(0)
	await shot("journey")
	await frames()
	game.chapter_panels.journey_apply(0,0)
	game.state.player_position=Vector2(180,169)
	game.state.materials["herb"]=2
	game.chapter_panels.journey_apply(0,1)
	game.state.life["stock"]["moon_cloth"]=1
	game.chapter_panels.journey(0)
	await shot("craft-delivery")
	await frames()
	game.chapter_panels.journey_apply(0,2)
	await shot("journey-done")
	game._close_modal()
	game.state.area_id="farm"
	game.state.player_position=Vector2(123,139)
	game.state.produce["turnip"]=4
	game.state.produce["wheat"]=4
	game._mount_area()
	game._update_ui()
	game.chapter_panels.order_preview(0)
	await shot("order")
	await frames()
	var guard: String=game.state.CHAPTER.fingerprint(game.state)
	game.chapter_panels.order_apply(0,guard)
	await shot("order-done")
	game.chapter_panels.goals()
	await shot("goals")
	await frames()
	quit()
