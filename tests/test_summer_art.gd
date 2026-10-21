extends SceneTree
const State=preload("res://scripts/farm_state.gd")
const Art=preload("res://scripts/summer_art.gd")
const World=preload("res://scripts/farm_world.gd")
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func layout(game: Node) -> bool:
	var panel: Panel=game.modal.get_child(1)
	for child in panel.get_children():
		if child is Control and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>panel.size.x+1 or child.position.y+child.size.y>panel.size.y+1): return false
	return true
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var s := State.new()
	var before := s.to_data()
	for crop in State.CROP_DATA.SUMMER:
		check(not s.buy(crop)["ok"] and s.to_data()==before,"spring shop preserves stock and cash")
		check(s.seeds[crop]==0 and s.produce[crop]==0,"new crops grant no starter income")
	var old := before.duplicate(true)
	old.erase("summer_garden")
	for crop in State.CROP_DATA.SUMMER:
		old["seeds"].erase(crop)
		old["produce"].erase(crop)
	check(s._valid_data(old),"0.25 save accepted with eight crops and no tub")
	s._apply_data(old)
	check(s.summer_garden==s.SUMMER_GARDEN.empty() and s.money==120 and s.seeds["turnip"]==8,"migration preserves original economy")
	s.seeds["tomato"]=1
	before=s.to_data()
	check(not s.work(3,"seed","tomato")["ok"] and s.to_data()==before,"retained summer seeds cannot be sown in spring")
	for crop in ["tomato","eggplant"]:
		s=State.new()
		s.day=29
		s.money=400
		check(s.buy(crop,3)["ok"] and s.money==400-State.CROPS[crop]["seed_cost"]*3,"summer seed charge matches catalog")
		s.plots[3]["tilled"]=true
		check(s.work(3,"seed",crop)["ok"] and s.seeds[crop]==2,"summer field sow consumes one")
		for n in range(State.CROPS[crop]["days"]):
			if not s.plots[3]["watered"]: check(s.work(3,"water")["ok"],"summer watering succeeds")
			check(not s.is_mature(s.plots[3]),"new crop not mature before its watered day count")
			s.sleep()
		check(s.is_mature(s.plots[3]) and s.work(3,"harvest")["ok"] and s.produce[crop]==1,"new crop matures and enters inventory")
		before=s.to_data()
		check(not s.work(3,"harvest")["ok"] and s.to_data()==before,"field harvest cannot replay")
		check(s._valid_data(s.to_data()),"new field crop state serializes")
	s=State.new()
	s.day=29
	s.money=500
	s.materials={"wood":20,"stone":20,"herb":0}
	before=s.to_data()
	check(not s.SUMMER_GARDEN.apply(s,"build")["ok"] and s.to_data()==before,"remote build cannot charge resources")
	s.player_position=s.SUMMER_GARDEN.ANCHOR
	check(s.SUMMER_GARDEN.apply(s,"build")["ok"] and s.money==410 and s.materials["wood"]==14 and s.materials["stone"]==16,"tub build charges exact cost")
	before=s.to_data()
	check(not s.SUMMER_GARDEN.apply(s,"build")["ok"] and s.to_data()==before,"tub cannot be built twice")
	check(s.buy("lotus")["ok"],"summer shop sells lotus seedling")
	before=s.to_data()
	check(not s.work(3,"seed","lotus")["ok"] and s.to_data()==before,"lotus rejected in dry field without consuming seed")
	check(s.SUMMER_GARDEN.apply(s,"plant")["ok"] and s.seeds["lotus"]==0,"lotus consumes one seed in own tub")
	before=s.to_data()
	check(not s.SUMMER_GARDEN.apply(s,"plant")["ok"] and s.to_data()==before,"occupied tub cannot consume another seed")
	for n in range(7):
		s.area_id="farm"
		s.player_position=s.SUMMER_GARDEN.ANCHOR
		before=s.to_data()
		check(not s.SUMMER_GARDEN.apply(s,"harvest")["ok"] and s.to_data()==before,"lotus not harvestable early")
		s.sleep()
		check(s.summer_garden["growth"]==n+1,"water tub grows once per sleep without field watering")
		check(s._valid_data(s.to_data()),"each water tub growth day valid")
	check(s.save_game("user://summer_art_test.json")==OK,"water tub saved at full seven days")
	var loaded := State.new()
	check(loaded.load_game("user://summer_art_test.json") and loaded.to_data()==s.to_data(),"full lotus state survives restart")
	loaded.area_id="farm"
	loaded.player_position=loaded.SUMMER_GARDEN.ANCHOR
	check(loaded.SUMMER_GARDEN.apply(loaded,"harvest")["ok"] and loaded.produce["lotus"]==1,"loaded lotus yields one root")
	before=loaded.to_data()
	check(not loaded.SUMMER_GARDEN.apply(loaded,"harvest")["ok"] and loaded.to_data()==before,"lotus cannot harvest twice")
	var plan := loaded.ESTATE.shipping_plan(loaded)
	check(plan["earnings"]==110 and loaded.ESTATE.ship(loaded,plan["guard"])["ok"] and loaded.produce["lotus"]==0,"lotus uses actual confirmed shipping path")
	s.day=56
	s.summer_garden["growth"]=3
	s.sleep()
	check(s.day==57 and s.summer_garden["growth"]==4,"season transition preserves and grows planted lotus")
	for bad in [{"built":false,"planted":true,"growth":1},{"built":true,"planted":false,"growth":1},{"built":true,"planted":true,"growth":8},{"built":true,"planted":true,"growth":1.5}]:
		var data := s.to_data()
		data["summer_garden"]=bad
		check(not s._valid_data(data),"corrupt water garden rejected")
	var invalid := s.to_data()
	invalid["plots"][3]={"tilled":true,"crop":"lotus","growth":1,"watered":true}
	check(not s._valid_data(invalid),"save cannot inject lotus into dry field")
	for entry in [[Art.CROPS,Art.FRAMES.CROPS,Vector2(1536,1024)],[Art.FACILITIES,Art.FRAMES.FACILITIES,Vector2(2172,724)],[Art.EDRIC,Art.FRAMES.EDRIC,Vector2(1024,1536)],[Art.SUYUE,Art.FRAMES.SUYUE,Vector2(1254,1254)]]:
		for row in entry[1]:
			for data in row:
				check(Rect2(Vector2.ZERO,entry[0].get_size()).encloses(Art.frame_region(entry[0],data,entry[2])) and data[2]>0 and data[3]>0,"registered production frame inside atlas")
	var world := World.new()
	world.state=s
	check(not world.blocked(s.SUMMER_GARDEN.ANCHOR),"water garden anchor remains walkable")
	check(world.interaction_hitbox("lotus_tub").has_point(s.SUMMER_GARDEN.POINT),"pond planter has its own selectable hitbox")
	world.free()
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_allowed=false
	game._close_modal()
	game.state=State.new()
	game.state.day=29
	game.state.area_id="farm"
	game.state.player_position=s.SUMMER_GARDEN.ANCHOR
	game._mount_area()
	game._interact("lotus_tub")
	check(is_instance_valid(game.modal) and layout(game),"actual pond interaction opens a fitting water garden card")
	before=game.state.to_data()
	game._process(5)
	check(game.state.to_data()==before,"water garden browsing pauses time and grants no resources")
	game._close_modal()
	game.inventory_panels.bag(3)
	var icons := 0
	for child in game.modal.get_child(1).get_children():
		if child is TextureRect: icons+=1
	check(icons==2 and layout(game),"eggplant and lotus harvest icons visible in real bag")
	game.inventory_panels.shop(3)
	check(is_instance_valid(game.modal) and layout(game) and game.inventory_panels.pages(State.CROP_ORDER)==4,"fourth shop page accessible for all summer crops")
	game.inventory_panels.seeds(3)
	check(is_instance_valid(game.modal) and layout(game) and game.inventory_panels.pages(State.CROP_DATA.FIELD)==4,"field seed menu has ten dry-field species")
	game.state.area_id="town"
	game.state.day=42
	game.journey_panels.summer(3)
	check(is_instance_valid(game.modal) and layout(game),"summer donation page includes final three crops")
	game.audio_system.shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://summer_art_test.json"+suffix))
	print("SUMMER ART: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
