class_name FarmState
extends RefCounted

const JOURNEY = preload("res://scripts/journey_rules.gd")
var journey: Dictionary = JOURNEY.empty()

const LIFE = preload("res://scripts/life_rules.gd")
const LIFE_DATA = preload("res://scripts/life_data.gd")
const RANCH = preload("res://scripts/ranch_rules.gd")
const RANCH_DATA = preload("res://scripts/ranch_data.gd")
const SAVE_VERSION := 1
const COOKING = preload("res://scripts/cooking_data.gd")
const FISHING = preload("res://scripts/fishing_data.gd")
const EXPLORATION = preload("res://scripts/exploration_data.gd")
const LIVESTOCK = preload("res://scripts/livestock_data.gd")
const REQUESTS = preload("res://scripts/request_data.gd")
const PROCESSING = preload("res://scripts/processing_data.gd")
const FORAGE = preload("res://scripts/forest_data.gd")
const COLS := 7
const ROWS := 4
const MAX_ENERGY := 100
const CROP_DATA = preload("res://scripts/crop_data.gd")
const STOCKS = preload("res://scripts/stock_rules.gd")
const SPRING = preload("res://scripts/spring_rules.gd")
const RESIDENTS = preload("res://scripts/resident_data.gd")
const CROPS = CROP_DATA.CROPS
const CROP_ORDER = CROP_DATA.ORDER
var day: int = 1
var minute: float = 420.0
var money: int = 120
var energy: int = MAX_ENERGY
var seeds: Dictionary = CROP_DATA.initial_seeds()
var produce: Dictionary = STOCKS.normalized({}, CROP_ORDER)
var plots: Array = []
var harvested: int = 0
var total_earned: int = 0
var reward_claimed: bool = false
var talked_today: bool = false
var friendship: int = 0
var player_position := Vector2(232, 200)
var area_id: String = "farm"
var load_notice: String = ""
var materials := {"wood": 0, "stone": 0, "herb": 0}
var gathered: Dictionary = {}
var fence_repaired := false
var rack_built := false
var goods: Dictionary = STOCKS.normalized({}, PROCESSING.ORDER)
var processing_job: Dictionary = {}
var active_request := ""
var request_completed_day := 0
var requests_completed := 0
var tea_event_seen := false
var coop_built := false
var chickens := 0
var fed_chickens := 0
var nest_eggs := 0
var eggs := 0
var route_restored := false
var relic_recovered := false
var fishing_rod := false
var fish := {"silver_carp": 0, "mist_trout": 0, "star_perch": 0}
var fish_caught_today := 0
var meals: Dictionary = STOCKS.normalized({}, COOKING.ORDER)
var life: Dictionary = LIFE.empty()
var ranch: Dictionary = RANCH.empty()
var hero_style := "male"
var spring_progress: Dictionary = SPRING.empty_progress()
# Pending casts are deliberately not serialized; restarting never grants a fish.
var _fishing_pending := false
var _fishing_area := ""

func _init() -> void:
	for i in range(COLS * ROWS):
		plots.append({"tilled": false, "crop": "", "growth": 0, "watered": false})
	# The abandoned manor has a small inherited vegetable patch.
	for i in [0, 1, 7, 8]:
		plots[i] = {"tilled": true, "crop": "turnip", "growth": 1, "watered": false}
	plots[2]["tilled"] = true

func is_raining() -> bool:
	return JOURNEY.rain(day)

func is_mature(plot: Dictionary) -> bool:
	return plot["crop"] != "" and plot["growth"] >= CROPS[plot["crop"]]["days"]

func work(index: int, tool: String, crop: String = "turnip") -> Dictionary:
	if index < 0 or index >= plots.size():
		return {"ok": false, "text": "請靠近田地再操作。"}
	var p: Dictionary = plots[index]
	var cost: int = 1 if tool in ["seed", "harvest"] or (tool=="water" and journey["tool_level"]==1) else 2
	if energy < cost:
		return {"ok": false, "text": "有點累了，回農舍睡一覺吧。"}
	var message := ""
	match tool:
		"hoe":
			if p["tilled"]:
				return {"ok": false, "text": "這塊田已經開墾，可以播種了。"}
			p["tilled"] = true
			p["watered"] = is_raining()
			message = "鬆軟的泥土，準備好迎接種子。"
		"seed":
			if not CROPS.has(crop):
				return {"ok": false, "text": "未知的種子。"}
			if not p["tilled"] or p["crop"] != "":
				return {"ok": false, "text": "先開墾一塊空田，再播種。"}
			if seeds[crop] <= 0:
				return {"ok": false, "text": "種子用完了，去東側的商攤補充吧。"}
			seeds[crop] -= 1
			p["crop"] = crop
			p["growth"] = 0
			message = "種下了%s。每天澆水，睡醒後就會成長。" % CROPS[crop]["name"]
		"water":
			if not p["tilled"]:
				return {"ok": false, "text": "這裡還不是田地。"}
			if p["watered"]:
				return {"ok": false, "text": "今天的水分已經足夠了。"}
			p["watered"] = true
			message = "澆好水了。濕潤的田地會呈現深褐色。"
		"harvest":
			if not is_mature(p):
				return {"ok": false, "text": "還沒成熟，繼續澆水並等待吧。"}
			if produce.get(p["crop"],0) >= 100000000:
				return {"ok":false,"text":"這份收成已放滿，先整理行囊。"}
			var harvested_crop: String = p["crop"]
			produce[harvested_crop] = produce.get(harvested_crop, 0) + 1
			harvested += 1
			p["crop"] = ""
			p["growth"] = 0
			message = "收穫了%s！可到西側出貨箱出售。" % CROPS[harvested_crop]["name"]
		_:
			return {"ok": false, "text": "請選擇一項工具。"}
	energy -= cost
	JOURNEY.mark(self,tool)
	return {"ok": true, "text": message}

func buy(crop: String, amount: int = 1) -> Dictionary:
	if not CROPS.has(crop) or amount <= 0 or amount > 99:
		return {"ok": false, "text": "無效的購買數量。"}
	var cost: int = CROPS[crop]["seed_cost"] * amount
	if seeds.get(crop,0) > 100000000-amount:
		return {"ok":false,"text":"種子已放滿，先播種一些吧。"}
	if money < cost:
		return {"ok": false, "text": "銀幣不足，先收穫一些作物吧。"}
	money -= cost
	seeds[crop] = seeds.get(crop, 0) + amount
	return {"ok": true, "text": "買到了 %d 包%s種子。" % [amount, CROPS[crop]["name"]]}

func sell_all() -> Dictionary:
	var earnings: int = 0
	for crop in CROP_ORDER:
		earnings += produce.get(crop, 0) * JOURNEY.crop_price(self,crop)
	for recipe in PROCESSING.ORDER:
		earnings += goods.get(recipe, 0) * PROCESSING.RECIPES[recipe]["price"]
	for id in RANCH_DATA.EXTRA:
		earnings += ranch["stock"][id] * RANCH_DATA.SPECIES[id]["sell"]
	for id in LIFE_DATA.GOODS:
		earnings += life["stock"][id] * LIFE_DATA.PRODUCTS[id]["price"]
	earnings += eggs * LIVESTOCK.EGG_PRICE
	for species in FISHING.ORDER:
		earnings += fish[species] * FISHING.FISH[species]["price"]
	if earnings == 0:
		return {"ok": false, "text": "行囊裡沒有可出貨的作物、成品、雞蛋或魚獲。"}
	if money > 1000000000000-earnings or total_earned > 1000000000000-earnings:
		return {"ok":false,"text":"帳簿金額已達上限，這批物品仍留在行囊。"}
	for crop in CROP_ORDER:
		produce[crop] = 0
	for recipe in PROCESSING.ORDER:
		goods[recipe] = 0
	eggs = 0
	for id in LIFE_DATA.GOODS: life["stock"][id] = 0
	for id in RANCH_DATA.EXTRA:
		ranch["stock"][id] = 0
	for species in FISHING.ORDER:
		fish[species] = 0
	money += earnings
	total_earned += earnings
	JOURNEY.mark(self,"ship")
	return {"ok": true, "text": "商隊收走了作物、成品、養殖產物與魚獲，獲得 %d 銀幣。" % earnings}

func talk() -> String:
	if not talked_today:
		talked_today = true
		friendship += 1
	if harvested >= 5 and not reward_claimed:
		reward_claimed = true
		money += 80
		return "你已收穫五份作物！這 80 銀幣是大家的心意。願這座莊園再次熱鬧起來。"
	if day == 1:
		return "我是茶館的青禾。舊田裡還有幾株蕪菁，澆水後睡一覺就能收成。等你收穫五份作物，我有一份小禮物。"
	if is_raining():
		return "今天下雨，田地會自己喝飽水。要不要趁機整理莊園？"
	return "茶香會讓人記得回家的路。記得每天澆水，成熟後採收，再到木箱出貨。"

func gather(node_id: String) -> Dictionary:
	if area_id != "forest" or not FORAGE.NODES.has(node_id):
		return {"ok": false, "text": "請到林地的採集點操作。"}
	if gathered.has(node_id):
		return {"ok": false, "text": "這裡今天已採集，睡醒後再來吧。"}
	var kind: String = FORAGE.NODES[node_id]["kind"]
	var data: Dictionary = FORAGE.MATERIALS[kind]
	if energy < data["energy"]:
		return {"ok": false, "text": "體力不足，回農舍休息或喝杯草茶吧。"}
	if materials[kind] > 100000000 - data["amount"]:
		return {"ok": false, "text": "這項素材已放滿。"}
	energy -= data["energy"]
	materials[kind] += data["amount"]
	gathered[node_id] = true
	return {"ok": true, "text": "%s +%d · 體力 -%d" % [data["name"], data["amount"], data["energy"]]}

func repair_fence() -> Dictionary:
	if area_id != "farm":
		return {"ok": false, "text": "請回莊園的舊圍欄施工。"}
	if fence_repaired:
		return {"ok": false, "text": "圍欄已修好了，莊園又多了一點生氣。"}
	for kind in FORAGE.REPAIR_COST:
		if materials[kind] < FORAGE.REPAIR_COST[kind]:
			return {"ok": false, "text": "需要木材 6、石料 4；可從鎮東的林地採集。"}
	for kind in FORAGE.REPAIR_COST:
		materials[kind] -= FORAGE.REPAIR_COST[kind]
	fence_repaired = true
	return {"ok": true, "text": "莊園圍欄修好了！木樁與石基迎來了新生。"}

func brew_tea() -> Dictionary:
	if area_id != "house":
		return {"ok": false, "text": "請到農舍爐邊煮茶。"}
	if energy >= MAX_ENERGY:
		return {"ok": false, "text": "體力已滿，先留著香草吧。"}
	if materials["herb"] < 1:
		return {"ok": false, "text": "需要霧香草 1 份，可在林地採集。"}
	materials["herb"] -= 1
	var restored := mini(20, MAX_ENERGY - energy)
	energy += restored
	return {"ok": true, "text": "一杯溫熱的草茶，恢復 %d 體力。" % restored}

func ingredient_count(ingredient: Dictionary) -> int:
	if ingredient["stock"]=="ranch": return int(ranch["stock"].get(ingredient["item"],0))
	if ingredient["stock"] == "eggs":
		return eggs
	return int(get(ingredient["stock"]).get(ingredient["item"], 0))

func can_cook(recipe: String) -> bool:
	if area_id != "house" or not COOKING.RECIPES.has(recipe) or meals.get(recipe, 0) >= COOKING.MAX_STOCK:
		return false
	for ingredient in COOKING.RECIPES[recipe]["ingredients"]:
		if ingredient_count(ingredient) < ingredient["amount"]:
			return false
	return true

func cook(recipe: String) -> Dictionary:
	if not can_cook(recipe):
		return {"ok": false, "text": "請到農舍爐灶備齊食材，並確認料理背包仍有空間。"}
	for ingredient in COOKING.RECIPES[recipe]["ingredients"]:
		if ingredient["stock"] == "eggs":
			eggs -= ingredient["amount"]
		elif ingredient["stock"]=="ranch":
			ranch["stock"][ingredient["item"]] -= ingredient["amount"]
		else:
			var stock: Dictionary = get(ingredient["stock"])
			stock[ingredient["item"]] -= ingredient["amount"]
	meals[recipe] = meals.get(recipe, 0) + 1
	return {"ok": true, "text": "做好了一份%s，已放入料理背包。" % COOKING.RECIPES[recipe]["name"]}

func eat_meal(recipe: String) -> Dictionary:
	if not COOKING.RECIPES.has(recipe) or meals.get(recipe, 0) < 1 or energy >= MAX_ENERGY:
		return {"ok": false, "text": "沒有這份料理，或體力已滿；先留到需要時吧。"}
	var restored := mini(int(COOKING.RECIPES[recipe]["energy"]), MAX_ENERGY - energy)
	meals[recipe] -= 1
	energy += restored
	return {"ok": true, "text": "享用了%s，恢復 %d 體力。" % [COOKING.RECIPES[recipe]["name"], restored]}

func build_dryer() -> Dictionary:
	if area_id != "farm" or rack_built:
		return {"ok": false, "text": "請回莊園建造；已建好的烘乾架不需重建。"}
	var cost: Dictionary = PROCESSING.BUILD_COST
	if materials["wood"] < cost["wood"] or materials["stone"] < cost["stone"] or money < cost["money"]:
		return {"ok": false, "text": "需要木材 4、石料 2 與 60 銀。"}
	materials["wood"] -= cost["wood"]
	materials["stone"] -= cost["stone"]
	money -= cost["money"]
	rack_built = true
	return {"ok": true, "text": "烘乾架建好了！放入收成，睡一晚後回來領取。"}

func start_processing(recipe: String, amount: int = 1) -> Dictionary:
	if area_id != "farm" or not rack_built:
		return {"ok": false, "text": "請到莊園建好的烘乾架操作。"}
	if not processing_job.is_empty():
		return {"ok": false, "text": "架上已有一批作物，領取後才能再次加工。"}
	if not PROCESSING.RECIPES.has(recipe) or amount not in [1, 3]:
		return {"ok": false, "text": "每次可放入一份或三份相同作物。"}
	var crop: String = PROCESSING.RECIPES[recipe]["crop"]
	if produce.get(crop, 0) < amount:
		return {"ok": false, "text": "收成不足，種子不能當作加工原料。"}
	if goods.get(recipe, 0) > PROCESSING.MAX_STOCK - amount:
		return {"ok": false, "text": "成品已放滿，先去出貨吧。"}
	produce[crop] -= amount
	processing_job = {"recipe": recipe, "amount": amount, "ready_day": day + 1}
	return {"ok": true, "text": "放入 %d 份%s，明早可領取。" % [amount, CROPS[crop]["name"]]}

func processing_ready() -> bool:
	return not processing_job.is_empty() and day >= processing_job["ready_day"]

func collect_processing() -> Dictionary:
	if area_id != "farm" or not processing_ready():
		return {"ok": false, "text": "成品還沒準備好，睡一晚後到烘乾架領取。"}
	var recipe: String = processing_job["recipe"]
	var amount: int = processing_job["amount"]
	if goods.get(recipe, 0) > PROCESSING.MAX_STOCK - amount:
		return {"ok": false, "text": "成品已放滿；架上的這批會保留，先去出貨吧。"}
	goods[recipe] = goods.get(recipe, 0) + amount
	processing_job = {}
	return {"ok": true, "text": "領取了 %d 份%s，可到出貨箱出售。" % [amount, PROCESSING.RECIPES[recipe]["name"]]}

func daily_request_id() -> String:
	return REQUESTS.ORDER[(day - 1) % REQUESTS.ORDER.size()]

func accept_request() -> Dictionary:
	if area_id != "town" or active_request != "" or request_completed_day == day:
		return {"ok": false, "text": "請到鎮上公告牌接單；同時只能接一件，每天最多完成一件。"}
	active_request = daily_request_id()
	return {"ok": true, "text": "已接下「%s」，備齊後找%s交付。不必今天完成。" % [REQUESTS.REQUESTS[active_request]["title"], REQUESTS.REQUESTS[active_request]["resident"]]}

func cancel_request() -> Dictionary:
	if area_id != "town" or active_request == "":
		return {"ok": false, "text": "目前沒有可放棄的委託。"}
	active_request = ""
	return {"ok": true, "text": "已放棄委託，行囊物品保持原樣。"}

func can_deliver_request(recipient: String) -> bool:
	if area_id != "town" or active_request == "" or request_completed_day == day:
		return false
	var request: Dictionary = REQUESTS.REQUESTS[active_request]
	if request["recipient"] != recipient:
		return false
	var stocks := {"produce": produce, "materials": materials, "goods": goods}
	for category in stocks:
		for item in request[category]:
			if stocks[category][item] < request[category][item]:
				return false
	return true

func deliver_request(recipient: String) -> Dictionary:
	if not can_deliver_request(recipient):
		return {"ok": false, "text": "請確認物品足夠，並找到委託本人交付。"}
	var request: Dictionary = REQUESTS.REQUESTS[active_request]
	var stocks := {"produce": produce, "materials": materials, "goods": goods}
	for category in stocks:
		for item in request[category]:
			stocks[category][item] -= request[category][item]
	money += request["reward"]
	friendship += request["friendship"]
	requests_completed += 1
	request_completed_day = day
	active_request = ""
	return {"ok": true, "text": "%s收下了物品，獲得 %d 銀。%s" % [request["resident"], request["reward"], "青禾好感 +1。" if request["friendship"] > 0 else "謝謝你替小鎮搭把手。"]}

func tea_event_available() -> bool:
	return friendship >= 3 and not tea_event_seen

func finish_tea_event() -> Dictionary:
	if area_id != "town" or not tea_event_available():
		return {"ok": false, "text": "這段相識已記在手札，或尚未到赴約的時候。"}
	if materials["herb"] > 100000000 - 2:
		return {"ok": false, "text": "香草已放滿，整理行囊後再來赴約吧。"}
	tea_event_seen = true
	materials["herb"] += 2
	friendship += 1
	return {"ok": true, "text": "記下了窗邊茶會。霧香草 +2，青禾好感 +1；可在農舍手札重讀。"}

func build_coop() -> Dictionary:
	if area_id != "farm" or coop_built:
		return {"ok": false, "text": "請到莊園建造；雞舍只需建造一次。"}
	var cost: Dictionary = LIVESTOCK.BUILD_COST
	if materials["wood"] < cost["wood"] or materials["stone"] < cost["stone"] or money < cost["money"]:
		return {"ok": false, "text": "需要木材 8、石料 6 與 100 銀。"}
	materials["wood"] -= cost["wood"]
	materials["stone"] -= cost["stone"]
	money -= cost["money"]
	coop_built = true
	return {"ok": true, "text": "雞舍建好了！可購買母雞，用小麥收成餵食。"}

func buy_chicken() -> Dictionary:
	if area_id != "farm" or not coop_built or chickens >= LIVESTOCK.MAX_CHICKENS:
		return {"ok": false, "text": "請先建雞舍，最多可飼養三隻母雞。"}
	if money < LIVESTOCK.CHICKEN_PRICE:
		return {"ok": false, "text": "購買一隻母雞需要 80 銀。"}
	money -= LIVESTOCK.CHICKEN_PRICE
	chickens += 1
	return {"ok": true, "text": "母雞來到了莊園。今天餵食，明早就能收蛋。"}

func can_feed_chickens() -> bool:
	var remaining: int = chickens - fed_chickens
	return area_id == "farm" and coop_built and remaining > 0 and produce["wheat"] >= remaining and nest_eggs + chickens <= LIVESTOCK.NEST_CAPACITY

func feed_chickens() -> Dictionary:
	if area_id != "farm" or not coop_built or chickens == 0:
		return {"ok": false, "text": "先到雞舍購買母雞，再來餵食。"}
	var remaining: int = chickens - fed_chickens
	if remaining <= 0:
		return {"ok": false, "text": "今天每隻母雞都吃飽了，不必重複餵食。"}
	if nest_eggs + chickens > LIVESTOCK.NEST_CAPACITY:
		return {"ok": false, "text": "巢箱快滿了，請先領蛋，替明天預留空位。"}
	if produce["wheat"] < remaining:
		return {"ok": false, "text": "還需要 %d 份小麥收成；種子不能當飼料。" % remaining}
	produce["wheat"] -= remaining
	fed_chickens = chickens
	return {"ok": true, "text": "餵好了 %d 隻母雞，明早會有 %d 顆新鮮雞蛋。" % [remaining, fed_chickens]}

func collect_eggs() -> Dictionary:
	if area_id != "farm" or not coop_built or nest_eggs <= 0:
		return {"ok": false, "text": "巢箱裡還沒有蛋；餵食後睡一晚再來吧。"}
	if eggs > LIVESTOCK.MAX_EGGS - nest_eggs:
		return {"ok": false, "text": "雞蛋已放滿行囊；巢箱會保留，先去出貨吧。"}
	var amount: int = nest_eggs
	eggs += amount
	nest_eggs = 0
	return {"ok": true, "text": "領取雞蛋 %d 顆，每顆可出貨 %d 銀。" % [amount, LIVESTOCK.EGG_PRICE]}

func can_restore_route() -> bool:
	var cost: Dictionary = EXPLORATION.ROUTE_COST
	return area_id == "forest" and not route_restored and requests_completed >= cost["requests"] and materials["wood"] >= cost["wood"] and materials["stone"] >= cost["stone"] and money >= cost["money"]

func restore_route() -> Dictionary:
	if not can_restore_route():
		return {"ok": false, "text": "請到林地東側；完成居民委託 2 件，備齊木材 6、石料 4 與 160 銀。"}
	materials["wood"] -= EXPLORATION.ROUTE_COST["wood"]
	materials["stone"] -= EXPLORATION.ROUTE_COST["stone"]
	money -= EXPLORATION.ROUTE_COST["money"]
	route_restored = true
	return {"ok": true, "text": "舊驛路重新通行了。沿東邊道路，去看看遺落的故事吧。"}

func recover_relic() -> Dictionary:
	if area_id != "ruins" or not route_restored or relic_recovered:
		return {"ok": false, "text": "請先重開驛路，再到舊驛站查看石台；殘片只能收藏一次。"}
	for crop in CROP_ORDER:
		if seeds[crop] > 100000000 - EXPLORATION.RELIC_SEEDS:
			return {"ok": false, "text": "種子已放滿，整理行囊後再來收好這份發現。"}
	for crop in CROP_ORDER:
		seeds[crop] += EXPLORATION.RELIC_SEEDS
	money += EXPLORATION.RELIC_MONEY
	relic_recovered = true
	return {"ok": true, "text": "星紋殘片記入手札；獲得八種春季種子各 3 包與 120 銀。"}

func craft_fishing_rod() -> Dictionary:
	if not FISHING.GROUNDS.has(area_id) or fishing_rod or (area_id == "ruins" and not route_restored):
		return {"ok": false, "text": "請到釣點製作，魚竿只需製作一次。"}
	var cost: Dictionary = FISHING.ROD_COST
	if materials["wood"] < cost["wood"] or materials["stone"] < cost["stone"] or money < cost["money"]:
		return {"ok": false, "text": "需要木材 4、石料 2 與 80 銀。"}
	materials["wood"] -= cost["wood"]
	materials["stone"] -= cost["stone"]
	money -= cost["money"]
	fishing_rod = true
	return {"ok": true, "text": "魚竿做好了！等待浮標下沉，再按收線。"}

func can_begin_fishing() -> bool:
	if (area_id == "ruins" and not route_restored) or not fishing_rod or not FISHING.GROUNDS.has(area_id) or _fishing_pending or energy < FISHING.ENERGY_COST or fish_caught_today >= FISHING.DAILY_LIMIT:
		return false
	return fish[FISHING.GROUNDS[area_id]["fish"]] < FISHING.MAX_STOCK

func begin_fishing() -> Dictionary:
	if not can_begin_fishing():
		return {"ok": false, "text": "請確認魚竿、釣點與體力；每天最多收穫三尾，行囊也要有空位。"}
	energy -= FISHING.ENERGY_COST
	_fishing_pending = true
	_fishing_area = area_id
	return {"ok": true, "text": "投竿了。浮標下沉時按收線；提早或太晚都會讓魚游走。"}

func cancel_fishing() -> void:
	_fishing_pending = false
	_fishing_area = ""

func finish_fishing(caught: bool) -> Dictionary:
	if not _fishing_pending:
		return {"ok": false, "text": "這次投竿已經結束。"}
	var origin := _fishing_area
	cancel_fishing()
	if not caught or area_id != origin:
		return {"ok": false, "text": "魚游走了。下次等浮標下沉，再及時收線吧。"}
	var species: String = FISHING.GROUNDS[origin]["fish"]
	if fish_caught_today >= FISHING.DAILY_LIMIT or fish[species] >= FISHING.MAX_STOCK:
		return {"ok": false, "text": "今天魚獲或行囊已滿，這次不再領取。"}
	fish[species] += 1
	fish_caught_today += 1
	return {"ok": true, "text": "釣到了%s！可出貨 %d 銀，今日魚獲 %d / 3。" % [FISHING.FISH[species]["name"], FISHING.FISH[species]["price"], fish_caught_today]}

func sleep() -> void:
	JOURNEY.mark(self,"rest")
	if life["irrigator"]:
		for i in range(2):
			if plots[i]["crop"]!="": plots[i]["watered"] = true
	RANCH.advance(self)
	cancel_fishing()
	fish_caught_today = 0
	nest_eggs += fed_chickens
	fed_chickens = 0
	for p in plots:
		if p["crop"] != "" and p["watered"]:
			p["growth"] = mini(p["growth"] + (2 if JOURNEY.season(day)=="夏" and day%3==0 and p["crop"] in ["berry","potato","tea"] else 1), CROPS[p["crop"]]["days"])
	gathered.clear()
	day += 1
	if day >= 29:
		spring_progress["spring_complete"] = true
	minute = 420.0
	energy = MAX_ENERGY
	talked_today = false
	area_id = "house"
	player_position = Vector2(296, 120)
	for p in plots:
		p["watered"] = is_raining() and p["tilled"]

func to_data() -> Dictionary:
	return {
		"journey": journey.duplicate(true),
		"life": life.duplicate(true), "ranch": ranch.duplicate(true), "hero_style":hero_style,
		"version": SAVE_VERSION, "day": day, "minute": minute, "money": money,
		"energy": energy, "seeds": STOCKS.normalized(seeds, CROP_ORDER), "produce": STOCKS.normalized(produce, CROP_ORDER),
		"plots": plots.duplicate(true), "harvested": harvested, "total_earned": total_earned,
		"reward_claimed": reward_claimed, "talked_today": talked_today,
		"friendship": friendship, "player": [player_position.x, player_position.y],
		"area": area_id, "materials": materials.duplicate(),
		"gathered": gathered.keys(), "fence_repaired": fence_repaired,
		"rack_built": rack_built, "goods": STOCKS.normalized(goods, PROCESSING.ORDER), "processing_job": processing_job.duplicate(),
		"active_request": active_request, "request_completed_day": request_completed_day,
		"requests_completed": requests_completed, "tea_event_seen": tea_event_seen,
		"coop_built": coop_built, "chickens": chickens, "fed_chickens": fed_chickens,
		"nest_eggs": nest_eggs, "eggs": eggs,
		"route_restored": route_restored, "relic_recovered": relic_recovered,
		"fishing_rod": fishing_rod, "fish": fish.duplicate(), "fish_caught_today": fish_caught_today,
		"meals": STOCKS.normalized(meals, COOKING.ORDER), "spring_progress": spring_progress.duplicate(true),
	}

func _valid_data(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != SAVE_VERSION:
		return false
	if not data.get("area", "farm") is String or data.get("area", "farm") not in ["farm", "house", "town", "forest", "ruins", "ranch_poultry", "ranch_meadow", "ranch_silk", "ranch_spring", "culture_grove", "culture_ember", "culture_sanctuary", "culture_market"]:
		return false
	if not data.get("fence_repaired", false) is bool:
		return false
	var stock: Variant = data.get("materials", {"wood": 0, "stone": 0, "herb": 0})
	if not stock is Dictionary:
		return false
	for kind in FORAGE.ORDER:
		var count: Variant = stock.get(kind)
		if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > 100000000 or count != int(count):
			return false
	var collected: Variant = data.get("gathered", [])
	if not collected is Array or collected.size() > FORAGE.NODES.size():
		return false
	var seen := {}
	for node_id in collected:
		if not node_id is String or not FORAGE.NODES.has(node_id) or seen.has(node_id):
			return false
		seen[node_id] = true
	for key in ["day", "minute", "money", "energy", "harvested", "total_earned", "friendship"]:
		if not (data.get(key) is float or data.get(key) is int):
			return false
		if not is_finite(float(data[key])) or float(data[key]) < 0:
			return false
	if data["day"] < 1 or data["day"] > 1000000 or data["energy"] > MAX_ENERGY or data["minute"] < 420 or data["minute"] > 1320:
		return false
	for key in ["day", "money", "energy", "harvested", "total_earned", "friendship"]:
		if data[key] != int(data[key]) or data[key] > 1000000000000:
			return false
	if not data.get("route_restored", false) is bool or not data.get("relic_recovered", false) is bool:
		return false
	if (data.get("area", "farm") == "ruins" or data.get("relic_recovered", false)) and not data.get("route_restored", false):
		return false
	if not data.get("coop_built",false) is bool:
		return false
	if data.get("hero_style","male") not in ["male","female"] or not RANCH.valid(data.get("ranch",RANCH.empty()),int(data["day"]),data.get("coop_built",false)):
		return false
	if not LIFE.valid(data.get("life",LIFE.empty()),int(data["day"])):
		return false
	for resident in RANCH_DATA.VISITORS:
		if data.get("life",LIFE.empty())["events"][resident] and data.get("ranch",RANCH.empty())["friends"][resident]<3:
			return false
	if not _valid_meals(data) or not _valid_fishing(data):
		return false
	if not _valid_livestock(data):
		return false
	if not _valid_requests(data):
		return false
	if not _valid_processing(data):
		return false
	for key in ["reward_claimed", "talked_today"]:
		if not data.get(key) is bool:
			return false
	for key in ["seeds", "produce"]:
		if not STOCKS.valid(data.get(key), CROP_ORDER, CROP_DATA.LEGACY):
			return false
	if not SPRING.valid(data.get("spring_progress", SPRING.empty_progress()), data):
		return false
	if not JOURNEY.valid(data.get("journey",JOURNEY.empty()),data):
		return false
	if not data.get("plots") is Array or data["plots"].size() != COLS * ROWS:
		return false
	for p in data["plots"]:
		if not p is Dictionary or not p.get("tilled") is bool or not p.get("watered") is bool:
			return false
		if not p.get("crop") is String or (p["crop"] != "" and not CROPS.has(p["crop"])):
			return false
		var growth: Variant = p.get("growth")
		if not (growth is float or growth is int) or not is_finite(float(growth)) or growth != int(growth) or growth < 0 or growth > 6:
			return false
		if p["crop"] != "" and (not p["tilled"] or growth > CROPS[p["crop"]]["days"]):
			return false
	if not data.get("player") is Array or data["player"].size() != 2:
		return false
	for n in data["player"]:
		if not (n is int or n is float) or not is_finite(float(n)):
			return false
	return Rect2(8, 43, 464, 174).has_point(Vector2(data["player"][0], data["player"][1]))

func _valid_meals(data: Dictionary) -> bool:
	return STOCKS.valid(data.get("meals", {}), COOKING.ORDER, COOKING.LEGACY if data.has("meals") else [])

func _valid_fishing(data: Dictionary) -> bool:
	if not data.get("fishing_rod", false) is bool:
		return false
	var count: Variant = data.get("fish_caught_today", 0)
	if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > FISHING.DAILY_LIMIT or count != int(count):
		return false
	if count > 0 and not data.get("fishing_rod", false):
		return false
	var stored: Variant = data.get("fish", {"silver_carp": 0, "mist_trout": 0, "star_perch": 0})
	if not stored is Dictionary:
		return false
	for species in FISHING.ORDER:
		var value: Variant = stored.get(species)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > FISHING.MAX_STOCK or value != int(value):
			return false
	return true

func _valid_livestock(data: Dictionary) -> bool:
	if not data.get("coop_built", false) is bool:
		return false
	var limits := {"chickens": LIVESTOCK.MAX_CHICKENS, "fed_chickens": LIVESTOCK.MAX_CHICKENS, "nest_eggs": LIVESTOCK.NEST_CAPACITY, "eggs": LIVESTOCK.MAX_EGGS}
	for key in limits:
		var value: Variant = data.get(key, 0)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > limits[key] or value != int(value):
			return false
	var hens: int = int(data.get("chickens", 0))
	var fed: int = int(data.get("fed_chickens", 0))
	var nest: int = int(data.get("nest_eggs", 0))
	if fed > hens or nest + fed > LIVESTOCK.NEST_CAPACITY:
		return false
	if (not data.get("coop_built", false) or hens == 0) and (hens > 0 or fed > 0 or nest > 0):
		return false
	return true

func _valid_requests(data: Dictionary) -> bool:
	var active: Variant = data.get("active_request", "")
	if not active is String or (active != "" and not REQUESTS.REQUESTS.has(active)):
		return false
	for key in ["request_completed_day", "requests_completed"]:
		var value: Variant = data.get(key, 0)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > data["day"] or value != int(value):
			return false
	var completed_day: int = int(data.get("request_completed_day", 0))
	var completed: int = int(data.get("requests_completed", 0))
	if (completed_day == 0) != (completed == 0) or completed > completed_day or (completed_day == int(data["day"]) and active != ""):
		return false
	return data.get("tea_event_seen", false) is bool

func _valid_processing(data: Dictionary) -> bool:
	if not data.get("rack_built", false) is bool:
		return false
	if not STOCKS.valid(data.get("goods", {}), PROCESSING.ORDER, PROCESSING.LEGACY if data.has("goods") else []):
		return false
	var job: Variant = data.get("processing_job", {})
	if not job is Dictionary:
		return false
	if job.is_empty():
		return true
	if not data.get("rack_built", false) or job.size() != 3 or not job.get("recipe") is String or not PROCESSING.RECIPES.has(job["recipe"]):
		return false
	var amount: Variant = job.get("amount")
	var ready: Variant = job.get("ready_day")
	if not (amount is float or amount is int) or not is_finite(float(amount)) or amount != int(amount) or int(amount) not in [1, 3]:
		return false
	if not (ready is float or ready is int) or not is_finite(float(ready)) or ready != int(ready) or ready < 2 or ready > data["day"] + 1:
		return false
	return true

func _apply_data(data: Dictionary) -> void:
	day = int(data["day"])
	minute = float(data["minute"])
	money = int(data["money"])
	energy = int(data["energy"])
	seeds = STOCKS.normalized(data["seeds"], CROP_ORDER)
	produce = STOCKS.normalized(data["produce"], CROP_ORDER)
	for crop in CROP_ORDER:
		seeds[crop] = int(seeds[crop])
		produce[crop] = int(produce[crop])
	plots = data["plots"].duplicate(true)
	for p in plots:
		p["growth"] = int(p["growth"])
	harvested = int(data["harvested"])
	total_earned = int(data["total_earned"])
	reward_claimed = data["reward_claimed"]
	talked_today = data["talked_today"]
	friendship = int(data["friendship"])
	player_position = Vector2(data["player"][0], data["player"][1])
	area_id = data.get("area", "farm")
	materials = data.get("materials", {"wood": 0, "stone": 0, "herb": 0}).duplicate()
	for kind in FORAGE.ORDER:
		materials[kind] = int(materials[kind])
	gathered.clear()
	for node_id in data.get("gathered", []):
		gathered[node_id] = true
	fence_repaired = data.get("fence_repaired", false)
	active_request = data.get("active_request", "")
	request_completed_day = int(data.get("request_completed_day", 0))
	requests_completed = int(data.get("requests_completed", 0))
	tea_event_seen = data.get("tea_event_seen", false)
	coop_built = data.get("coop_built", false)
	chickens = int(data.get("chickens", 0))
	fed_chickens = int(data.get("fed_chickens", 0))
	nest_eggs = int(data.get("nest_eggs", 0))
	eggs = int(data.get("eggs", 0))
	route_restored = data.get("route_restored", false)
	relic_recovered = data.get("relic_recovered", false)
	fishing_rod = data.get("fishing_rod", false)
	fish = data.get("fish", {"silver_carp": 0, "mist_trout": 0, "star_perch": 0}).duplicate()
	for species in FISHING.ORDER:
		fish[species] = int(fish[species])
	fish_caught_today = int(data.get("fish_caught_today", 0))
	meals = STOCKS.normalized(data.get("meals", {}), COOKING.ORDER)
	journey = JOURNEY.normalized(data.get("journey",JOURNEY.empty()))
	life = LIFE.normalized(data.get("life",LIFE.empty()))
	ranch = RANCH.normalized(data.get("ranch",RANCH.empty()))
	hero_style = data.get("hero_style","male")
	spring_progress = SPRING.normalized(data.get("spring_progress", SPRING.empty_progress()))
	for recipe in COOKING.ORDER:
		meals[recipe] = int(meals[recipe])
	cancel_fishing()
	rack_built = data.get("rack_built", false)
	goods = STOCKS.normalized(data.get("goods", {}), PROCESSING.ORDER)
	for recipe in PROCESSING.ORDER:
		goods[recipe] = int(goods[recipe])
	processing_job = data.get("processing_job", {}).duplicate()
	if not processing_job.is_empty():
		processing_job["amount"] = int(processing_job["amount"])
		processing_job["ready_day"] = int(processing_job["ready_day"])

func save_game(path: String = "user://farm_save.json") -> Error:
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_data(), "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	# Preserve the previous valid save before atomically replacing the primary.
	if FileAccess.file_exists(path):
		var old_data: Variant = _read_json(path)
		if _valid_data(old_data):
			var copy_error := DirAccess.copy_absolute(path, path + ".bak")
			if copy_error != OK:
				return copy_error
	return DirAccess.rename_absolute(temp_path, path)

func _read_json(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

func load_game(path: String = "user://farm_save.json") -> bool:
	load_notice = ""
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var data: Variant = _read_json(candidate)
		if _valid_data(data):
			_apply_data(data)
			if candidate != path:
				load_notice = "主存檔損壞，已讀取上一份備份。"
			return true
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		load_notice = "存檔無法讀取。原檔已保留；本次將不自動覆寫，請先備份後重新開始。"
	return false

func ship_with_reserve() -> Dictionary:
	if not journey["reserve"]: return sell_all()
	var retained := {}
	var sources := {"produce":produce,"goods":goods,"ranch":ranch["stock"],"craft":life["stock"],"fish":fish}
	for category in sources:
		retained[category]={}
		for id in sources[category]:
			var amount: int=mini(2,sources[category][id])
			retained[category][id]=amount
			sources[category][id]-=amount
	var saved_eggs := mini(2,eggs)
	eggs-=saved_eggs
	var result := sell_all()
	for category in sources:
		for id in sources[category]: sources[category][id]+=retained[category][id]
	eggs+=saved_eggs
	return result
