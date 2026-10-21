extends RefCounted

const STOCKS = preload("res://scripts/stock_rules.gd")
const CROPS = preload("res://scripts/crop_data.gd")
const RANCH = preload("res://scripts/ranch_data.gd")
const LIFE = preload("res://scripts/life_data.gd")
const PEOPLE := ["npc","shop","smith","edric","lyria","borin","yunji","suyue","qinglin"]
const NAMES := ["青禾","洛安","雷恩","艾德里克","莉莉雅","博林","雲霽","素月","青麟"]
const TASKS := ["water","rest","harvest","ship","seed"]
const TASK_TEXT := ["替田裡的一株作物澆水","進農舍點床，休息到明天","採收一份成熟作物","到出貨箱出售一份收成","在空田重新播種"]
const SLOTS := [Vector2(50,155),Vector2(54,181),Vector2(290,168),Vector2(432,154),Vector2(398,208),Vector2(58,208)]
const DECOR := ["空白","木圍欄","精靈燈罩","庭園小樹"]
const COSTS := [{},{"wood":2},{"stone":2,"wood":1},{"wood":1,"herb":2}]
const LIKES := {
	"npc":["produce:tea","life:honey_tea"],"shop":["produce:berry","life:star_lantern"],
	"smith":["materials:stone","life:jade_charm"],"edric":["produce:wheat","life:wool_blanket"],
	"lyria":["produce:tea","life:moon_cloth"],"borin":["materials:stone","life:wool_blanket"],
	"yunji":["materials:herb","life:jade_charm"],"suyue":["materials:herb","life:honey_tea"],
	"qinglin":["produce:berry","life:moon_cloth"]}
const GIFTS := ["produce:tea","produce:berry","produce:wheat","materials:herb","materials:stone",
	"life:moon_cloth","life:honey_tea","life:wool_blanket","life:jade_charm","life:star_lantern"]
const CLUES := [Vector2(205,152),Vector2(275,162),Vector2(419,187)]
const CLUE_TITLES := [["異鄉茶苗","月葉泉記","林居共栽碑"],["舊橋釘","冷卻水槽","雙語工匠印"],["清泉測石","藥田札記","靈脈水聲"],["東西商道圖","舊秤砣","共榮商約"]]
const CLUE_TEXT := [
	["東洲茶苗與西陸樹苗共用泉水，葉片各自舒展。","泉邊刻著兩種文字：取水的人，也替後來者留一瓢。","莉莉雅留下育苗記錄，請你以兩份香草替新苗遮護。"],
	["橋釘保留東洲榫口，外層卻是西陸符文的鑄紋。","水槽上刻著冷卻的次序，急著鍛打反而容易裂開。","博林希望以三份石料補好工作檯，讓兩地工匠共用。"],
	["白石記下泉水的高度，水位因雨季和晴日慢慢改變。","素月提醒旅人：藥草要留根，取用只取所需。","雲霽請你帶兩份香草與一尾銀鱗鯽，記錄水土是否安穩。"],
	["商道圖以驛站相接，城牆以外也有人照看旅途。","這把舊秤砣標著兩地單位，旁邊留著互相換算的刻痕。","艾德里克請你備木材三份、小麥一份，搭好旅人的歇腳桌。"]]
const QUEST_NEEDS := [["materials:herb",2],["materials:stone",3],["materials:herb",2],["materials:wood",3]]
const EVENT_LINES := [
	["青禾把你常坐的位子移到窗邊，問起今天田裡的新芽。","她把寫著你口味的茶單收進抽屜：下次回來，不必再開口。"],
	["洛安攤開遠方的商路圖，請你替莊園在圖上添一筆。","他替你的出貨留出一格帳頁，說這些收成也屬於雲橋的故事。"],
	["雷恩將磨好的工具放到你手邊，提起師父初學時的糗事。","鐘聲響起，他邀你一起檢查橋上的老鉚釘。工作也可以有人作伴。"],
	["艾德里克卸下護腕，和你沿橋檢查夜燈。","他將備用燈繩交給你：巡路不再只是自己的差事。"],
	["莉莉雅把東洲茶苗與精靈種子分給你看，請你為新苗選個名字。","她留下一只空育苗盒，希望明年也能和你一起播種。"],
	["博林收起錘子，讓你摸一摸已磨平的木槽邊緣。","他在工具架上留了你的位置，說慢慢學也不要緊。"],
	["雲霽不再趕著記遠山，而是坐下聽你說起莊園的日常。","竹卷新的一頁寫上雲橋。他說，停留也能是一段旅程。"],
	["素月拆開曬好的藥袋，教你辨認香草葉緣。","她替莊園留了一份換季照料札記，叮嚀你也要好好休息。"],
	["青麟帶你看林邊留下的蹄印，安靜等待鹿群走過。","你們把落葉堆回樹根，約好下次仍只帶走自然落下的禮物。"]]

static func empty() -> Dictionary:
	var v := {"tutorial":{},"layout":0,"decor":[0,0,0,0,0,0],"gifts":{},"events":{},"clues":[0,0,0,0],"quests":[false,false,false,false],"summer_cycle":0,"summer_offered":[],"summer_done":0,"reserve":false,"tool_level":0}
	for id in TASKS: v["tutorial"][id]=false
	for id in PEOPLE:
		v["gifts"][id]=0
		v["events"][id]=0
	return v

static func season(day: int) -> String:
	return "春" if ((day-1)/28)%2==0 else "夏"

static func year(day: int) -> int:
	return (day-1)/56+1

static func rain(day: int) -> bool:
	return day%4==0 if season(day)=="春" else ((day-29)%5==1 or (day-29)%5==2)

static func weather(day: int) -> String:
	if rain(day): return "細雨" if season(day)=="春" else "夏雨"
	return "暑晴" if season(day)=="夏" else "晴朗"

static func crop_price(s: RefCounted, id: String) -> int:
	var price: int=CROPS.CROPS[id]["price"]
	return price*6/5 if season(s.day)=="夏" and id in ["berry","potato","tea"] else price

static func mark(s: RefCounted, id: String) -> void:
	if id in TASKS: s.journey["tutorial"][id]=true

static func next_task(s: RefCounted) -> String:
	for id in TASKS:
		if not s.journey["tutorial"][id]: return id
	return ""

static func friendship(s: RefCounted, id: String) -> int:
	if id=="npc": return s.friendship
	if id in ["shop","smith"]: return s.spring_progress["friends"][id]
	return s.ranch["friends"].get(id,0)

static func stage(points: int) -> String:
	if points>=25: return "知心"
	if points>=10: return "信賴"
	if points>=3: return "熟識"
	return "初識"

static func near(s: RefCounted, id: String) -> bool:
	if id not in PEOPLE: return false
	if id in ["npc","shop","smith"]: return s.area_id=="town" and s.player_position.distance_to(s.RESIDENTS.position(id,s.minute,s.is_raining()))<52
	return s.area_id==RANCH.visitor_area(id,s.minute,s.is_raining()) and s.player_position.distance_to(RANCH.visitor_position(id,s.area_id,s.minute,s.is_raining()))<52

static func count(s: RefCounted, key: String) -> int:
	var parts := key.split(":")
	if parts.size()!=2: return 0
	if parts[0]=="life": return s.life["stock"].get(parts[1],0)
	var stock: Variant=s.get(parts[0]) if parts[0] in ["produce","materials","fish"] else {}
	return stock.get(parts[1],0)

static func item_name(key: String) -> String:
	var parts := key.split(":")
	if parts[0]=="produce": return CROPS.CROPS[parts[1]]["name"]
	if parts[0]=="materials": return {"herb":"霧香草","stone":"石料","wood":"木材"}[parts[1]]
	if parts[0]=="fish": return "銀鱗鯽"
	return LIFE.PRODUCTS[parts[1]]["name"]

static func take(s: RefCounted, key: String, amount: int) -> void:
	var parts := key.split(":")
	if parts[0]=="life": s.life["stock"][parts[1]]-=amount
	else: s.get(parts[0])[parts[1]]-=amount

static func result(ok: bool, message: String) -> Dictionary:
	return {"ok":ok,"text":message}

static func gift(s: RefCounted, id: String, item: String) -> Dictionary:
	if not near(s,id) or item not in GIFTS or s.journey["gifts"][id]==s.day or count(s,item)<1:
		return result(false,"請走近居民，準備禮物；每位居民每天收一份。")
	var points: int=2 if item in LIKES[id] else 1
	take(s,item,1)
	s.journey["gifts"][id]=s.day
	if id=="npc": s.friendship=mini(100000000,s.friendship+points)
	elif id in ["shop","smith"]: s.spring_progress["friends"][id]=mini(100000000,s.spring_progress["friends"][id]+points)
	else: s.ranch["friends"][id]=mini(100,s.ranch["friends"][id]+points)
	return result(true,"%s收下了%s，好感 +%d。%s" % [NAMES[PEOPLE.find(id)],item_name(item),points,"這是他喜歡的禮物。" if points==2 else "謝謝你記得我。"])

static func finish_event(s: RefCounted, id: String, tier: int) -> Dictionary:
	if tier not in [1,2] or not near(s,id) or s.journey["events"][id]!=tier-1 or friendship(s,id)<(10 if tier==1 else 25):
		return result(false,"關係條件尚未達成，或已收好這段回憶。")
	var reward := 80 if tier==1 else 150
	if s.money>1000000000000-reward: return result(false,"帳簿已滿，回憶會留待下次。")
	s.journey["events"][id]=tier
	s.money+=reward
	return result(true,"記下%s回憶，收到 %d 銀心意。" % ["信賴" if tier==1 else "知心",reward])

static func decorate(s: RefCounted, slot: int, kind: int) -> Dictionary:
	if s.area_id!="farm" or slot<0 or slot>=6 or kind<0 or kind>3 or s.journey["decor"][slot]==kind:
		return result(false,"請在莊園選擇不同的庭園配置。")
	if kind>0:
		for site in range(3):
			if s.estate["fixtures"][site]>0 and s.ESTATE.FOOTPRINTS[site].grow(5).has_point(SLOTS[slot]): return result(false,"這處已被設施占用，請另選裝飾位置。")
	for key in COSTS[kind]:
		if s.materials[key]<COSTS[kind][key]: return result(false,"素材不足；原配置已保留。")
	for key in COSTS[kind]: s.materials[key]-=COSTS[kind][key]
	s.journey["decor"][slot]=kind
	return result(true,"已放置"+DECOR[kind]+"；拆除與替換不退素材。")

static func inspect_clue(s: RefCounted, clue: int) -> Dictionary:
	var area: int=LIFE.AREAS.find(s.area_id)
	if area<0 or clue<0 or clue>2 or s.player_position.distance_to(CLUES[clue])>28: return result(false,"請走近聚落的記錄點。")
	s.journey["clues"][area] = s.journey["clues"][area] | (1<<clue)
	return result(true,CLUE_TEXT[area][clue])

static func quest(s: RefCounted, index: int) -> Dictionary:
	if index<0 or index>3 or s.area_id!=LIFE.AREAS[index] or s.journey["quests"][index] or s.journey["clues"][index]!=7:
		return result(false,"請先走訪本聚落的三處記錄點，再回工坊交付。")
	var need: Array=QUEST_NEEDS[index]
	if count(s,need[0])<need[1] or (index==2 and count(s,"fish:silver_carp")<1) or (index==3 and count(s,"produce:wheat")<1): return result(false,"交付物資尚未齊全，記錄會保留。")
	var reward := 80+index*10
	var cap_ok: bool=s.seeds["berry"]<=99999997 if index==0 else (s.ranch["feed"]<=99999990 if index==1 else (s.meals["star_tea"]<100000000 if index==2 else s.seeds["potato"]<=99999997))
	if s.money>1000000000000-reward or not cap_ok: return result(false,"行囊或帳簿已滿，先整理再交付。")
	take(s,need[0],need[1])
	if index==2: take(s,"fish:silver_carp",1)
	if index==3: take(s,"produce:wheat",1)
	s.money+=reward
	if index==0: s.seeds["berry"]+=3
	elif index==1: s.ranch["feed"]+=10
	elif index==2: s.meals["star_tea"]+=1
	else: s.seeds["potato"]+=3
	s.journey["quests"][index]=true
	return result(true,"聚落委託完成，收到 %d 銀與當地謝禮。" % reward)

static func summer_open(s: RefCounted) -> bool:
	return season(s.day)=="夏" and (s.day-1)%28+1>=14 and s.area_id=="town" and s.journey["summer_done"]!=year(s.day)

static func summer_donate(s: RefCounted, crop: String) -> Dictionary:
	if not summer_open(s) or crop not in CROPS.ORDER or s.produce[crop]<1: return result(false,"夏14至28日到鎮上，備妥三種不同作物參加星燈夜。")
	var current: bool=s.journey["summer_cycle"]==year(s.day)
	var offered: Array=s.journey["summer_offered"] if current else []
	if crop in offered or offered.size()>=3: return result(false,"這種作物已放上長桌，請準備其他種類。")
	if not current:
		s.journey["summer_cycle"]=year(s.day)
		s.journey["summer_offered"]=[]
	s.produce[crop]-=1
	s.journey["summer_offered"].append(crop)
	return result(true,"將%s放上夏夜長桌。" % CROPS.CROPS[crop]["name"])

static func summer_finish(s: RefCounted) -> Dictionary:
	if not summer_open(s) or s.journey["summer_cycle"]!=year(s.day) or s.journey["summer_offered"].size()!=3 or s.money>999999999850: return result(false,"請先在夏夜市集備齊三種收成。")
	s.journey["summer_done"]=year(s.day)
	s.money+=150
	return result(true,"星燈夜記入手札，收到 150 銀。兩地的燈影，在同一條河上相逢。")

static func valid(v: Variant, data: Dictionary) -> bool:
	if not v is Dictionary or v.size()!=empty().size(): return false
	for key in empty():
		if not v.has(key): return false
	if not v["tutorial"] is Dictionary or v["tutorial"].size()!=5: return false
	for id in TASKS:
		if not v["tutorial"].get(id) is bool: return false
	if not STOCKS.valid(v["gifts"],PEOPLE,PEOPLE,int(data["day"])) or not STOCKS.valid(v["events"],PEOPLE,PEOPLE,2): return false
	for id in PEOPLE:
		var points: int=int(data["friendship"]) if id=="npc" else int(data.get("spring_progress",{}).get("friends",{}).get(id,0) if id in ["shop","smith"] else data.get("ranch",{}).get("friends",{}).get(id,0))
		if v["events"][id]>0 and points<(10 if v["events"][id]==1 else 25): return false
	if not number(v["layout"],2) or not number(v["tool_level"],1) or not v["reserve"] is bool: return false
	for key in ["decor","clues","quests"]:
		if not v[key] is Array or v[key].size()!=(6 if key=="decor" else 4): return false
	for item in v["decor"]:
		if not number(item,3): return false
	for i in range(4):
		if not number(v["clues"][i],7) or not v["quests"][i] is bool or (v["quests"][i] and v["clues"][i]!=7): return false
	for key in ["summer_cycle","summer_done"]:
		if not number(v[key],year(int(data["day"]))): return false
	if not v["summer_offered"] is Array or v["summer_offered"].size()>3: return false
	var seen := {}
	for id in v["summer_offered"]:
		if id not in CROPS.ORDER or seen.has(id): return false
		seen[id]=true
	if not seen.is_empty() and v["summer_cycle"]==0: return false
	if (v["summer_cycle"]==year(int(data["day"])) and not seen.is_empty()) or v["summer_done"]==year(int(data["day"])):
		if (int(data["day"])-1)%56+1<42: return false
	if v["summer_done"]>v["summer_cycle"] or (v["summer_done"]>0 and v["summer_done"]==v["summer_cycle"] and seen.size()!=3): return false
	return true

static func number(value: Variant, cap: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=0 and value<=cap

static func normalized(v: Dictionary) -> Dictionary:
	var result := v.duplicate(true)
	for key in ["layout","summer_cycle","summer_done","tool_level"]: result[key]=int(result[key])
	for key in ["decor","clues"]:
		for i in range(result[key].size()): result[key][i]=int(result[key][i])
	for key in ["gifts","events"]:
		for id in PEOPLE: result[key][id]=int(result[key][id])
	return result

static func upgrade_tool(s: RefCounted) -> Dictionary:
	if s.area_id!="farm" or s.journey["tool_level"]!=0 or s.money<180 or s.materials["wood"]<8 or s.materials["stone"]<6:
		return result(false,"請在莊園準備180銀、木材8、石料6；工具只升級一次。")
	s.money-=180
	s.materials["wood"]-=8
	s.materials["stone"]-=6
	s.journey["tool_level"]=1
	return result(true,"水壺已調校，每次澆水體力由2降為1。")
