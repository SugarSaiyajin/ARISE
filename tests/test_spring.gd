extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Area = preload("res://scripts/area_world.gd")
const SAVE := "user://spring_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: ",label)

func _initialize() -> void:
	var s := State.new()
	check(State.CROP_DATA.SPRING.size()==8 and State.CROP_ORDER.size()==11 and State.PROCESSING.ORDER.size()==8 and State.COOKING.ORDER.size()==12,"complete spring content catalogs")
	for crop in State.CROP_ORDER:
		check(State.CROPS[crop]["price"] > State.CROPS[crop]["seed_cost"] and State.CROPS[crop]["days"] in range(2,8),"crop has positive margin and defined growth")
	var legacy := s.to_data()
	legacy.erase("spring_progress")
	for category in ["seeds","produce"]:
		for crop in State.CROP_ORDER:
			if crop not in State.CROP_DATA.LEGACY: legacy[category].erase(crop)
	for category in ["goods","meals"]:
		var order: Array = State.PROCESSING.LEGACY if category=="goods" else State.COOKING.LEGACY
		for item in legacy[category].keys():
			if item not in order: legacy[category].erase(item)
	check(s._valid_data(legacy),"0.14 save accepted without spring fields")
	var loaded := State.new()
	loaded._apply_data(legacy)
	check(loaded.seeds["tea"]==0 and loaded.produce["carrot"]==0 and loaded.goods["spring_tea"]==0 and loaded.meals["garden_stew"]==0,"new inventories default zero in legacy save")
	check(loaded.money==120 and loaded.seeds["turnip"]==8,"legacy economy preserved")
	s.area_id="town"
	s.SPRING.talk(s,"shop")
	s.SPRING.talk(s,"shop")
	check(s.spring_progress["friends"]["shop"]==1,"one merchant friendship per day")
	s.sleep()
	s.area_id="town"
	s.SPRING.talk(s,"shop")
	check(s.spring_progress["friends"]["shop"]==2,"resident friendship advances on next day")
	var before := s.to_data()
	check(not s.SPRING.finish_event(s,"shop")["ok"] and s.to_data()==before,"event requirements are atomic")
	s.day=14
	s.produce["turnip"]=2
	s.produce["wheat"]=1
	s.produce["berry"]=1
	s.area_id="farm"
	before=s.to_data()
	check(not s.SPRING.donate(s,"turnip")["ok"] and s.to_data()==before,"festival donation requires town")
	s.area_id="town"
	s.day=13
	before=s.to_data()
	check(not s.SPRING.donate(s,"turnip")["ok"] and s.to_data()==before,"festival cannot start early")
	s.day=14
	check(s.SPRING.donate(s,"turnip")["ok"] and s.produce["turnip"]==1,"donation consumes one crop")
	before=s.to_data()
	check(not s.SPRING.donate(s,"turnip")["ok"] and s.to_data()==before,"duplicate crop donation rejected without cost")
	check(s.SPRING.donate(s,"wheat")["ok"] and s.SPRING.donate(s,"berry")["ok"] and s.SPRING.can_celebrate(s),"three distinct crops unlock spring feast")
	check(s.save_game(SAVE)==OK and loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"partial festival preparation survives restart")
	var cash := s.money
	check(s.SPRING.celebrate(s)["ok"] and s.money==cash+120,"festival completion grants one reward")
	before=s.to_data()
	check(not s.SPRING.celebrate(s)["ok"] and not s.SPRING.donate(s,"tea")["ok"] and s.to_data()==before,"festival reward and offerings cannot repeat same year")
	check(not s.SPRING.finish_chapter(s)["ok"],"festival alone cannot finish chapter")
	s.day=28
	s.sleep()
	check(s.SPRING.season_day(s.day)==1 and s.SPRING.year(s.day)==2 and s.spring_progress["spring_complete"],"28 days advance to next spring and retain summary")
	check(s.spring_progress["festival_year"]==1 and not s.SPRING.can_celebrate(s),"next year does not replay old feast")
	for field in ["friends","talk_days","events","offerings"]:
		var data := s.to_data()
		data["spring_progress"][field]=null
		check(not s._valid_data(data),"malformed spring nested data rejected")
	for bad in [-1,0.5,true,"1",INF,NAN]:
		var data := s.to_data()
		data["spring_progress"]["friends"]["shop"]=bad
		check(not s._valid_data(data),"invalid friendship rejected")
	for bad in [["turnip","turnip"],["unknown"],[1],["turnip","wheat","berry","tea"]]:
		var data := s.to_data()
		data["spring_progress"]["offerings"]=bad
		check(not s._valid_data(data),"invalid festival offerings rejected")
	var data := s.to_data()
	data["spring_progress"]["chapter_done"]=true
	check(not s._valid_data(data),"chapter flag without milestones rejected")
	data=s.to_data()
	data["spring_progress"]["festival_year"]=99
	check(not s._valid_data(data),"future festival reward rejected")
	data=s.to_data()
	data["spring_progress"]["events"]["smith"]=true
	check(not s._valid_data(data),"unearned resident event flag rejected")
	var world := Area.new()
	world.area_id="town"
	world.state=State.new()
	for minute in range(420,1321,5):
		world.state.minute=minute
		var valid := true
		for id in State.RESIDENTS.ORDER:
			valid=valid and not world.blocked(world.resident_position(id)) and not world.blocked(world.resident_anchor(id))
		check(valid,"all resident schedule positions and approach points avoid obstacles")
	world.state.day=4
	for id in State.RESIDENTS.ORDER:
		check(world.resident_position(id)==State.RESIDENTS.HOMES[id],"rain keeps residents under shelter")
	world.free()
	_month()
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("SPRING TESTS: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)

func _month() -> void:
	# Earn all progress from the normal starter state. No money, materials,
	# crops, friendship, story flags or time skips are injected.
	var s := State.new()
	var planted := false
	var cooked := false
	for day in range(1,29):
		check(s.day==day and s.energy==100,"each spring morning restores stamina")
		s.area_id="farm"
		if s.processing_ready(): check(s.collect_processing()["ok"],"collect real overnight processing")
		if s.nest_eggs>0: check(s.collect_eggs()["ok"],"collect eggs earned by feeding")
		for i in range(s.plots.size()):
			if s.is_mature(s.plots[i]): check(s.work(i,"harvest")["ok"],"harvest naturally grown crop")
		var beds := [3,4,5,6,9,10,11,12]
		for n in range(8):
			var index: int = beds[n]
			var crop: String = State.CROP_ORDER[n]
			if s.plots[index]["crop"]=="" and s.seeds[crop]>0:
				if not s.plots[index]["tilled"]: s.work(index,"hoe")
				check(s.work(index,"seed",crop)["ok"],"replant from owned seeds")
		for i in range(s.plots.size()):
			if s.plots[i]["crop"]!="" and not s.plots[i]["watered"]: check(s.work(i,"water")["ok"],"care for spring crops within energy budget")
		s.area_id="forest"
		for node in State.FORAGE.NODES: check(s.gather(node)["ok"],"daily gathering uses actual stamina")
		s.area_id="farm"
		if not s.fence_repaired: check(s.repair_fence()["ok"],"repair fence from gathered materials")
		if day==2: check(s.build_dryer()["ok"],"build dryer using earned resources")
		s.area_id="town"
		s.talk()
		for id in ["shop","smith"]: s.SPRING.talk(s,id)
		if s.tea_event_available(): check(s.finish_tea_event()["ok"],"earn Qinghe tea event")
		if s.active_request=="" and s.request_completed_day!=s.day:
			var request: String = s.daily_request_id()
			if request!="caravan_treats" or s.goods["dried_berry"]>0: s.accept_request()
		if s.active_request!="":
			var id: String = State.REQUESTS.REQUESTS[s.active_request]["recipient"]
			if s.can_deliver_request(id): check(s.deliver_request(id)["ok"],"complete resident request with earned items")
		s.area_id="forest"
		if s.can_restore_route(): check(s.restore_route()["ok"],"restore route through commissions and resources")
		if s.route_restored and not s.relic_recovered:
			s.area_id="ruins"
			check(s.recover_relic()["ok"],"discover relic through unlocked road")
		s.area_id="town"
		for id in ["shop","smith"]:
			if s.SPRING.event_available(s,id): check(s.SPRING.finish_event(s,id)["ok"],"earn resident personal event")
		if day==14:
			for crop in State.CROP_ORDER:
				if s.produce[crop]>0 and s.spring_progress["offerings"].size()<3:
					check(s.SPRING.donate(s,crop)["ok"],"prepare feast with three available homegrown crops")
			check(s.SPRING.celebrate(s)["ok"],"complete actual spring feast")
			check(s.SPRING.finish_chapter(s)["ok"],"complete chapter from six earned milestones")
		s.area_id="farm"
		if s.route_restored and not s.coop_built and s.money>=180:
			check(s.build_coop()["ok"] and s.buy_chicken()["ok"],"add hen without overspending")
		if s.can_feed_chickens(): check(s.feed_chickens()["ok"],"feed hen with grown wheat")
		if s.rack_built and s.processing_job.is_empty():
			for recipe in State.PROCESSING.ORDER:
				if s.produce.get(State.PROCESSING.RECIPES[recipe]["crop"],0)>1:
					check(s.start_processing(recipe)["ok"],"process surplus and retain crop reserve")
					break
		if not cooked and s.produce["carrot"]>0 and s.produce["cabbage"]>0 and s.produce["potato"]>0:
			s.area_id="house"
			check(s.cook("garden_stew")["ok"] and s.eat_meal("garden_stew")["ok"],"cook and eat actual new harvest")
			cooked=true
		if day>=14:
			s.area_id="farm"
			s.sell_all()
		check(s.money>=0 and s.energy>=0 and s.energy<=100 and s._valid_data(s.to_data()),"daily economy and persistent state remain valid")
		check(s.save_game(SAVE)==OK,"daily spring checkpoint saved")
		var loaded := State.new()
		check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"daily spring checkpoint survives restart")
		s.sleep()
	check(s.day==29 and s.spring_progress["spring_complete"] and s.spring_progress["chapter_done"] and cooked,"entire 28-day spring and chapter completed from starter state")
	check(s.total_earned>500 and s.chickens==1 and s.spring_progress["festival_year"]==1,"spring economy supports farming livestock and celebrations")
