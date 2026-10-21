extends SceneTree
const State = preload("res://scripts/farm_state.gd")
const Rules = preload("res://scripts/estate_rules.gd")
var passed := 0
var failed := 0
const SAVE := "user://estate_test.json"
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	var s := State.new()
	var old := s.to_data()
	old.erase("estate")
	check(s._valid_data(old),"0.24 save accepted without estate fields")
	s._apply_data(old)
	check(s.estate==Rules.empty(),"migration grants no unearned care, builds or milestones")
	s.produce["turnip"]=5
	s.journey["reserve"]=true
	var before := s.to_data()
	var plan := Rules.shipping_plan(s)
	check(s.to_data()==before and plan["earnings"]==54 and plan["lines"][0]["amount"]==3,"shipping preview is non-mutating and respects reserves")
	check(Rules.ship(s,plan["guard"])["ok"] and s.produce["turnip"]==2 and s.money==174,"confirmed shipment matches quoted quantity and income")
	before=s.to_data()
	check(not Rules.ship(s,plan["guard"])["ok"] and s.to_data()==before,"duplicate quote cannot charge or pay twice")
	s.produce["turnip"]=6
	plan=Rules.shipping_plan(s)
	s.produce["turnip"]+=1
	before=s.to_data()
	check(not Rules.ship(s,plan["guard"])["ok"] and s.to_data()==before,"stale inventory quote is rejected intact")
	s=State.new()
	s.coop_built=true
	s.chickens=2
	s.produce["wheat"]=2
	plan=Rules.ranch_plan(s,"feed")
	check(plan["ok"] and plan["wheat"]==2 and s.fed_chickens==0,"farm chicken feed preview does not feed early")
	check(Rules.ranch_apply(s,"feed",plan["guard"])["ok"] and s.fed_chickens==2 and s.produce["wheat"]==0,"farm chicken batch consumes exact wheat")
	s=State.new()
	s.ranch["homes"][1]=true
	s.area_id="ranch_meadow"
	for id in ["rabbit","sheep"]: s.ranch["animals"][id]["owned"]=true
	s.ranch["feed"]=1
	before=s.to_data()
	check(not Rules.ranch_plan(s,"feed")["ok"] and s.to_data()==before,"insufficient feed never partially pays or feeds")
	s.ranch["feed"]=2
	plan=Rules.ranch_plan(s,"feed")
	check(plan["ok"] and plan["feed"]==2,"batch preflights both animals")
	check(Rules.ranch_apply(s,"feed",plan["guard"])["ok"] and s.ranch["feed"]==0 and s.ranch["animals"]["rabbit"]["fed"] and s.ranch["animals"]["sheep"]["fed"],"confirmed batch feeds exactly two")
	before=s.to_data()
	check(not Rules.ranch_plan(s,"feed")["ok"] and s.to_data()==before,"already fed animals are skipped")
	s.energy=1
	before=s.to_data()
	check(not Rules.ranch_plan(s,"care")["ok"] and s.to_data()==before,"not enough stamina preserves entire care batch")
	s.estate["fixtures"][0]=2
	s.energy=0
	plan=Rules.ranch_plan(s,"care")
	check(plan["ok"] and plan["energy"]==0,"care bench changes actual quoted stamina requirement")
	check(Rules.ranch_apply(s,"care",plan["guard"])["ok"] and s.estate["care_total"]==2 and s.energy==0,"care bench applies once per eligible animal")
	check(s.save_game(SAVE)==OK,"estate checkpoint saves")
	var loaded := State.new()
	check(loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"care flags and counters survive restart")
	for site in range(3):
		for kind in range(1,4):
			s=State.new()
			s.life["irrigator"]=true
			s.money=500
			s.materials={"wood":30,"stone":30,"herb":0}
			var cash := s.money
			check(Rules.build(s,site,kind)["ok"] and s.money==cash-Rules.COSTS[kind]["money"],"each facility can be built in each defined legal site")
			before=s.to_data()
			check(not Rules.build(s,site,kind)["ok"] and s.to_data()==before,"occupied site cannot charge twice")
			check(not Rules.build(s,(site+1)%3,kind)["ok"] and s.to_data()==before,"duplicate facility cannot multiply its perk")
			check(s._valid_data(s.to_data()),"all facility placement states validate")
			check(Rules.build(s,site,0)["ok"] and s.money==cash-Rules.COSTS[kind]["money"],"demolishing removes facility without refund exploit")
	s=State.new()
	s.money=500
	s.materials={"wood":30,"stone":30,"herb":0}
	check(not Rules.build(s,0,1)["ok"],"irrigation expansion requires installed base device")
	s.journey["decor"][0]=1
	before=s.to_data()
	check(not Rules.build(s,0,2)["ok"] and s.to_data()==before,"occupied decorative slot blocks construction intact")
	s.journey["decor"][0]=0
	check(Rules.build(s,0,2)["ok"],"removing conflicting decor allows construction")
	before=s.to_data()
	check(not s.JOURNEY.decorate(s,0,1)["ok"] and s.to_data()==before,"new decor cannot overlap built facility")
	s=State.new()
	s.life["irrigator"]=true
	s.estate["fixtures"][0]=1
	for i in range(8): s.plots[i]={"tilled":true,"crop":"wheat","growth":0,"watered":false}
	s.sleep()
	for i in range(8): check(s.plots[i]["growth"]==(1 if i<6 else 0),"water divider affects exactly first six planted plots")
	s=State.new()
	s.estate["fixtures"][0]=3
	s.produce["turnip"]=6
	plan=Rules.shipping_plan(s)
	check(plan["earnings"]==113,"storage bonus is included once and rounded down")
	check(Rules.ship(s,plan["guard"])["ok"] and s.money==233,"actual storage shipment matches preview")
	for id in s.JOURNEY.PEOPLE:
		s=State.new()
		if id=="npc": s.friendship=3
		elif id in ["shop","smith"]: s.spring_progress["friends"][id]=3
		else: s.ranch["friends"][id]=3
		s.area_id="town" if id in ["npc","shop","smith"] else s.RANCH_DATA.visitor_area(id,s.minute,s.is_raining())
		s.player_position=s.RESIDENTS.position(id,s.minute,s.is_raining()) if s.area_id=="town" else s.RANCH_DATA.visitor_position(id,s.area_id,s.minute,s.is_raining())
		var time := s.minute
		var energy := s.energy
		var points := s.JOURNEY.friendship(s,id)
		check(Rules.activity(s,id,2)["ok"] and s.minute==time+30 and s.energy==energy-6 and s.JOURNEY.friendship(s,id)==points+2,"all nine shared activities commit exact time stamina and relationship")
		before=s.to_data()
		check(not Rules.activity(s,id,1)["ok"] and s.to_data()==before,"one weekly activity prevents choice/reward duplication")
		s.day=3
		check(Rules.daily_line(s,id).contains(Rules.ACTIVITY_LINES[s.JOURNEY.PEOPLE.find(id)][1]),"activity choice is reflected in later daily dialogue")
		s.day=8
		check(Rules.activity(s,id,1)["ok"],"new calendar week reopens shared activity")
		check(s._valid_data(s.to_data()),"weekly activities validate for every resident")
	s=State.new()
	s.friendship=3
	s.area_id="town"
	s.player_position=s.RESIDENTS.position("npc",s.minute,false)
	s.minute=1290
	before=s.to_data()
	check(not Rules.activity(s,"npc",1)["ok"] and s.to_data()==before,"late activity cannot push clock beyond day boundary")
	s=State.new()
	s.day=29
	for index in range(4):
		s.area_id=s.LIFE_DATA.AREAS[index]
		var key: String=Rules.SUMMER_NEEDS[index]
		var parts := key.split(":")
		s.get(parts[0])[parts[1]]=Rules.SUMMER_AMOUNTS[index]*2
		var cash := s.money
		check(Rules.summer_job(s,index)["ok"] and s.money==cash+Rules.SUMMER_REWARDS[index],"each summer collaboration consumes its actual materials and pays its reward")
		before=s.to_data()
		check(not Rules.summer_job(s,index)["ok"] and s.to_data()==before,"summer weekly cap survives repeated clicks")
	check(s.estate["summer_completed"]==4 and s._valid_data(s.to_data()),"all summer collaborations count toward long-term goal")
	check(s.save_game(SAVE)==OK and loaded.load_game(SAVE) and loaded.to_data()==s.to_data(),"summer weekly limits survive restart")
	s.day=57
	before=s.to_data()
	check(not Rules.summer_job(s,3)["ok"] and s.to_data()==before,"spring does not offer summer collaboration rewards")
	s=State.new()
	before=s.to_data()
	check(not Rules.claim_goal(s,0)["ok"] and s.to_data()==before,"unearned milestones cannot be claimed")
	s.harvested=12
	var money := s.money
	check(Rules.claim_goal(s,0)["ok"] and s.money==money+100,"earned milestone rewards exactly once")
	before=s.to_data()
	check(not Rules.claim_goal(s,0)["ok"] and s.to_data()==before,"milestone replay cannot pay twice")
	var finish := State.new()
	finish.day=42
	finish.harvested=12
	finish.coop_built=true
	finish.ranch["homes"]=[true,true,true,true]
	for id in ["duck","rabbit","bee"]: finish.ranch["animals"][id]["owned"]=true
	finish.estate["care_total"]=12
	finish.estate["craft_total"]=5
	finish.estate["summer_completed"]=4
	for area in finish.LIFE_DATA.AREAS: finish.estate["summer_jobs"][area]=29
	finish.requests_completed=3
	finish.request_completed_day=3
	finish.friendship=3
	finish.spring_progress["friends"]={"shop":3,"smith":3}
	finish.journey["quests"]=[true,true,true,true]
	finish.journey["clues"]=[7,7,7,7]
	finish.journey["summer_cycle"]=1
	finish.journey["summer_offered"]=["turnip","wheat","berry"]
	finish.journey["summer_done"]=1
	for index in range(6):
		check(Rules.goal_ready(finish,index) and Rules.claim_goal(finish,index)["ok"],"all six independent late-game goals can be earned and claimed")
	check(finish.money==1320 and finish._valid_data(finish.to_data()),"all goal rewards conserve currency and remain saveable")
	check(finish.save_game(SAVE)==OK and loaded.load_game(SAVE),"claimed milestones checkpoint and load")
	before=loaded.to_data()
	for index in range(6): check(not Rules.claim_goal(loaded,index)["ok"] and loaded.to_data()==before,"milestones remain non-repeatable after restart")
	for id in s.JOURNEY.PEOPLE:
		var dialogue_state := State.new()
		dialogue_state.day=2
		var previous_line := ""
		for points in [0,3,10,25]:
			if id=="npc": dialogue_state.friendship=points
			elif id in ["shop","smith"]: dialogue_state.spring_progress["friends"][id]=points
			else: dialogue_state.ranch["friends"][id]=points
			var snapshot := dialogue_state.to_data()
			var line := Rules.daily_line(dialogue_state,id)
			check(line!=previous_line and dialogue_state.to_data()==snapshot,"relationship stages change each resident's words without awarding resources")
			previous_line=line
	for key in Rules.empty():
		var data := s.to_data()
		data["estate"][key]=null
		check(not s._valid_data(data),"malformed estate state rejected without mutation")
	for bad in [-1,0.5,true,"1",INF,NAN,4]:
		var data := s.to_data()
		data["estate"]["fixtures"][0]=bad
		check(not s._valid_data(data),"invalid facility data rejected")
	var malformed := s.to_data()
	malformed["estate"]["milestones"][3]=true
	check(not s._valid_data(malformed),"unearned craft milestone flag rejected")
	print("ESTATE TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
