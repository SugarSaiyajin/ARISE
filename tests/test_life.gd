extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/life_rules.gd")
const Data = preload("res://scripts/life_data.gd")
const Ranch = preload("res://scripts/ranch_data.gd")
const SAVE := "user://life_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)

func _initialize() -> void:
	var s := State.new()
	var legacy := s.to_data()
	legacy.erase("life")
	legacy["ranch"]["feed"]=5
	check(s._valid_data(legacy),"0.21 save accepted without community progress")
	s._apply_data(legacy)
	check(s.ranch["feed"]==5 and s.life==Rules.empty(),"migration preserves old ranch without granting items")
	check(Ranch.HOME_COST[0]==s.LIVESTOCK.BUILD_COST,"both coop entry points charge the same construction cost")
	for id in Data.ORDER:
		s=State.new()
		var recipe: Dictionary = Data.RECIPES[id]
		s.area_id=recipe["area"]
		var before := s.to_data()
		check(not Rules.craft(s,id)["ok"] and s.to_data()==before,"missing ingredients never partially pay")
		for source in recipe["needs"]:
			if source[0]=="ranch": s.ranch["stock"][source[1]]=source[2]
			else: s.get(source[0])[source[1]]=source[2]
		check(Rules.craft(s,id)["ok"],"each recipe accepts exact inputs at its workshop")
		for source in recipe["needs"]: check(Rules.count(s,source)==0,"crafting consumes exact amounts")
		check(s._valid_data(s.to_data()),"accepted craft remains saveable")
		if id in ["grain_feed","herb_feed"]:
			check(s.ranch["feed"]==recipe["output"] and s.life["job"].is_empty(),"feed immediately stored without a phantom job")
		else:
			check(s.save_game(SAVE)==OK,"paid work order checkpoint saved")
			var loaded := State.new()
			check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"pending recipe and materials survive restart")
			s=loaded
			check(not Rules.collect(s)["ok"],"work cannot finish before a sleep day")
			s.sleep()
			check(not Rules.collect(s)["ok"],"cannot collect at home instead of correct workshop")
			s.area_id=recipe["area"]
			check(Rules.collect(s)["ok"],"mature work collected at correct workshop")
			before=s.to_data()
			check(not Rules.collect(s)["ok"] and s.to_data()==before,"completed work never rewards twice")
			if id=="irrigator":
				check(s.life["irrigator"],"irrigation equipment installed once")
				for source in recipe["needs"]:
					if source[0]=="ranch": s.ranch["stock"][source[1]]=source[2]
					else: s.get(source[0])[source[1]]=source[2]
				before=s.to_data()
				check(not Rules.craft(s,id)["ok"] and s.to_data()==before,"installed equipment cannot consume a duplicate recipe")
				s.plots[0]["crop"]="wheat"
				s.plots[0]["growth"]=0
				s.plots[0]["watered"]=false
				s.plots[1]["watered"]=false
				var growth: int = s.plots[7]["growth"]
				s.sleep()
				check(s.plots[0]["growth"]==1 and s.plots[7]["growth"]==growth,"irrigator waters only first two plots without moving player or planting")
			else:
				var money: int = s.money
				check(s.sell_all()["ok"] and s.money==money+Data.PRODUCTS[id]["price"],"new crafted item ships at its listed value")
			check(s._valid_data(s.to_data()),"finished job and shipping remain valid")
	s=State.new()
	s.produce["wheat"]=1
	s.ranch["feed"]=100000000
	var before := s.to_data()
	check(not Rules.craft(s,"grain_feed")["ok"] and s.to_data()==before,"full feed store never loses wheat")
	for recipe_id in ["honey_cake","duck_pudding","star_tea"]:
		s=State.new()
		s.area_id="house"
		for item in State.COOKING.RECIPES[recipe_id]["ingredients"]:
			if item["stock"]=="ranch": s.ranch["stock"][item["item"]]=item["amount"]
			else: s.get(item["stock"])[item["item"]]=item["amount"]
		check(s.cook(recipe_id)["ok"] and s.meals[recipe_id]==1,"ranch produce cooks into new meals")
		before=s.to_data()
		check(not s.cook(recipe_id)["ok"] and s.to_data()==before,"meal cannot duplicate without raw ingredients")
		s.energy=5
		check(s.eat_meal(recipe_id)["ok"] and s.energy==5+State.COOKING.RECIPES[recipe_id]["energy"],"ranch meals restore their stated energy")
	for id in Ranch.VISITORS:
		s=State.new()
		for day in range(3):
			s.area_id=Ranch.AREAS[Ranch.RESIDENTS[id]["home"]]
			check(s.RANCH.talk(s,id)["ok"],"daily conversation builds the earned relationship")
			if day<2: s.sleep()
		check(Rules.event_available(s,id),"three earned conversations unlock the personal story")
		var money: int = s.money
		check(Rules.finish_event(s,id)["ok"] and s.money==money+50,"personal finale grants its reward once")
		before=s.to_data()
		check(not Rules.finish_event(s,id)["ok"] and s.to_data()==before,"replay cannot claim a second reward")
		var item: String = Data.REQUESTS[id]["item"]
		s.ranch["stock"][item]=2
		money=s.money
		check(Rules.deliver(s,id)["ok"] and s.money==money+Data.REQUESTS[id]["reward"] and s.ranch["stock"][item]==1,"commission exchanges one exact product for reward")
		before=s.to_data()
		check(not Rules.deliver(s,id)["ok"] and s.to_data()==before,"daily commission cannot be repeated")
		check(s.save_game(SAVE)==OK,"story and commission progress saved")
		var loaded := State.new()
		check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"story and daily limits survive restart")
	for id in Ranch.VISITORS:
		check(Ranch.visitor_area(id,600,false).begins_with("ranch_"),"morning routine remains at ranch")
		check(Ranch.visitor_area(id,720,false)==Ranch.CULTURES[id],"daytime routine goes to cultural home")
		check(Ranch.visitor_area(id,720,true).begins_with("ranch_"),"rain keeps residents at ranch")
		check(Ranch.visitor_area(id,1200,false).begins_with("ranch_"),"evening returns residents to ranch")
	s=State.new()
	for area in Data.AREAS:
		s.area_id=area
		check(Rules.gather(s)["ok"],"each culture area offers one daily resource")
		before=s.to_data()
		check(not Rules.gather(s)["ok"] and s.to_data()==before,"reentering map does not reset daily gathering")
		check(s._valid_data(s.to_data()),"culture locations are valid save destinations")
	s=State.new()
	s.money=1000
	s.materials={"wood":30,"stone":30,"herb":0}
	s.RANCH.build(s,1)
	s.area_id="ranch_meadow"
	s.RANCH.buy(s,"rabbit")
	s.ranch["animals"]["rabbit"]["bond"]=20
	s.day=4
	check(s.RANCH.feed(s,"rabbit")["ok"] and s.ranch["feed"]==0,"bond benefit supplies feed without demanding an unavailable unit")
	before=s.to_data()
	check(not s.RANCH.feed(s,"rabbit")["ok"] and s.to_data()==before,"bond benefit still applies only once per day")
	for key in ["stock","job","events","requests","gathered","irrigator"]:
		var data := s.to_data()
		data["life"][key]=null
		check(not s._valid_data(data),"malformed community progress rejected safely")
	var data := s.to_data()
	data["life"]["events"]["edric"]=true
	check(not s._valid_data(data),"unearned story flag rejected")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("LIFE TESTS: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
