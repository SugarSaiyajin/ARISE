extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/ranch_rules.gd")
const Data = preload("res://scripts/ranch_data.gd")
const SAVE := "user://ranch_test_only.json"
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: ",message)

func _initialize() -> void:
	var s := State.new()
	var legacy := s.to_data()
	legacy.erase("ranch")
	legacy.erase("hero_style")
	legacy["coop_built"] = true
	legacy["chickens"] = 2
	legacy["fed_chickens"] = 1
	legacy["nest_eggs"] = 4
	legacy["eggs"] = 5
	check(s._valid_data(legacy),"0.14 save without new fields accepted")
	s._apply_data(legacy)
	check(s.chickens==2 and s.eggs==5 and Rules.home_open(s,0),"existing hens and eggs preserved and home accessible")
	s.sleep()
	check(s.nest_eggs==5 and s.fed_chickens==0,"old fed hens produce exactly once")
	s = State.new()
	var before := s.to_data()
	check(not Rules.buy(s,"unknown")["ok"] and not Rules.feed(s,"unknown")["ok"],"unknown species rejected")
	check(not Rules.build(s,-1)["ok"] and not Rules.build(s,4)["ok"],"invalid homes rejected")
	check(s.to_data()==before,"rejected unknown operations do not mutate state")
	check(not Rules.build(s,0)["ok"] and s.to_data()==before,"missing materials cannot partially pay")
	s.money = 6000
	s.materials = {"wood":40,"stone":30,"herb":10}
	for home in range(4):
		s.area_id = "farm"
		check(Rules.build(s,home)["ok"],"build each approved habitat")
		var built := s.to_data()
		check(not Rules.build(s,home)["ok"] and built==s.to_data(),"building twice cannot charge again")
		check(s._valid_data(s.to_data()),"home construction remains saveable")
	for n in range(6): check(Rules.buy_feed(s)["ok"],"buy feed with actual currency")
	for id in Data.ORDER:
		s.area_id = Data.AREAS[Data.SPECIES[id]["home"]]
		check(Rules.buy(s,id)["ok"],"adopt each approved species")
		if id != "hen":
			var adopted := s.to_data()
			check(not Rules.buy(s,id)["ok"] and adopted==s.to_data(),"one named animal or group per extra species")
		check(Rules.rename(s,id,"小"+Data.SPECIES[id]["name"])["ok"],"name each animal or flock")
		check(not Rules.rename(s,id,"\n")["ok"] and not Rules.rename(s,id,"1234567890123")["ok"],"invalid names cannot corrupt save")
	check(s._valid_data(s.to_data()),"all owned young animals and names valid")
	var immature := s.to_data()
	check(not Rules.collect(s,"carp")["ok"] and s.to_data()==immature,"young fish cannot grant products")
	for day in range(12):
		for id in Data.EXTRA:
			s.area_id = Data.AREAS[Data.SPECIES[id]["home"]]
			if s.ranch["feed"]==0: Rules.buy_feed(s)
			check(Rules.feed(s,id)["ok"],"daily feed paid once")
			var fed := s.to_data()
			check(not Rules.feed(s,id)["ok"] and s.to_data()==fed,"repeated feed has no extra costs")
			check(Rules.care(s,id)["ok"],"species-appropriate care increases bond")
			var cared := s.to_data()
			check(not Rules.care(s,id)["ok"] and s.to_data()==cared,"daily care cannot farm friendship")
		if day==0:
			check(s.save_game(SAVE)==OK,"fed young state checkpoint saved")
			var loaded := State.new()
			check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"restart preserves feed flags and names")
			s = loaded
		s.sleep()
		check(s._valid_data(s.to_data()),"every overnight transition stays valid")
	for id in Data.EXTRA:
		s.area_id = Data.AREAS[Data.SPECIES[id]["home"]]
		var a: Dictionary = s.ranch["animals"][id]
		check(a["age"]==Data.SPECIES[id]["days"] and a["bond"]==12,"young animals mature and bond over real fed days")
		check(a["ready"]>0,"every species produces including slow natural antler cycle")
		var amount: int = a["ready"]
		check(Rules.collect(s,id)["ok"] and s.ranch["stock"][id]==amount,"collect moves only completed yield")
		var collected := s.to_data()
		check(not Rules.collect(s,id)["ok"] and s.to_data()==collected,"duplicate collection has no reward")
	check(s.ranch["stock"]["deer"]==1,"antlers take seven mature fed days rather than daily reward")
	var expected := 0
	for id in Data.EXTRA: expected += s.ranch["stock"][id]*Data.SPECIES[id]["sell"]
	s.area_id = "farm"
	var cash := s.money
	check(s.sell_all()["ok"] and s.money==cash+expected,"all seven new products ship for exact value")
	check(s.ranch["stock"].values().all(func(n): return n==0),"shipping clears only collected new products")
	for id in Data.EXTRA:
		var age: int = s.ranch["animals"][id]["age"]
		var cycle: int = s.ranch["animals"][id]["cycle"]
		s.sleep()
		check(s.ranch["animals"][id]["age"]==age and s.ranch["animals"][id]["cycle"]==cycle,"unfed animals pause without free products")
	s.area_id = "ranch_spring"
	s.ranch["animals"]["carp"]["ready"] = 24
	before = s.to_data()
	check(not Rules.feed(s,"carp")["ok"] and s.to_data()==before,"full product box prevents wasted feed")
	s.ranch["stock"]["carp"] = Data.LIMIT
	before = s.to_data()
	check(not Rules.collect(s,"carp")["ok"] and s.to_data()==before,"full inventory keeps ready products")
	for id in Data.VISITORS:
		s.area_id = Data.AREAS[Data.RESIDENTS[id]["home"]]
		check(Rules.talk(s,id)["ok"] and s.ranch["friends"][id]==1,"six new residents can be befriended")
		Rules.talk(s,id)
		check(s.ranch["friends"][id]==1,"same-day conversation never repeats friendship")
	s.hero_style = "female"
	check(s.save_game(SAVE)==OK,"grown animals products visitors and female style saved")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"complete ranch state survives JSON restart")
	for bad in [-1,1.5,INF,"1",true]:
		var data := s.to_data()
		data["ranch"]["feed"] = bad
		check(not s._valid_data(data),"malformed feed count rejected")
	for key in ["owned","age","cycle","fed","cared","ready","name"]:
		var data := s.to_data()
		data["ranch"]["animals"]["duck"][key] = null
		check(not s._valid_data(data),"malformed animal fields rejected")
	var data := s.to_data()
	data["ranch"]["animals"]["dragon"] = {}
	check(not s._valid_data(data),"unknown animal blocks corrupt save")
	data = s.to_data()
	data["ranch"]["talked"]["edric"] = s.day+1
	check(not s._valid_data(data),"future conversation cannot suppress legitimate daily interaction")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("RANCH TESTS: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
