extends SceneTree
const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/journey_rules.gd")
var passed := 0
var failed := 0
const SAVE := "user://journey_test.json"
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	var s := State.new()
	var legacy := s.to_data()
	legacy.erase("journey")
	check(s._valid_data(legacy),"0.23 and earlier saves accepted without new fields")
	s._apply_data(legacy)
	check(s.journey==Rules.empty(),"migration grants no unearned tutorial actions, gifts or rewards")
	var before := s.to_data()
	check(not s.work(-1,"water")["ok"] and s.to_data()==before,"failed work cannot advance tutorial")
	check(s.work(0,"water")["ok"] and Rules.next_task(s)=="rest","watering commits first real task")
	s.sleep()
	check(Rules.next_task(s)=="harvest","sleep advances only its own task")
	s.area_id="farm"
	check(s.work(0,"harvest")["ok"] and Rules.next_task(s)=="ship","harvest requires real mature plot")
	check(s.sell_all()["ok"] and Rules.next_task(s)=="seed","actual shipping advances task")
	check(s.work(0,"seed")["ok"] and Rules.next_task(s)=="","full playable onboarding completes")
	for id in Rules.PEOPLE:
		s=State.new()
		s.area_id="town" if id in ["npc","shop","smith"] else State.RANCH_DATA.visitor_area(id,s.minute,s.is_raining())
		s.player_position=State.RESIDENTS.position(id,s.minute,s.is_raining()) if s.area_id=="town" else State.RANCH_DATA.visitor_position(id,s.area_id,s.minute,s.is_raining())
		var item: String=Rules.LIKES[id][0]
		var parts := item.split(":")
		s.get(parts[0])[parts[1]]=2
		var points := Rules.friendship(s,id)
		check(Rules.gift(s,id,item)["ok"] and Rules.friendship(s,id)==points+2 and Rules.count(s,item)==1,"all nine residents accept exact liked gift")
		before=s.to_data()
		check(not Rules.gift(s,id,item)["ok"] and s.to_data()==before,"daily gift cannot repeat or consume twice")
		check(s.save_game(SAVE)==OK,"daily gift checkpoint saves")
		var loaded := State.new()
		check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"daily cap and consumed gift survive restart")
		loaded.player_position=Vector2(20,60)
		before=loaded.to_data()
		check(not Rules.gift(loaded,id,item)["ok"] and loaded.to_data()==before,"remote gift cannot bypass physical interaction")
		if id=="npc": s.friendship=25
		elif id in ["shop","smith"]: s.spring_progress["friends"][id]=25
		else: s.ranch["friends"][id]=25
		check(not Rules.finish_event(s,id,2)["ok"],"relationship memories must complete in order")
		var money := s.money
		check(Rules.finish_event(s,id,1)["ok"] and s.money==money+80,"trust memory rewards once")
		before=s.to_data()
		check(not Rules.finish_event(s,id,1)["ok"] and s.to_data()==before,"replayed trust never rewards twice")
		check(Rules.finish_event(s,id,2)["ok"] and s.money==money+230,"close memory rewards once after trust")
		check(s._valid_data(s.to_data()),"relationship state validates for each resident")
	for index in range(4):
		s=State.new()
		s.area_id=State.LIFE_DATA.AREAS[index]
		before=s.to_data()
		check(not Rules.quest(s,index)["ok"] and s.to_data()==before,"cannot skip exploring to claim quest")
		for clue in range(3):
			s.player_position=Rules.CLUES[clue]
			check(Rules.inspect_clue(s,clue)["ok"],"every culture clue can be inspected at its location")
			var bits: int=s.journey["clues"][index]
			Rules.inspect_clue(s,clue)
			check(s.journey["clues"][index]==bits,"re-inspection never alters completed bit or creates rewards")
		s.materials={"wood":3,"stone":3,"herb":2}
		s.fish["silver_carp"]=1
		s.produce["wheat"]=1
		check(Rules.quest(s,index)["ok"] and s.journey["quests"][index],"each distinct culture quest accepts its exact delivery")
		before=s.to_data()
		check(not Rules.quest(s,index)["ok"] and s.to_data()==before,"culture quest never rewards twice")
		check(s._valid_data(s.to_data()),"exploration and reward state validates")
	s=State.new()
	s.materials={"wood":50,"stone":50,"herb":50}
	for slot in range(6):
		for kind in range(1,4): check(Rules.decorate(s,slot,kind)["ok"],"all six slots accept each approved decoration")
		check(Rules.decorate(s,slot,0)["ok"],"decoration can be removed without blocking layout")
	before=s.to_data()
	check(not Rules.decorate(s,-1,2)["ok"] and not Rules.decorate(s,6,2)["ok"] and s.to_data()==before,"invalid slots never consume materials")
	s.money=180
	s.materials={"wood":8,"stone":6,"herb":0}
	check(Rules.upgrade_tool(s)["ok"] and s.money==0 and s.materials["wood"]==0,"tool upgrade consumes exact construction cost")
	var energy := s.energy
	check(s.work(0,"water")["ok"] and s.energy==energy-1,"upgraded watering actually reduces stamina cost")
	before=s.to_data()
	check(not Rules.upgrade_tool(s)["ok"] and s.to_data()==before,"tool upgrade cannot charge twice")
	s=State.new()
	s.journey["reserve"]=true
	s.produce["turnip"]=5
	s.ranch["stock"]["bee"]=4
	s.life["stock"]["honey_tea"]=3
	s.eggs=4
	var expected := 3*18+2*62+195+2*56
	var money := s.money
	check(s.ship_with_reserve()["ok"] and s.money==money+expected,"retained shipping pays only excess items across stocks")
	check(s.produce["turnip"]==2 and s.ranch["stock"]["bee"]==2 and s.life["stock"]["honey_tea"]==2 and s.eggs==2,"reserved materials stay exactly once")
	before=s.to_data()
	check(not s.ship_with_reserve()["ok"] and s.to_data()==before,"shipping only reserve stock cannot generate money")
	s.produce["turnip"]=5
	s.money=1000000000000
	before=s.to_data()
	check(not s.ship_with_reserve()["ok"] and s.to_data()==before,"overflow shipping restores all withheld stock")
	for recipe in State.LIFE_DATA.GOODS:
		s=State.new()
		s.area_id=State.LIFE_DATA.RECIPES[recipe]["area"]
		for ingredient in State.LIFE_DATA.RECIPES[recipe]["needs"]:
			if ingredient[0]=="ranch": s.ranch["stock"][ingredient[1]]=ingredient[2]
			else: s.get(ingredient[0])[ingredient[1]]=ingredient[2]
		s.money=State.LIFE_DATA.FEES[recipe]-1
		before=s.to_data()
		check(not s.LIFE.craft(s,recipe)["ok"] and s.to_data()==before,"insufficient fee cannot consume any workshop inputs")
		s.money+=1
		check(s.LIFE.craft(s,recipe)["ok"] and s.money==0,"workshop consumes exact listed fee")
	for day in range(1,113):
		check(Rules.season(day)==["春","夏","秋"][((day-1)/28)%3],"three-season calendar sequence")
		check(Rules.rain(day)==((day-57)%7==3 if Rules.season(day)=="秋" else day%4==0 if Rules.season(day)=="春" else (day-29)%5 in [1,2]),"calendar forecasts match weather rules")
	s=State.new()
	s.day=28
	s.plots[0]["watered"]=true
	s.sleep()
	check(s.day==29 and Rules.season(s.day)=="夏" and s.is_mature(s.plots[0]),"season transition preserves crop growth and plot identity")
	check(Rules.crop_price(s,"berry")==57 and Rules.crop_price(s,"turnip")==18,"summer premium applies only to favored crops with integer price")
	s.day=30
	s.plots[2]={"tilled":true,"crop":"berry","growth":0,"watered":true}
	s.sleep()
	check(s.plots[2]["growth"]==2,"summer favored crop gains extra growth on third day")
	s.day=42
	s.area_id="town"
	check(not s.SPRING.festival_open(s) and Rules.summer_open(s),"summer never accidentally opens spring festival")
	for crop in ["turnip","wheat","berry"]:
		s.produce[crop]=2
		check(Rules.summer_donate(s,crop)["ok"] and s.produce[crop]==1,"summer feast consumes one of each distinct crop")
		check(not Rules.summer_donate(s,crop)["ok"],"duplicate summer offering rejected")
	check(s.save_game(SAVE)==OK,"partial summer offerings checkpoint saved")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"summer offerings survive restart")
	money=s.money
	check(Rules.summer_finish(s)["ok"] and s.money==money+150,"summer completion grants reward exactly once")
	before=s.to_data()
	check(not Rules.summer_finish(s)["ok"] and s.to_data()==before,"summer replay never rewards twice")
	check(s._valid_data(s.to_data()),"completed summer and migration remain saveable")
	for key in Rules.empty():
		var malformed := s.to_data()
		malformed["journey"][key]=null
		check(not s._valid_data(malformed),"malformed journey nested field rejected")
	for bad in [-1,0.5,true,"1",INF,NAN,8]:
		var malformed := s.to_data()
		malformed["journey"]["clues"][0]=bad
		check(not s._valid_data(malformed),"invalid exploration bits rejected")
	print("JOURNEY TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
