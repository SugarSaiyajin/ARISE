extends SceneTree
const State = preload("res://scripts/farm_state.gd")
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	var reports := {}
	for diversified in [false,true]:
		var s := State.new()
		var rows: Array=[]
		var spending := 0
		var crops := ["turnip","turnip","turnip","turnip","wheat","wheat","berry","tea"] if diversified else ["turnip","turnip","turnip","turnip","turnip","turnip","turnip","turnip"]
		var indices := [0,1,2,3,7,8,9,10]
		for day in range(1,57):
			s.area_id="farm"
			check(s.day==day,"annual progression does not skip or repeat days")
			for n in range(8):
				var index: int=indices[n]
				if s.is_mature(s.plots[index]): check(s.work(index,"harvest")["ok"],"campaign harvests mature crops through real action")
				if not s.plots[index]["tilled"]: s.work(index,"hoe")
				if s.plots[index]["crop"]=="":
					var crop: String=crops[n]
					if s.seeds[crop]==0 and s.money>=s.CROPS[crop]["seed_cost"]:
						var cash: int=s.money
						check(s.buy(crop,1)["ok"],"replacement seed uses real shop price")
						spending+=cash-s.money
					if s.seeds[crop]>0: check(s.work(index,"seed",crop)["ok"],"campaign replants with owned seed")
				if s.plots[index]["crop"]!="" and not s.plots[index]["watered"]: check(s.work(index,"water")["ok"],"campaign waters within daily stamina budget")
			if diversified:
				if day%3==0:
					s.area_id="forest"
					for id in s.FORAGE.NODES:
						if s.energy>=s.FORAGE.MATERIALS[s.FORAGE.NODES[id]["kind"]]["energy"]: s.gather(id)
					s.area_id="farm"
				if day>=12 and not s.ranch["homes"][1] and s.money>=280 and s.materials["wood"]>=6 and s.materials["stone"]>=3:
					var cash: int=s.money
					check(s.RANCH.build(s,1)["ok"],"diversified campaign builds habitat from earned funds")
					s.area_id="ranch_meadow"
					check(s.RANCH.buy(s,"rabbit")["ok"],"campaign buys rabbit with remaining cash")
					spending+=cash-s.money
				if day>=20 and not s.ranch["homes"][2] and s.money>=310 and s.materials["wood"]>=6 and s.materials["stone"]>=4:
					s.area_id="farm"
					var cash: int=s.money
					check(s.RANCH.build(s,2)["ok"],"campaign builds second habitat")
					s.area_id="ranch_silk"
					check(s.RANCH.buy(s,"bee")["ok"],"campaign buys second animal species")
					spending+=cash-s.money
				if s.ranch["feed"]<3 and s.produce["wheat"]>0:
					s.area_id="farm"
					s.LIFE.craft(s,"grain_feed")
				if s.ranch["feed"]<2 and s.money>=20:
					s.area_id="farm"
					var cash: int=s.money
					s.RANCH.buy_feed(s)
					spending+=cash-s.money
				for id in ["rabbit","bee"]:
					if not s.ranch["animals"][id]["owned"]: continue
					s.area_id=s.RANCH_DATA.AREAS[s.RANCH_DATA.SPECIES[id]["home"]]
					if s.ranch["feed"]>0: s.RANCH.feed(s,id)
					if s.energy>0: s.RANCH.care(s,id)
					if s.ranch["animals"][id]["ready"]>0: s.RANCH.collect(s,id)
				if s.life["job"].get("ready_day",day+1)<=day:
					s.area_id="culture_sanctuary"
					s.LIFE.collect(s)
				if s.life["job"].is_empty() and s.ranch["stock"]["bee"]>0 and s.produce["tea"]>0 and s.money>=8:
					s.area_id="culture_sanctuary"
					var cash: int=s.money
					s.LIFE.craft(s,"honey_tea")
					spending+=cash-s.money
				s.area_id="farm"
				if day>=15 and s.journey["tool_level"]==0 and s.money>=300 and s.materials["wood"]>=8 and s.materials["stone"]>=6:
					var cash: int=s.money
					check(s.JOURNEY.upgrade_tool(s)["ok"],"water tool investment is affordable with earned currency")
					spending+=cash-s.money
				if day>=35 and not s.ESTATE.has_facility(s,3) and s.money>=240 and s.materials["wood"]>=8 and s.materials["stone"]>=4:
					var cash: int=s.money
					check(s.ESTATE.build(s,1,3)["ok"],"late-season storage uses earned materials and cash")
					spending+=cash-s.money
			s.area_id="farm"
			s.ship_with_reserve()
			rows.append({"day":day,"season":s.JOURNEY.season(day),"cash":s.money,"harvested":s.harvested,"earned":s.total_earned,"energy_left":s.energy})
			check(s._valid_data(s.to_data()),"daily campaign state remains valid through season and production boundaries")
			var save := "user://estate_campaign_"+str(diversified)+".json"
			check(s.save_game(save)==OK,"campaign daily checkpoint commits")
			var loaded := State.new()
			check(loaded.load_game(save) and loaded.to_data()==s.to_data(),"campaign daily restart preserves all business state")
			s=loaded
			s.sleep()
		check(s.day==57 and s.season()=="秋" and s.money>120 and s.harvested>50,"both campaigns finish a profitable spring-summer campaign entering autumn without grants")
		check(s.money==120+s.total_earned-spending,"year budget conserves all starting cash, sale income and recorded expenses")
		reports["mixed_farm" if diversified else "crop_farm"]={"daily":rows,"ending_cash":s.money,"shipping_income":s.total_earned,"cash_spent":spending,"harvested":s.harvested,"care_total":s.estate["care_total"],"craft_total":s.estate["craft_total"],"water_tool":s.journey["tool_level"],"storage":s.ESTATE.has_facility(s,3)}
	var file := FileAccess.open("res://docs/campaign-balance-0.25.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"type":"deterministic business-state simulation, not device gameplay","days_per_policy":56,"starting_cash":120,"currency_or_material_grants":false,"travel_clock_and_path_time_modeled":false,"policies_have_different_workloads":true,"policies":reports},"\t"))
	file.close()
	print("ESTATE YEAR TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
