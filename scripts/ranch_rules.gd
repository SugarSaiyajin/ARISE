extends RefCounted

const DATA = preload("res://scripts/ranch_data.gd")

static func empty() -> Dictionary:
	var result := {"homes":[false,false,false,false], "feed":0, "stock":{}, "animals":{}, "friends":{}, "talked":{}, "hen_name":"琥珀雞"}
	for id in DATA.EXTRA:
		result["stock"][id] = 0
		result["animals"][id] = {"owned":false,"age":0,"cycle":0,"fed":false,"cared":false,"bond":0,"ready":0,"name":DATA.SPECIES[id]["name"]}
	for id in DATA.VISITORS:
		result["friends"][id] = 0
		result["talked"][id] = 0
	return result

static func home_open(s: RefCounted, home: int) -> bool:
	return s.ranch["homes"][home] or (home == 0 and s.coop_built)

static func on_site(s: RefCounted, id: String) -> bool:
	return DATA.SPECIES.has(id) and s.area_id == DATA.AREAS[DATA.SPECIES[id]["home"]]

static func result(ok: bool, text: String) -> Dictionary:
	return {"ok":ok,"text":text}

static func build(s: RefCounted, home: int) -> Dictionary:
	if home < 0 or home >= 4 or s.area_id not in ["farm", DATA.AREAS[home]] or home_open(s,home):
		return result(false,"棲地已開放，或請先回莊園安排建造。")
	var cost: Dictionary = DATA.HOME_COST[home]
	if s.money < cost["money"] or s.materials["wood"] < cost["wood"] or s.materials["stone"] < cost["stone"]:
		return result(false,"建造需要木材 %d、石料 %d、%d 銀。" % [cost["wood"],cost["stone"],cost["money"]])
	s.money -= cost["money"]
	s.materials["wood"] -= cost["wood"]
	s.materials["stone"] -= cost["stone"]
	s.ranch["homes"][home] = true
	if home == 0:
		s.coop_built = true
	return result(true,DATA.HOMES[home]+"已建好，可以迎接新夥伴。")

static func buy(s: RefCounted, id: String) -> Dictionary:
	if not on_site(s,id) or not home_open(s,DATA.SPECIES[id]["home"]):
		return result(false,"請到對應棲地，並先完成建造。")
	if id == "hen":
		if s.chickens >= s.LIVESTOCK.MAX_CHICKENS or s.money < 80:
			return result(false,"母雞上限三隻，領養每隻需要 80 銀。")
		s.money -= 80
		s.chickens += 1
		return result(true,"琥珀雞已入住，記得準備收成小麥。")
	var animal: Dictionary = s.ranch["animals"][id]
	if animal["owned"] or s.money < DATA.SPECIES[id]["price"]:
		return result(false,"已經有這位夥伴，或銀幣不足。")
	s.money -= DATA.SPECIES[id]["price"]
	animal["owned"] = true
	return result(true,"新夥伴入住了！餵養後休息，幼體會逐日成長。")

static func buy_feed(s: RefCounted) -> Dictionary:
	if s.area_id != "farm" and s.area_id not in DATA.AREAS:
		return result(false,"請回莊園或牧場採買。")
	if s.money < 20 or s.ranch["feed"] > DATA.LIMIT - 10:
		return result(false,"補給需要 20 銀，或飼料庫存已滿。")
	s.money -= 20
	s.ranch["feed"] += 10
	return result(true,"購入十份照料飼料，使用時配成穀草、花料、桑葉或魚食。")

static func feed_cost(s: RefCounted, id: String) -> int:
	return 0 if id in DATA.EXTRA and s.ranch["animals"][id]["bond"]>=20 and s.day%4==0 else 1

static func feed(s: RefCounted, id: String) -> Dictionary:
	if not on_site(s,id):
		return result(false,"請走到對應棲地。")
	if id == "hen":
		var origin: String = s.area_id
		s.area_id = "farm"
		var answer: Dictionary = s.feed_chickens()
		s.area_id = origin
		return answer
	var animal: Dictionary = s.ranch["animals"][id]
	var cost := feed_cost(s,id)
	if not animal["owned"] or animal["fed"] or s.ranch["feed"] < cost:
		return result(false,"尚未領養、今日已餵，或照料飼料不足。")
	if animal["ready"] >= 24:
		return result(false,"產物箱已滿，請先領取。")
	s.ranch["feed"] -= cost
	animal["fed"] = true
	return result(true,"已備好今天的食物；休息後結算成長與產物。")

static func care(s: RefCounted, id: String) -> Dictionary:
	if not on_site(s,id) or id == "hen":
		return result(false,"母雞照料沿用餵食與巢箱，請選其他夥伴。")
	var a: Dictionary = s.ranch["animals"][id]
	var energy_cost := 0 if s.ESTATE.has_facility(s,2) else 1
	if not a["owned"] or a["cared"] or s.energy < energy_cost:
		return result(false,"尚未領養、今天已照料，或體力不足。")
	s.energy -= energy_cost
	s.estate["care_total"]=mini(100000000,s.estate["care_total"]+1)
	s.GROWTH.record(s,id)
	a["cared"] = true
	a["bond"] = mini(100,a["bond"]+1)
	return result(true,"照料完成，好感增加。"+DATA.SPECIES[id]["hint"])

static func rename(s: RefCounted, id: String, nickname: String) -> Dictionary:
	if not on_site(s,id) or nickname.strip_edges().is_empty() or nickname.length() > 12 or "\n" in nickname or "\t" in nickname:
		return result(false,"名字請用一至十二個字，不含換行。")
	if id == "hen":
		if s.chickens == 0: return result(false,"請先迎接母雞。")
		s.ranch["hen_name"] = nickname.strip_edges()
	else:
		if not s.ranch["animals"][id]["owned"]: return result(false,"請先迎接夥伴。")
		s.ranch["animals"][id]["name"] = nickname.strip_edges()
	return result(true,"已記下新名字。")

static func collect(s: RefCounted, id: String) -> Dictionary:
	if not on_site(s,id): return result(false,"請到對應棲地領取。")
	if id == "hen":
		var origin: String = s.area_id
		s.area_id = "farm"
		var answer: Dictionary = s.collect_eggs()
		s.area_id = origin
		return answer
	var a: Dictionary = s.ranch["animals"][id]
	if not a["owned"] or a["ready"] <= 0 or s.ranch["stock"][id] > DATA.LIMIT - a["ready"]:
		return result(false,"沒有可領產物，或行囊已滿。")
	s.ranch["stock"][id] += a["ready"]
	a["ready"] = 0
	return result(true,DATA.SPECIES[id]["product"]+"已收入行囊，可到莊園出貨。")

static func advance(s: RefCounted) -> void:
	for id in DATA.EXTRA:
		var a: Dictionary = s.ranch["animals"][id]
		if a["owned"] and a["fed"]:
			if a["age"] < DATA.SPECIES[id]["days"]:
				a["age"] += 1
			else:
				a["cycle"] += 1
				if a["cycle"] >= DATA.SPECIES[id]["interval"] and a["ready"] < 24:
					a["ready"] += 1
					a["cycle"] = 0
		a["fed"] = false
		a["cared"] = false

static func talk(s: RefCounted, id: String) -> Dictionary:
	if not DATA.RESIDENTS.has(id) or s.area_id != DATA.visitor_area(id,s.minute,s.is_raining()):
		return result(false,"居民目前不在這裡。")
	if s.ranch["talked"][id] != s.day:
		s.ranch["talked"][id] = s.day
		s.ranch["friends"][id] = mini(100,s.ranch["friends"][id]+1)
	return result(true,DATA.RESIDENTS[id]["line"])

static func integer(v: Variant, limit: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= 0 and v <= limit and v == int(v)

static func valid(v: Variant, day: int, coop: bool) -> bool:
	if not v is Dictionary or v.size() != 7: return false
	for key in empty():
		if not v.has(key): return false
	if not v["homes"] is Array or v["homes"].size() != 4: return false
	for flag in v["homes"]:
		if not flag is bool: return false
	if v["homes"][0] and not coop: return false
	if not integer(v["feed"],DATA.LIMIT) or not valid_name(v["hen_name"]): return false
	for key in ["animals","stock","friends","talked"]:
		if not v[key] is Dictionary: return false
	if v["animals"].size()!=7 or v["stock"].size()!=7 or v["friends"].size()!=6 or v["talked"].size()!=6: return false
	for id in DATA.EXTRA:
		if not v["stock"].has(id) or not integer(v["stock"][id],DATA.LIMIT): return false
		var a: Variant = v["animals"].get(id)
		if not a is Dictionary or a.size()!=8: return false
		for key in ["owned","fed","cared"]:
			if not a.get(key) is bool: return false
		for key in ["age","cycle","bond","ready"]:
			var limit: int = {"age":DATA.SPECIES[id]["days"],"cycle":DATA.SPECIES[id]["interval"]-1,"bond":100,"ready":24}[key]
			if not integer(a.get(key),limit): return false
		if not valid_name(a.get("name")): return false
		if a["owned"] and not v["homes"][DATA.SPECIES[id]["home"]] and not (DATA.SPECIES[id]["home"]==0 and coop): return false
		if not a["owned"] and (a["age"]>0 or a["cycle"]>0 or a["bond"]>0 or a["ready"]>0 or a["fed"] or a["cared"]): return false
		if a["age"] < DATA.SPECIES[id]["days"] and (a["ready"]>0 or a["cycle"]>0): return false
	for id in DATA.VISITORS:
		if not integer(v["friends"].get(id),100) or not integer(v["talked"].get(id),day): return false
	return true

static func valid_name(v: Variant) -> bool:
	return v is String and not v.strip_edges().is_empty() and v.length() <= 12 and "\n" not in v and "\t" not in v

static func normalized(v: Dictionary) -> Dictionary:
	var copy := v.duplicate(true)
	copy["feed"] = int(copy["feed"])
	for id in DATA.EXTRA:
		copy["stock"][id] = int(copy["stock"][id])
		for key in ["age","cycle","bond","ready"]: copy["animals"][id][key] = int(copy["animals"][id][key])
	for id in DATA.VISITORS:
		copy["friends"][id] = int(copy["friends"][id])
		copy["talked"][id] = int(copy["talked"][id])
	return copy
