extends SceneTree
const State=preload("res://scripts/farm_state.gd")
const Art=preload("res://scripts/resident_walk_art.gd")
const Behavior=preload("res://scripts/animal_behavior.gd")
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void: run.call_deferred()
func layout(game: Node) -> bool:
	var card: Panel=game.modal.get_child(1)
	for child in card.get_children():
		if child is Control and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>card.size.x+1 or child.position.y+child.size.y>card.size.y+1): return false
	return true
func run() -> void:
	var s := State.new()
	var old := s.to_data()
	old.erase("home")
	for id in ["summer_stew","eggplant_bake","lotus_tea"]: old["meals"].erase(id)
	check(s._valid_data(old),"0.26 save accepted without home or seasonal meals")
	s._apply_data(old)
	check(s.home==s.HOME.empty() and s.meals["lotus_tea"]==0,"old save gains no free storage, rest or meals")
	s.produce["tomato"]=7
	var before := s.to_data()
	check(not s.HOME.transfer(s,"tomato",true,5)["ok"] and s.to_data()==before,"remote storage cannot move inventory")
	s.area_id="house"
	s.player_position=s.HOME.STORAGE
	check(s.HOME.transfer(s,"tomato",true,5)["ok"] and s.produce["tomato"]==2 and s.home["stored"]["tomato"]==5,"deposit conserves exact crop quantity")
	before=s.to_data()
	check(not s.HOME.transfer(s,"tomato",true,5)["ok"] and s.to_data()==before,"insufficient deposit is atomic")
	check(s.HOME.transfer(s,"tomato",false,1)["ok"] and s.produce["tomato"]==3 and s.home["stored"]["tomato"]==4,"withdraw conserves quantity")
	s.area_id="farm"
	check(s.sell_all()["ok"] and s.home["stored"]["tomato"]==4 and s.produce["tomato"]==0,"shipping never sells home storage")
	s.area_id="house"
	s.produce["potato"]=1
	before=s.to_data()
	check(not s.cook("summer_stew")["ok"] and s.to_data()==before,"stored crops cannot be silently consumed by cooking")
	s.player_position=s.HOME.STORAGE
	check(s.HOME.transfer(s,"tomato",false,1)["ok"] and s.cook("summer_stew")["ok"],"withdrawn crop can be cooked")
	for recipe in ["summer_stew","eggplant_bake","lotus_tea"]:
		for ingredient in State.COOKING.RECIPES[recipe]["ingredients"]: s.get(ingredient["stock"])[ingredient["item"]]=1
		check(s.cook(recipe)["ok"],"seasonal cooking uses all actual ingredients")
		s.energy=0
		check(s.eat_meal(recipe)["ok"] and s.energy==State.COOKING.RECIPES[recipe]["energy"],"seasonal meal restores defined stamina")
	s.player_position=s.HOME.CHAIR
	s.energy=97
	var minute := s.minute
	check(s.HOME.rest(s)["ok"] and s.energy==100 and s.minute==minute+20,"chair rest capped at100 and costs20 minutes")
	before=s.to_data()
	check(not s.HOME.rest(s)["ok"] and s.to_data()==before,"daily rest cannot repeat")
	check(s.save_game("user://living_test.json")==OK,"storage, seasonal meal and rest save")
	var loaded := State.new()
	check(loaded.load_game("user://living_test.json") and loaded.to_data()==s.to_data(),"home inventory and rest flag survive restart")
	loaded.energy=0
	before=loaded.to_data()
	check(not loaded.HOME.rest(loaded)["ok"] and loaded.to_data()==before,"restart cannot bypass daily rest flag")
	s.sleep()
	s.player_position=s.HOME.CHAIR
	s.energy=90
	check(s.HOME.rest(s)["ok"] and s.energy==98,"next day allows exactly one new short rest")
	for n in range(3): check(s.HOME.theme(s)["ok"] and s._valid_data(s.to_data()),"all home themes valid and reversible")
	for key in ["theme","rested_day"]:
		for bad in [-1,0.5,INF,"1",null]:
			var data := s.to_data()
			data["home"][key]=bad
			check(not s._valid_data(data),"invalid home counters rejected")
	var bad_stock := s.to_data()
	bad_stock["home"]["stored"]["tomato"]=-1
	check(not s._valid_data(bad_stock),"negative stored crops rejected")
	s.area_id="town"
	for day in range(29,35):
		s.day=day
		var id := s.daily_request_id()
		if id.begins_with("summer_"):
			check(s.accept_request()["ok"],"seasonal request accepted from actual daily board")
			var request: Dictionary=State.REQUESTS.REQUESTS[id]
			for category in ["produce","materials","goods"]:
				for item in request[category]: s.get(category)[item]=request[category][item]
			var money := s.money
			check(s.deliver_request(request["recipient"])["ok"] and s.money==money+request["reward"],"seasonal request consumes items and rewards exact amount")
			before=s.to_data()
			check(not s.deliver_request(request["recipient"])["ok"] and s.to_data()==before,"seasonal commission cannot replay")
	for entry in [["npc","tomato"],["smith","eggplant"],["suyue","lotus"]]:
		s=State.new()
		s.day=29
		var id: String=entry[0]
		s.area_id="town" if id!="suyue" else "ranch_poultry"
		s.player_position=State.RESIDENTS.position(id,420,false) if id!="suyue" else State.RANCH_DATA.visitor_position(id,s.area_id,420,false)
		s.produce[entry[1]]=2
		check(s.JOURNEY.gift(s,id,"produce:"+entry[1])["ok"] and s.produce[entry[1]]==1,"new favorite crop gift consumes one")
		before=s.to_data()
		check(not s.JOURNEY.gift(s,id,"produce:"+entry[1])["ok"] and s.to_data()==before,"new seasonal gifts respect daily limit")
	for id in Art.IDS.values():
		var texture: Texture2D=Art.TEXTURES[id]
		check(texture.get_width()<=512 and texture.get_height()<=512,"new character texture import fits mobile budget")
		for row in Art.F.FRAMES[id]:
			for frame in row:
				check(frame[0]>=0 and frame[1]>=0 and frame[0]+frame[2]<=Art.F.SIZES[id][0] and frame[1]+frame[3]<=Art.F.SIZES[id][1] and frame[4]>=0 and frame[5]>0,"all112 sprite frames and pivots inside source")
	check(State.RANCH_DATA.visitor_direction("edric","ranch_poultry",470,true)==Vector2.ZERO,"rain shelter is stationary and never plays walking frames")
	check(State.RANCH_DATA.visitor_direction("edric","ranch_poultry",440,false)==Vector2.ZERO,"working pause does not play walking frames")
	for minute_at in [470,525,550,560]:
		check(State.RANCH_DATA.visitor_direction("edric","ranch_poultry",minute_at,false).length()>0,"walking segments use an actual motion vector")
	for id in State.RANCH_DATA.VISITORS:
		for rain in [false,true]:
			for minute_at in range(420,1320,10):
				var area: String=State.RANCH_DATA.visitor_area(id,minute_at,rain)
				var point: Vector2=State.RANCH_DATA.visitor_position(id,area,minute_at,rain)
				var world=preload("res://scripts/culture_world.gd").new() if area.begins_with("culture") else preload("res://scripts/ranch_world.gd").new()
				world.area_id=area
				check(not world.blocked(point),"all visitor work, rest and chat route samples are walkable")
				world.free()
	s=State.new()
	s.ranch["animals"]["rabbit"]["owned"]=true
	s.ranch["animals"]["rabbit"]["ready"]=1
	before=s.to_data()
	for id in State.RANCH_DATA.ORDER:
		for time in [0.0,2.0,5.0,8.0]:
			var pose := Behavior.pose(s,id,time,20)
			check(pose["frame"] in [0,1,2,3] and s.to_data()==before,"animal idle and proximity affect presentation only")
	check(Behavior.pose(s,"rabbit",0,80)["ready"]==1,"ready products available as persistent visual marker")
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=State.new()
	game.state.area_id="house"
	game.state.player_position=game.state.HOME.STORAGE
	game._mount_area()
	for page in range(4):
		game.home_panels.storage(page,5)
		check(layout(game),"all storage pages and quantity buttons fit mobile card")
		before=game.state.to_data()
		game._process(20)
		check(game.state.to_data()==before,"storage browsing pauses clock without moving stock")
	game._close_modal()
	game._interact("home_chair")
	check(layout(game),"actual chair interaction opens fitting menu")
	for index in range(9,12):
		game._show_cookbook(index)
		check(layout(game),"new recipes fit existing cookbook")
	game.journey_panels.gifts("npc",4)
	check(layout(game),"fifth gift page fits after seasonal expansion")
	game._close_modal()
	for anchor in game.world.interactions().values():
		check(not game.world.blocked(anchor) and not game.navigation.get_point_path(Vector2i(game.state.player_position/8),Vector2i(anchor/8)).is_empty(),"all house furniture anchors and exit remain reachable")
	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://living_test.json"+suffix))
	print("LIVING VILLAGE: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
