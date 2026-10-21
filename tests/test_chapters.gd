extends SceneTree
const State=preload("res://scripts/farm_state.gd")
var passed := 0
var failed := 0
func check(ok: bool, text: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",text)
func _initialize() -> void: run.call_deferred()
func checkpoint(s: RefCounted) -> bool:
	if s.save_game("user://chapter_test.json")!=OK: return false
	var loaded := State.new()
	return loaded.load_game("user://chapter_test.json") and loaded.to_data()==s.to_data()
func layout(game: Node) -> bool:
	var panel: Panel=game.modal.get_child(1)
	for child in panel.get_children():
		if child is Control and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>panel.size.x+1 or child.position.y+child.size.y>panel.size.y+1): return false
	for child in panel.get_children():
		if child is Label and child.autowrap_mode!=TextServer.AUTOWRAP_OFF:
			var lines: int=child.get_line_count()
			var height: float=lines*child.get_theme_font("font").get_height(child.get_theme_font_size("font_size"))+maxi(0,lines-1)*child.get_theme_constant("line_spacing")
			for button in panel.get_children():
				if button is Button and button.position.y>child.position.y and child.position.y+height>button.position.y+2: return false
	return true
func run() -> void:
	var s := State.new()
	var legacy := s.to_data()
	for key in ["interior","growth","chapter"]: legacy.erase(key)
	check(s._valid_data(legacy),"0.27 save accepted without any new chapter fields")
	s._apply_data(legacy)
	check(s.chapter==s.CHAPTER.empty() and s.growth==s.GROWTH.empty() and s.interior==s.INTERIOR.defaults() and s.money==120,"legacy migration grants no stories, orders, bonds or money")
	for id in s.CHAPTER.PEOPLE:
		for choice in [1,2]:
			s=State.new()
			s.area_id="town" if id in ["npc","shop","smith"] else s.RANCH_DATA.visitor_area(id,s.minute,s.is_raining())
			s.player_position=s.RESIDENTS.position(id,s.minute,false) if id in ["npc","shop","smith"] else s.RANCH_DATA.visitor_position(id,s.area_id,s.minute,false)
			if id=="npc": s.friendship=5
			elif id in ["shop","smith"]: s.spring_progress["friends"][id]=5
			else: s.ranch["friends"][id]=5
			var energy := s.energy
			var minute := s.minute
			check(s.CHAPTER.story(s,id,choice)["ok"] and s.energy==energy-3 and s.minute==minute+20 and s.JOURNEY.friendship(s,id)==7,"each resident story applies exactly once after an explicit choice")
			var expected: String=s.CHAPTER.DATA.STORIES[s.CHAPTER.PEOPLE.find(id)][choice+3]
			check(expected in s.ESTATE.daily_line(s,id),"each of18 outcomes is remembered in actual daily dialogue")
			var before := s.to_data()
			check(not s.CHAPTER.story(s,id,choice)["ok"] and s.to_data()==before,"repeated story cannot consume time or reward friendship")
			check(checkpoint(s),"each personal choice survives save and restart")
	s.estate["choices"]["qinglin"]=1
	s.day=3
	check(s.ESTATE.ACTIVITY_LINES[8][0] in s.ESTATE.daily_line(s,"qinglin"),"new personal stories retain existing shared-activity memories")
	s=State.new()
	s.friendship=5
	var before := s.to_data()
	check(not s.CHAPTER.story(s,"npc",1)["ok"] and s.to_data()==before,"story cannot be completed remotely")
	for index in range(4):
		s=State.new()
		s.area_id=s.CHAPTER.DATA.AREAS[index]
		s.player_position=s.JOURNEY.CLUES[0]
		check(s.CHAPTER.journey(s,index)["ok"] and s.chapter["journeys"][index]==1,"each region begins with physical observation")
		s.player_position=Vector2(180,169)
		before=s.to_data()
		check(not s.CHAPTER.journey(s,index)["ok"] and s.to_data()==before,"missing chapter materials do not partially advance")
		var data: Array=s.CHAPTER.DATA.JOURNEYS[index]
		for stage in [1,2]:
			var need: Array=data[stage+3]
			s.CHAPTER.stock(s,need[0])[need[1]]=need[2]
			check(s.CHAPTER.journey(s,index)["ok"] and s.CHAPTER.count(s,need)==0,"chapter delivery consumes exact raw or crafted goods")
			check(checkpoint(s),"each regional chapter step persists")
		check(s.money==120+data[6] and s.chapter["journeys"][index]==3,"regional completion pays the documented one-time reward")
		before=s.to_data()
		check(not s.CHAPTER.journey(s,index)["ok"] and s.to_data()==before,"regional reward cannot replay")
	s=State.new()
	s.player_position=Vector2(123,139)
	for week_day in [1,8,29]:
		s.day=week_day
		for index in range(3):
			var data := s.CHAPTER.order(s,index)
			for need in data["needs"]: s.CHAPTER.stock(s,need[0])[need[1]]=need[2]
			var guard := s.CHAPTER.fingerprint(s)
			var cash := s.money
			check(s.CHAPTER.deliver_order(s,index,guard)["ok"] and s.money==cash+data["reward"],"spring, summer and alternating processing orders pay exact preview income")
			before=s.to_data()
			check(not s.CHAPTER.deliver_order(s,index,guard)["ok"] and s.to_data()==before,"stale weekly confirmation cannot pay twice")
			check(not s.CHAPTER.deliver_order(s,index,s.CHAPTER.fingerprint(s))["ok"] and s.to_data()==before,"fresh quote still respects completed order bits")
		check(checkpoint(s),"weekly completion flags and lifetime counter survive restart")
	check(s.chapter["orders_done"]==9,"week changes refresh eligibility without resetting long-term progress")
	check(s.CHAPTER.claim_goal(s,2)["ok"],"six-order long-term goal can be claimed")
	before=s.to_data()
	check(not s.CHAPTER.claim_goal(s,2)["ok"] and s.to_data()==before,"long-term reward cannot repeat")
	s.day=36
	var quote := s.CHAPTER.fingerprint(s)
	s.day=37
	before=s.to_data()
	check(not s.CHAPTER.deliver_order(s,0,quote)["ok"] and s.to_data()==before,"date change invalidates an old delivery preview")
	s=State.new()
	s.money=1000
	s.materials={"wood":20,"stone":20,"herb":0}
	check(s.RANCH.build(s,1)["ok"],"growth campaign builds its actual habitat")
	s.area_id="ranch_meadow"
	check(s.RANCH.buy(s,"rabbit")["ok"],"growth campaign adopts through real rules")
	s.RANCH.buy_feed(s)
	s.RANCH.buy_feed(s)
	var feed_spent := 0
	for day in range(1,15):
		s.area_id="ranch_meadow"
		feed_spent+=s.RANCH.feed_cost(s,"rabbit")
		check(s.RANCH.feed(s,"rabbit")["ok"] and s.RANCH.care(s,"rabbit")["ok"],"fourteen-day campaign uses actual feeding and daily care")
		check(s.GROWTH.interact(s,"rabbit")["ok"],"rabbit responds to its preferred morning interaction")
		before=s.to_data()
		check(not s.GROWTH.interact(s,"rabbit")["ok"] and s.to_data()==before,"trait activity obeys a saved daily cap")
		s.sleep()
	check(s.growth["days"]["rabbit"]==14 and s.GROWTH.stage(s,"rabbit")==3 and s.ranch["animals"]["rabbit"]["age"]==2,"growth and trust emerge from real days, food and care")
	for tier in range(3):
		check(s.GROWTH.claim(s,"rabbit",tier)["ok"],"earned animal milestones grant feed once")
		before=s.to_data()
		check(not s.GROWTH.claim(s,"rabbit",tier)["ok"] and s.to_data()==before,"animal milestone cannot replay")
	check(s.ranch["feed"]==20-feed_spent+16 and checkpoint(s),"milestone feed is exact and all growth flags persist")
	for id in s.RANCH_DATA.ORDER:
		var data := s.to_data()
		data["growth"]["claimed"][id]=7
		if id!="rabbit": check(not s._valid_data(data),"unearned animal milestone flags rejected")
	s=State.new()
	s.area_id="house"
	s.player_position=Vector2(239,185)
	var candidate := s.interior.duplicate(true)
	candidate[6][0]+=32
	candidate[7][2]=1
	check(s.INTERIOR.valid(candidate),"chest movement and rug rotation preserve all furniture and exit routes")
	var original := s.to_data()
	check(s.INTERIOR.apply(s,candidate,JSON.stringify(original).sha256_text())["ok"],"valid furniture preview applies after confirmation")
	check(s.interior==candidate and checkpoint(s),"moved and rotated furniture survive restart exactly")
	s.player_position=s.INTERIOR.anchors(s.interior)["home_storage"]
	s.produce["turnip"]=5
	check(s.HOME.transfer(s,"turnip",true,5)["ok"],"storage interaction follows moved chest")
	candidate=s.interior.duplicate(true)
	candidate[3]=[224,185,0]
	before=s.to_data()
	check(not s.INTERIOR.apply(s,candidate,s.CHAPTER.fingerprint(s))["ok"] and s.to_data()==before,"blocked exit preview cannot alter room")
	candidate=s.interior.duplicate(true)
	candidate[6]=[302,76,0]
	check(not s.INTERIOR.valid(candidate),"overlapping solid furniture rejected")
	candidate=s.interior.duplicate(true)
	candidate[5]=[900,80,0]
	check(not s.INTERIOR.valid(candidate),"furniture outside room rejected")
	candidate=s.interior.duplicate(true)
	candidate[0][2]=0.5
	check(not s.INTERIOR.valid(candidate),"non-integer rotations rejected")
	var invalid := s.to_data()
	invalid["chapter"]["stories"]["npc"]=1
	check(not s._valid_data(invalid),"story flag without earned relationship rejected")
	invalid=s.to_data()
	invalid["chapter"]["order_bits"]=8
	check(not s._valid_data(invalid),"invalid weekly bitmask rejected")
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game._close_modal()
	game.state=State.new()
	game.state.area_id="house"
	game._mount_area()
	for callback in [game.chapter_panels.hub,game.chapter_panels.people,game.chapter_panels.animals,game.chapter_panels.journeys,game.chapter_panels.orders,game.chapter_panels.goals,game.chapter_panels.furnishings]:
		before=game.state.to_data()
		callback.call()
		check(layout(game),"new chapter and furniture menus fit logical mobile viewport")
		game._process(15)
		check(game.state.to_data()==before,"browsing new systems pauses time and grants no resources")
	for id in game.state.CHAPTER.PEOPLE:
		for page in [0,1]:
			game.chapter_panels.story(id,page)
			await process_frame
			check(layout(game),"all personal event pages and choices fit")
	for id in game.state.RANCH_DATA.ORDER:
		game.chapter_panels.animal(id)
		check(layout(game),"all growth detail pages fit")
	for index in range(4):
		game.chapter_panels.journey(index)
		check(layout(game),"all regional quest pages fit")
	for index in range(3):
		game.chapter_panels.order_preview(index)
		check(layout(game),"weekly order confirmations fit")
	game.chapter_panels.furnishings()
	game.chapter_panels.furniture_select(7)
	before=game.state.to_data()
	game.chapter_panels.furniture_move(Vector2(8,0))
	game.chapter_panels.furniture_rotate()
	check(game.state.to_data()==before,"moving and rotating preview changes no saved room")
	game._close_modal()
	game.state=State.new()
	game.state.area_id="house"
	game.state.interior=s.interior.duplicate(true)
	game.state.player_position=Vector2(239,185)
	game._mount_area()
	for anchor in game.world.interactions().values():
		check(not game.world.blocked(anchor) and not game.navigation.get_point_path(Vector2i(game.state.player_position/8),Vector2i(anchor/8)).is_empty(),"actual game navigation matches edited furniture layout")
	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://chapter_test.json"+suffix))
	print("CHAPTER SYSTEMS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
