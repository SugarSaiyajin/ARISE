extends RefCounted

const JOURNEY = preload("res://scripts/journey_rules.gd")
const RANCH = preload("res://scripts/ranch_data.gd")
const LIFE = preload("res://scripts/life_data.gd")
const SITES := [Vector2(48,156),Vector2(405,207),Vector2(285,151)]
const FOOTPRINTS := [Rect2(30,144,36,16),Rect2(384,193,38,14),Rect2(275,139,20,16)]
const ANCHORS := [Vector2(48,174),Vector2(405,214),Vector2(298,163)]
const SITE_NAMES := ["住宅西側","茶亭南側","田區東緣"]
const FACILITIES := ["空地","分流水槽","照料工作檯","保鮮貨架"]
const COSTS := [{},{"wood":8,"stone":6,"money":140},{"wood":6,"stone":3,"money":90},{"wood":8,"stone":4,"money":120}]
const GOAL_NAMES := ["初成田園","生靈相伴","雲橋熟客","工藝日常","四方行旅","夏日共榮"]
const GOAL_TEXT := ["累計採收12份","擁有3種動物，累計照料12次","完成3件委託，3位居民好感達3","領取5件聚落工藝品","完成四聚落探索委託","累計完成4件夏季週委託並參加星燈夜"]
const GOAL_REWARDS := [100,150,180,220,250,300]
const ACTIVITY_LINES := [
	["青禾和你整理茶種，把來年要種的品種寫在紙上。","青禾帶你沿河走了一段，說起第一次聞到異鄉茶香的日子。"],
	["洛安教你核對種子袋上的兩地記號，帳冊上多了你的註解。","洛安與你比對驛路地圖，圈出商旅常停留的樹蔭。"],
	["雷恩和你磨平工具柄，提醒你手感比裝飾更重要。","雷恩陪你檢查橋釘，說起師父如何聽出金屬的裂痕。"],
	["艾德里克幫你整理穀物，卸下護腕後動作仍有些拘謹。","艾德里克與你查看橋頭夜燈，約好替晚歸的人留一盞光。"],
	["莉莉雅和你分裝新苗，為東西兩地的種子各留了一格。","莉莉雅帶你認識林邊的幼樹，不同的葉子共享一片樹蔭。"],
	["博林替工作檯換好木楔，邀你試試穩不穩。","博林和你量過橋邊水槽，草圖上留下兩個人的字。"],
	["雲霽教你整理草木札記，先記名字，再記相遇的地方。","雲霽陪你聽泉水，這次沒有急著趕下一段路。"],
	["素月和你把香草攤開，教你留下根部再採新葉。","素月帶你看屋簷下避雨的小生靈，提醒你輕一點走。"],
	["青麟和你清理育苗盆，把落葉重新覆在根旁。","青麟與你沿林緣行走，留下鹿群熟悉的小路。"]]
const DAILY_STAGES := [
	["我是青禾，茶館裡總留著一壺熱水。","你常坐的位子，我替你留著。","茶種的事，想聽聽你的主意。","你回來時，茶香也像有了方向。"],
	["種子上都有價目，慢慢挑就好。","你來了，今天的種子剛分裝完。","遠路的帳簿，想和你一起看看。","莊園那一頁，我已留在帳冊前頭。"],
	["工具用壞了，拿來看看再說。","你用工具的習慣，我慢慢記住了。","這枚舊鐘片，交給你聽聽聲音。","有你幫手，這座工坊不只剩錘聲。"],
	["橋頭路窄，行走時留意商隊。","你出門的時候，我會多看一眼橋路。","今晚的巡路，願意和我走一段嗎？","在雲橋卸下護腕，也能覺得安心。"],
	["幼苗怕踩，請沿樹蔭走。","你帶來的茶苗，新葉已經展開了。","這份育苗記錄，想和你一起完成。","明年的種子，也替你留一小盒。"],
	["工作檯旁有木刺，先別急著碰。","你上次磨的木楔，裝得很牢。","有件新工具，想聽聽你實際用過的感覺。","工坊裡的位置，你隨時都能用。"],
	["山路很長，走累了就先停一停。","你的莊園，已經記進我的竹卷。","這頁空白，想留給你說的故事。","我想再住一季，和你慢慢看雲橋。"],
	["藥草剛曬好，別急著全收起來。","你的腳步聲，我在屋簷下就聽見了。","香草的分法，今天想教你完整記下來。","這只藥袋是留給你的，照料自己也要用心。"],
	["鹿群還在林邊，先安靜等一等。","牠們不再躲著你的腳步了。","這處新芽，想請你一起照看。","你熟悉的這條路，山林也會記得。"]]
const DAILY_TOPICS := [
	["新茶要先溫杯，別急著入口。","今天的茶味淡一些，適合配點麵包。","窗邊的苗又長了一片小葉。"],
	["東洲的種袋，繩結和西陸不太一樣。","留一份收成給委託，別一次全出貨。","商隊說，驛路邊又有人擺攤了。"],
	["先磨平握柄，做工才不會傷手。","雨天要把工具擦乾再收。","修補舊物，也能看見從前的手藝。"],
	["橋頭的夜燈，白天也要檢查燈繩。","盾放下來，雙手才能幫忙搬穀物。","今天的商旅都平安過橋了。"],
	["不同葉子，需要的日照也不同。","蜂群喜歡這片安靜的花圃。","取一瓢泉水，也記得替新苗留一點。"],
	["好的木槽，邊緣一定要磨圓。","符文能省力，細心可不能省。","今天先修農具，錘聲也會輕一些。"],
	["泉水的回聲，每天都不太一樣。","記下人名，有時比記下遠山更重要。","不趕路的日子，也能遇見新風景。"],
	["採香草時留下根，明天才有新葉。","換季的藥袋，要重新檢查是否受潮。","棚下有清水，走累了就來坐坐。"],
	["自然落下的玉角，才是山林的贈禮。","落葉留在根旁，也能照料新芽。","今天不拾取什麼，只看鹿群走過也很好。"]]
const SUMMER_NEEDS := ["produce:berry","materials:stone","materials:herb","produce:potato"]
const SUMMER_AMOUNTS := [1,2,2,1]
const SUMMER_REWARDS := [70,45,40,80]

static func empty() -> Dictionary:
	var value := {"fixtures":[0,0,0],"care_total":0,"craft_total":0,"milestones":[false,false,false,false,false,false],"activities":{},"choices":{},"summer_jobs":{},"summer_completed":0}
	for id in JOURNEY.PEOPLE:
		value["activities"][id]=0
		value["choices"][id]=0
	for area in LIFE.AREAS: value["summer_jobs"][area]=0
	return value

static func clone(s: RefCounted) -> RefCounted:
	var copy: RefCounted=s.get_script().new()
	copy._apply_data(s.to_data())
	return copy

static func fingerprint(s: RefCounted) -> String:
	return JSON.stringify(s.to_data()).sha256_text()

static func has_facility(s: RefCounted, kind: int) -> bool:
	return kind in s.estate["fixtures"]

static func field_targets(s: RefCounted, tool: String) -> Array[int]:
	var result: Array[int]=[]
	if s.area_id!="farm": return result
	for i in range(s.plots.size()):
		var p: Dictionary=s.plots[i]
		if (tool=="water" and p["crop"]!="" and not p["watered"]) or (tool=="harvest" and s.is_mature(p)):
			result.append(i)
	return result

static func crop_status(s: RefCounted) -> Dictionary:
	var result := {"planted":0,"dry":0,"mature":0,"empty":0}
	for p in s.plots:
		if p["crop"]=="": result["empty"]+=1
		else:
			result["planted"]+=1
			if not p["watered"]: result["dry"]+=1
			if s.is_mature(p): result["mature"]+=1
	return result

static func ranch_targets(s: RefCounted, action: String) -> Array[String]:
	var result: Array[String]=[]
	if action not in ["feed","care","collect"]: return result
	for id in RANCH.ORDER:
		if s.area_id!=("farm" if id=="hen" and s.area_id=="farm" else RANCH.AREAS[RANCH.SPECIES[id]["home"]]): continue
		if id=="hen":
			if action=="feed" and s.chickens>s.fed_chickens: result.append(id)
			elif action=="collect" and s.nest_eggs>0: result.append(id)
		else:
			var animal: Dictionary=s.ranch["animals"][id]
			if not animal["owned"]: continue
			if (action=="feed" and not animal["fed"]) or (action=="care" and not animal["cared"]) or (action=="collect" and animal["ready"]>0): result.append(id)
	return result

static func ranch_plan(s: RefCounted, action: String) -> Dictionary:
	var copy := clone(s)
	var ids := ranch_targets(copy,action)
	if ids.is_empty(): return {"ok":false,"text":"本地沒有待處理項目。"}
	for id in ids:
		var result: Dictionary
		if id=="hen" and copy.area_id=="farm": result=copy.feed_chickens() if action=="feed" else copy.collect_eggs()
		else: result=copy.RANCH.call(action,copy,id)
		if not result["ok"]: return {"ok":false,"text":RANCH.SPECIES[id]["name"]+"："+result["text"]}
	return {"ok":true,"text":"已準備處理%d項。" % ids.size(),"ids":ids,"data":copy.to_data(),"guard":fingerprint(s),"energy":s.energy-copy.energy,"feed":s.ranch["feed"]-copy.ranch["feed"],"wheat":s.produce["wheat"]-copy.produce["wheat"]}

static func ranch_apply(s: RefCounted, action: String, guard: String) -> Dictionary:
	if guard!=fingerprint(s): return JOURNEY.result(false,"進度已有變動，請重新查看照料清單。")
	var plan := ranch_plan(s,action)
	if not plan["ok"]: return plan
	s._apply_data(plan["data"])
	return {"ok":true,"text":"已完成本地%d項照料；成功項目不會重複結算。" % plan["ids"].size(),"ids":plan["ids"]}

static func shipping_plan(s: RefCounted) -> Dictionary:
	var copy := clone(s)
	var before: Dictionary=copy.to_data()
	var result: Dictionary=copy.ship_with_reserve()
	var lines: Array=[]
	if result["ok"]:
		for id in s.CROP_ORDER:
			var amount: int=s.produce.get(id,0)-copy.produce.get(id,0)
			if amount>0: lines.append({"name":s.CROPS[id]["name"],"amount":amount})
		for id in s.PROCESSING.ORDER:
			var amount: int=s.goods.get(id,0)-copy.goods.get(id,0)
			if amount>0: lines.append({"name":s.PROCESSING.RECIPES[id]["name"],"amount":amount})
		for id in RANCH.EXTRA:
			var amount: int=s.ranch["stock"][id]-copy.ranch["stock"][id]
			if amount>0: lines.append({"name":RANCH.SPECIES[id]["product"],"amount":amount})
		for id in LIFE.GOODS:
			var amount: int=s.life["stock"][id]-copy.life["stock"][id]
			if amount>0: lines.append({"name":LIFE.PRODUCTS[id]["name"],"amount":amount})
		for id in s.FISHING.ORDER:
			var amount: int=s.fish[id]-copy.fish[id]
			if amount>0: lines.append({"name":s.FISHING.FISH[id]["name"],"amount":amount})
		if s.eggs>copy.eggs: lines.append({"name":"雞蛋","amount":s.eggs-copy.eggs})
	return {"ok":result["ok"],"text":result["text"],"guard":fingerprint(s),"lines":lines,"earnings":copy.money-int(before["money"])}

static func ship(s: RefCounted, guard: String) -> Dictionary:
	if guard!=fingerprint(s) or s.area_id!="farm": return JOURNEY.result(false,"進度已變動或不在莊園，請重新確認出貨。")
	return s.ship_with_reserve()

static func facility_reason(s: RefCounted, site: int, kind: int) -> String:
	if s.area_id!="farm" or site<0 or site>2 or kind<0 or kind>3: return "請回莊園選擇施工位置。"
	if s.estate["fixtures"][site]!=0 and kind!=0: return "此位置已有設施，請先拆除。"
	if kind>0 and FOOTPRINTS[site].grow(3).has_point(s.player_position): return "請先走出施工範圍，再確認建造。"
	if kind==0: return "" if s.estate["fixtures"][site]!=0 else "此處已是空地。"
	if kind==1 and not s.life["irrigator"]: return "先向聚落工坊製作並安裝符玉灌溉器。"
	if has_facility(s,kind): return "同類設施只需一座，可拆除後另選位置重建。"
	for index in range(6):
		if s.journey["decor"][index]!=0 and FOOTPRINTS[site].grow(5).has_point(JOURNEY.SLOTS[index]): return "裝飾占用此處，請先移除對應庭園裝飾。"
	for key in COSTS[kind]:
		var owned: int=s.money if key=="money" else s.materials[key]
		if owned<COSTS[kind][key]: return "銀幣或施工材料不足。"
	return ""

static func build(s: RefCounted, site: int, kind: int) -> Dictionary:
	var reason := facility_reason(s,site,kind)
	if reason!="": return JOURNEY.result(false,reason)
	if kind!=0:
		for key in COSTS[kind]:
			if key=="money": s.money-=COSTS[kind][key]
			else: s.materials[key]-=COSTS[kind][key]
	s.estate["fixtures"][site]=kind
	return JOURNEY.result(true,"配置已更新；拆除不退材料。")

static func goal_ready(s: RefCounted, index: int) -> bool:
	match index:
		0: return s.harvested>=12
		1:
			var owned := 1 if s.chickens>0 else 0
			for id in RANCH.EXTRA:
				if s.ranch["animals"][id]["owned"]: owned+=1
			return owned>=3 and s.estate["care_total"]>=12
		2:
			var friends := 0
			for id in JOURNEY.PEOPLE:
				if JOURNEY.friendship(s,id)>=3: friends+=1
			return s.requests_completed>=3 and friends>=3
		3: return s.estate["craft_total"]>=5
		4: return s.journey["quests"].all(func(flag):return flag)
		5: return s.estate["summer_completed"]>=4 and s.journey["summer_done"]>0
	return false

static func claim_goal(s: RefCounted, index: int) -> Dictionary:
	if index<0 or index>5 or s.estate["milestones"][index] or not goal_ready(s,index): return JOURNEY.result(false,"目標尚未達成，或已領取謝禮。")
	if s.money>1000000000000-GOAL_REWARDS[index]: return JOURNEY.result(false,"帳簿已滿，謝禮保留。")
	s.estate["milestones"][index]=true
	s.money+=GOAL_REWARDS[index]
	return JOURNEY.result(true,"完成「%s」，獲得%d銀。" % [GOAL_NAMES[index],GOAL_REWARDS[index]])

static func daily_line(s: RefCounted, id: String) -> String:
	var index := JOURNEY.PEOPLE.find(id)
	if index<0: return ""
	var story_choice: int=s.chapter["stories"][id]
	var memories: int=s.estate["choices"][id]
	if story_choice>0: return s.CHAPTER.DATA.STORIES[index][story_choice+3]+"\n"+(ACTIVITY_LINES[index][memories-1] if memories>0 and s.day%3==0 else DAILY_TOPICS[index][(s.day+index)%3])
	if memories>0 and s.day%3==0: return ACTIVITY_LINES[index][memories-1]+" 這段相處，我還記得。"
	var points := JOURNEY.friendship(s,id)
	var level := 3 if points>=25 else 2 if points>=10 else 1 if points>=3 else 0
	return ("夏日也記得歇一歇。" if s.season()=="夏" else "秋收時，也留點暖意給自己。" if s.season()=="秋" else "春風又把新芽吹開了。")+"\n"+DAILY_STAGES[index][level]+"\n"+DAILY_TOPICS[index][(s.day+index)%3]

static func activity(s: RefCounted, id: String, choice: int) -> Dictionary:
	if id not in JOURNEY.PEOPLE or choice not in [1,2] or not JOURNEY.near(s,id) or JOURNEY.friendship(s,id)<3: return JOURNEY.result(false,"請走近熟識的居民，再約一起活動。")
	var previous: int=s.estate["activities"][id]
	if previous>0 and (previous-1)/7==(s.day-1)/7: return JOURNEY.result(false,"這週已一起活動，下週再約。")
	if s.energy<6 or s.minute>1289: return JOURNEY.result(false,"請保留6點體力與30分鐘，晚些時候再約。")
	s.energy-=6
	s.minute+=30
	s.estate["activities"][id]=s.day
	s.estate["choices"][id]=choice
	if id=="npc": s.friendship=mini(100000000,s.friendship+2)
	elif id in ["shop","smith"]: s.spring_progress["friends"][id]=mini(100000000,s.spring_progress["friends"][id]+2)
	else: s.ranch["friends"][id]=mini(100,s.ranch["friends"][id]+2)
	return JOURNEY.result(true,"一起度過半小時，好感+2；這次相處會留在日常對話裡。")

static func summer_job(s: RefCounted, index: int) -> Dictionary:
	if index<0 or index>3 or s.season()!="夏" or s.area_id!=LIFE.AREAS[index]: return JOURNEY.result(false,"夏季到對應聚落參加週活動。")
	var previous: int=s.estate["summer_jobs"][s.area_id]
	if previous>0 and (previous-1)/7==(s.day-1)/7: return JOURNEY.result(false,"本聚落這週已完成，下週再來。")
	if s.energy<4 or JOURNEY.count(s,SUMMER_NEEDS[index])<SUMMER_AMOUNTS[index] or s.money>1000000000000-SUMMER_REWARDS[index] or s.estate["summer_completed"]>=100000000: return JOURNEY.result(false,"體力、物資不足，或帳簿已滿。")
	JOURNEY.take(s,SUMMER_NEEDS[index],SUMMER_AMOUNTS[index])
	s.energy-=4
	s.money+=SUMMER_REWARDS[index]
	s.estate["summer_jobs"][s.area_id]=s.day
	s.estate["summer_completed"]+=1
	return JOURNEY.result(true,"完成夏季聚落活動，收到%d銀。" % SUMMER_REWARDS[index])

static func valid(v: Variant, data: Dictionary) -> bool:
	if not v is Dictionary or v.size()!=empty().size(): return false
	for key in empty():
		if not v.has(key): return false
	if not v["fixtures"] is Array or v["fixtures"].size()!=3 or not v["milestones"] is Array or v["milestones"].size()!=6: return false
	var seen := {}
	for item in v["fixtures"]:
		if not JOURNEY.number(item,3) or (item>0 and seen.has(int(item))): return false
		if item>0: seen[int(item)]=true
	var decor: Array=data.get("journey",JOURNEY.empty())["decor"]
	for site in range(3):
		if v["fixtures"][site]==1 and not data.get("life",{}).get("irrigator",false): return false
		if v["fixtures"][site]>0:
			for index in range(6):
				if decor[index]>0 and FOOTPRINTS[site].grow(5).has_point(JOURNEY.SLOTS[index]): return false
	for flag in v["milestones"]:
		if not flag is bool: return false
	for key in ["care_total","craft_total","summer_completed"]:
		if not JOURNEY.number(v[key],100000000): return false
	if not preload("res://scripts/stock_rules.gd").valid(v["activities"],JOURNEY.PEOPLE,JOURNEY.PEOPLE,int(data["day"])) or not preload("res://scripts/stock_rules.gd").valid(v["choices"],JOURNEY.PEOPLE,JOURNEY.PEOPLE,2): return false
	if not preload("res://scripts/stock_rules.gd").valid(v["summer_jobs"],LIFE.AREAS,LIFE.AREAS,int(data["day"])): return false
	for id in JOURNEY.PEOPLE:
		if (v["activities"][id]==0)!=(v["choices"][id]==0): return false
	for day in v["summer_jobs"].values():
		if day>0 and JOURNEY.season_at(data,int(day))!="夏": return false
	if v["milestones"][1]:
		var owned: int=1 if data.get("chickens",0)>0 else 0
		for animal in data.get("ranch",{}).get("animals",{}).values():
			if animal["owned"]: owned+=1
		if owned<3: return false
	if v["milestones"][2]:
		var friends: int=1 if data["friendship"]>=3 else 0
		for points in data.get("spring_progress",{}).get("friends",{}).values():
			if points>=3: friends+=1
		for points in data.get("ranch",{}).get("friends",{}).values():
			if points>=3: friends+=1
		if data.get("requests_completed",0)<3 or friends<3: return false
	if v["milestones"][4] and not data.get("journey",JOURNEY.empty())["quests"].all(func(flag): return flag): return false
	var summer_places := 0
	for previous in v["summer_jobs"].values():
		if previous>0: summer_places+=1
	if v["summer_completed"]<summer_places or (v["summer_completed"]>0 and summer_places==0): return false
	if v["milestones"][0] and data["harvested"]<12: return false
	if v["milestones"][1] and v["care_total"]<12: return false
	if v["milestones"][3] and v["craft_total"]<5: return false
	if v["milestones"][5] and (v["summer_completed"]<4 or data.get("journey",JOURNEY.empty())["summer_done"]==0): return false
	return true

static func normalized(v: Dictionary) -> Dictionary:
	var copy := v.duplicate(true)
	for key in ["care_total","craft_total","summer_completed"]: copy[key]=int(copy[key])
	for i in range(3): copy["fixtures"][i]=int(copy["fixtures"][i])
	for key in ["activities","choices","summer_jobs"]:
		for id in copy[key]: copy[key][id]=int(copy[key][id])
	return copy
