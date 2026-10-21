extends SceneTree
const State = preload("res://scripts/farm_state.gd")
func _initialize() -> void:
	var s := State.new()
	var report := {"crops":{},"crafts":{},"animals":{},"notes":["Crop daily margins use listed watered days; summer bonus growth is not included.","Animal estimates use purchased feed at 2 silver per ration; wood/stone gathering and player stamina are separate costs.","Craft margins deduct sale value of raw products and listed cash fee; unshippable wood/stone have no cash quote."]}
	var failed := false
	for id in State.CROP_ORDER:
		var item: Dictionary=State.CROPS[id]
		var spring: int=item["price"]
		s.day=29
		var summer: int=s.JOURNEY.crop_price(s,id)
		report["crops"][id]={"seed":item["seed_cost"],"watered_days":item["days"],"spring_sell":spring,"summer_sell":summer,"spring_net_per_watered_day":float(spring-item["seed_cost"])/item["days"],"summer_net_per_watered_day":float(summer-item["seed_cost"])/item["days"]}
		if spring<=item["seed_cost"]: failed=true
	for id in State.LIFE_DATA.GOODS:
		var values := []
		for day in [1,29]:
			s.day=day
			var inputs := 0
			for source in State.LIFE_DATA.RECIPES[id]["needs"]:
				if source[0]=="ranch": inputs+=State.RANCH_DATA.SPECIES[source[1]]["sell"]*source[2]
				elif source[0]=="produce": inputs+=s.JOURNEY.crop_price(s,source[1])*source[2]
			var net: int=State.LIFE_DATA.PRODUCTS[id]["price"]-inputs-State.LIFE_DATA.FEES[id]
			values.append(net)
			if net<=0: failed=true
		report["crafts"][id]={"sell":State.LIFE_DATA.PRODUCTS[id]["price"],"fee":State.LIFE_DATA.FEES[id],"ready_after_sleeps":1,"spring_net_over_raw_sale":values[0],"summer_net_over_raw_sale":values[1]}
	for id in State.RANCH_DATA.ORDER:
		var item: Dictionary=State.RANCH_DATA.SPECIES[id]
		var net: float=float(item["sell"])/item["interval"]-(State.CROPS["wheat"]["price"] if id=="hen" else 2)
		report["animals"][id]={"purchase":item["price"],"habitat_cash":State.RANCH_DATA.HOME_COST[item["home"]]["money"],"maturity_fed_days":item["days"],"production_interval":item["interval"],"cash_net_per_adult_fed_day":net}
		if net<=0: failed=true
	var file := FileAccess.open("res://docs/balance-0.24.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("BALANCE AUDIT: ","failed" if failed else "all crop, animal and craft routes have positive cash margins")
	quit(1 if failed else 0)
