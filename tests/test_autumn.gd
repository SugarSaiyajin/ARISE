extends SceneTree
const State=preload("res://scripts/farm_state.gd")
const Art=preload("res://scripts/autumn_art.gd")
var passed:=0
var failed:=0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func checkpoint(s: RefCounted) -> bool:
	if s.save_game("user://autumn-test.json")!=OK: return false
	var loaded:=State.new()
	return loaded.load_game("user://autumn-test.json") and loaded.to_data()==s.to_data()
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
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for d in [1,28,29,56,57,70,84,85,98,112,113,126,140,168,169,999999]:
		var s:=State.new()
		s.day=d
		var old:=s.to_data()
		old.erase("calendar_offset")
		old.erase("calendar_since")
		old.erase("autumn")
		for key in ["seeds","produce"]:
			for id in State.CROP_DATA.AUTUMN: old[key].erase(id)
		for id in State.CROP_DATA.AUTUMN: old["home"]["stored"].erase(id)
		for id in s.AUTUMN.RECIPES: old["meals"].erase(id)
		old["journey"]["gifts"]["npc"]=d
		old["chapter"]["order_week"]=(d-1)/7+1
		check(s._valid_data(old),"legacy boundary valid before migration")
		s._apply_data(old)
		check(s.day==d and s.season()==("春" if ((d-1)/28)%2==0 else "夏") and s.calendar_year()==(d-1)/56+1,"legacy keeps absolute day, displayed season and year")
		check(s.journey["gifts"]["npc"]==d and s.chapter["order_week"]==(d-1)/7+1 and s.autumn==s.AUTUMN.empty(),"migration preserves caps without granting new rewards")
		check(checkpoint(s),"migration persists once through real JSON save/load")
		var offset:=s.calendar_offset
		s._apply_data(s.to_data())
		check(s.calendar_offset==offset,"new-format reload never adds a second epoch")
	var s:=State.new()
	# A historic summer job from the old first year must remain valid after migrating year2.
	s.day=100
	var old:=s.to_data()
	old.erase("calendar_offset")
	old.erase("calendar_since")
	old["estate"]["summer_jobs"]["culture_grove"]=42
	old["estate"]["summer_completed"]=1
	old["journey"]["summer_cycle"]=2
	old["journey"]["summer_done"]=2
	old["journey"]["summer_offered"]=["turnip","wheat","berry"]
	old["rack_built"]=true
	old["processing_job"]={"recipe":"dried_wheat","amount":1,"ready_day":101}
	check(s._valid_data(old),"legacy historical summer records and processing deadline valid")
	s._apply_data(old)
	check(s.season()=="夏" and s.calendar_year()==2 and not s.JOURNEY.summer_open(s) and checkpoint(s),"historical summer records survive epoch migration and cannot repay")
	s.sleep()
	check(s.day==101 and s.processing_ready(),"job ready day stays exact after migrated sleep")
	for d in [57,84,141,168]:
		s=State.new()
		s.day=d
		check(s.season()=="秋" and s.calendar_year()==(1 if d<85 else 2),"new games enter autumn in each84day year")
	s=State.new()
	s.day=84
	s.sleep()
	check(s.day==85 and s.season()=="春" and s.calendar_year()==2,"autumn ends at next spring without resetting total day")
	for id in State.CROP_DATA.AUTUMN:
		s=State.new()
		s.money=1000
		var before:=s.to_data()
		check(not s.buy(id)["ok"] and s.to_data()==before,"autumn seeds unavailable in spring with no charge")
		s.day=57
		check(s.buy(id)["ok"] and s.money==1000-State.CROPS[id]["seed_cost"],"exact approved seed cost")
		check(s.work(2,"seed",id)["ok"] and s.seeds[id]==0,"one seed plants one crop")
		s.plots[2]["watered"]=false
		s.sleep()
		check(s.plots[2]["growth"]==0,"dry autumn crop pauses growth")
		for n in range(State.CROPS[id]["days"]):
			s.energy=100
			s.plots[2]["watered"]=true
			s.sleep()
			check(s.plots[2]["growth"]==n+1 and checkpoint(s),"each watered night grows once, including growth8and9 save values")
		check(s.work(2,"harvest")["ok"] and s.produce[id]==1,"mature crop yields a single harvest")
		before=s.to_data()
		check(not s.work(2,"harvest")["ok"] and s.to_data()==before,"grapes and all autumn crops cannot duplicate harvest")
		check(s.JOURNEY.crop_price(s,id)==State.CROPS[id]["price"],"approved harvest price unchanged")
		s.day=84
		s.seeds[id]=1
		check(s.work(2,"seed",id)["ok"],"late autumn planting allowed")
		s.plots[2]["watered"]=true
		s.sleep()
		check(s.season()=="春" and s.plots[2]["crop"]==id and s.plots[2]["growth"]==1,"cross-season crops and seeds survive")
	for choice in [1,2]:
		s=State.new()
		s.day=70
		s.area_id="town"
		s.player_position=s.AUTUMN.STAND
		for id in State.CROP_DATA.AUTUMN:
			s.produce[id]=4
			check(s.AUTUMN.donate(s,id)["ok"] and s.produce[id]==3,"fair consumes exactly one of each approved autumn crop")
			var before:=s.to_data()
			check(not s.AUTUMN.donate(s,id)["ok"] and s.to_data()==before,"duplicate offering cannot charge")
		check(checkpoint(s),"partial/complete offering save survives")
		var cash:=s.money
		check(s.AUTUMN.finish(s,choice)["ok"] and s.money==cash+200 and s.autumn["choice"]==choice,"both resident choices unlock recipes and pay once")
		var before:=s.to_data()
		check(not s.AUTUMN.finish(s,choice)["ok"] and s.to_data()==before,"festival cannot repeat payout")
		check(s.AUTUMN.exchange(s,"pumpkin")["ok"] and s.produce["pumpkin"]==2 and s.seeds["pumpkin"]==2,"basket exchanges real produce for two seeds")
		before=s.to_data()
		check(not s.AUTUMN.exchange(s,"grape")["ok"] and s.to_data()==before,"daily exchange limit shared across crops")
		check(s.cook("harvest_soup")["ok"] and s.produce["pumpkin"]==1 and s.produce["sweet_potato"]==2,"celadon pot uses exact two crops")
		check(s.cook("grape_juice")["ok"] and s.produce["grape"]==1,"press uses two grapes per juice")
		s.energy=0
		check(s.eat_meal("harvest_soup")["ok"] and s.energy==65 and s.eat_meal("grape_juice")["ok"] and s.energy==100,"autumn foods restore stated energy capped at100")
		check(checkpoint(s),"choice, recipes, exchange cap and food survive real restart")
		for key in s.AUTUMN.empty():
			var malformed:=s.to_data()
			malformed["autumn"][key]=null
			check(not s._valid_data(malformed),"malformed autumn field rejected safely")
		s.day=154
		for id in State.CROP_DATA.AUTUMN:
			s.produce[id]=1
			check(s.AUTUMN.donate(s,id)["ok"],"next year starts fresh basket")
		check(s.AUTUMN.finish(s,choice)["ok"] and checkpoint(s),"next year permits exactly one new fair")
	s=State.new()
	s.day=70
	s.produce["pumpkin"]=1
	s.produce["sweet_potato"]=1
	s.area_id="house"
	var before:=s.to_data()
	check(not s.cook("harvest_soup")["ok"] and s.to_data()==before,"recipe unavailable before actual fair completion")
	s.area_id="town"
	s.player_position=Vector2(30,147)
	before=s.to_data()
	check(not s.AUTUMN.donate(s,"pumpkin")["ok"] and s.to_data()==before,"remote fair cannot consume offering")

	# Complete a year using only starter resources and real work/sleep/shop/fair calls.
	s=State.new()
	for today in range(1,85):
		s.area_id="farm"
		for i in range(s.plots.size()):
			if s.is_mature(s.plots[i]): check(s.work(i,"harvest")["ok"],"year campaign harvest uses real energy")
		if today==57:
			for i in range(3):
				var id: String=State.CROP_DATA.AUTUMN[i]
				check(s.buy(id)["ok"],"campaign buys autumn seeds from earned/start cash")
				if not s.plots[2+i]["tilled"]: check(s.work(2+i,"hoe")["ok"],"campaign tills real field")
				check(s.work(2+i,"seed",id)["ok"],"campaign sows autumn seed")
		for i in range(s.plots.size()):
			if s.plots[i]["crop"]!="" and not s.plots[i]["watered"]: check(s.work(i,"water")["ok"],"campaign waters without grants")
		if today==70:
			s.area_id="town"
			s.player_position=s.AUTUMN.STAND
			for id in State.CROP_DATA.AUTUMN: check(s.AUTUMN.donate(s,id)["ok"],"campaign brings three actually grown crops")
			check(s.AUTUMN.finish(s,1)["ok"],"campaign completes real fair")
		check(checkpoint(s),"each day of year remains saveable")
		s.sleep()
	check(s.day==85 and s.calendar_year()==2 and s.season()=="春" and s.autumn["done"]==1 and s.money==209,"84day campaign reaches next spring with real fair payout and exact seed costs")
	for entry in [[Art.CROPS,Art.F.CROPS],[Art.OBJECTS,Art.F.OBJECTS]]:
		for row in entry[1]:
			for frame in row:
				check(frame[0]>=0 and frame[1]>=0 and frame[0]+frame[2]<=1536 and frame[1]+frame[3]<=1024,"production frame remains inside source atlas")
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_allowed=false
	game.audio_system.shutdown()
	game._close_modal()
	game.state=State.new()
	game.state.day=70
	game.state.area_id="town"
	game.state.player_position=Vector2(210,185)
	game._mount_area()
	game._update_ui()
	check(game.world.interactions().has("harvest_table") and not game.world.blocked(Vector2(210,185)),"fair has reachable selectable real-world anchor")
	for callback in [game.autumn_panels.hub,game.autumn_panels.workshop,game.journey_panels.calendar]:
		callback.call()
		await process_frame
		check(layout(game),"autumn panel fits desktop and mobile with no paragraph/button overlap")

	game.state.area_id="house"
	for id in game.state.AUTUMN.RECIPES:
		game._show_cookbook(game.state.COOKING.ORDER.find(id))
		await process_frame
		check(layout(game),"locked autumn recipe notice cannot overlap cooking buttons")
	game.state.area_id="town"
	for id in State.CROP_DATA.AUTUMN: game.state.produce[id]=1
	for id in State.CROP_DATA.AUTUMN: game.state.AUTUMN.donate(game.state,id)
	game.autumn_panels.story()
	await process_frame
	check(layout(game),"both fair choices remain inside card")
	game.autumn_panels.finish(1)
	await process_frame
	check(layout(game),"resident memory remains inside card")
	game._close_modal()
	game.queue_free()
	await process_frame
	print("AUTUMN: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
