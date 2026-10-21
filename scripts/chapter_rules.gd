extends RefCounted
const DATA=preload("res://scripts/chapter_data.gd")
const PEOPLE=DATA.PEOPLE
static func empty() -> Dictionary:
	var value := {"stories":{},"journeys":[0,0,0,0],"order_week":0,"order_bits":0,"orders_done":0,"goals":[false,false,false,false]}
	for id in PEOPLE: value["stories"][id]=0
	return value
static func reply(ok: bool, message: String) -> Dictionary: return {"ok":ok,"text":message}
static func week(s: RefCounted) -> int: return int((s.day-1)/7)+1
static func story(s: RefCounted, id: String, choice: int) -> Dictionary:
	if id not in PEOPLE or choice not in [1,2]: return reply(false,"未知的故事選擇。")
	if s.chapter["stories"][id]!=0 or not s.JOURNEY.near(s,id) or s.JOURNEY.friendship(s,id)<5 or s.energy<3 or s.minute>1300: return reply(false,"走近本人、好感達5，需3體力與20分鐘；每段事件只完成一次。")
	s.chapter["stories"][id]=choice
	s.energy-=3
	s.minute+=20
	if id=="npc": s.friendship=mini(100000000,s.friendship+2)
	elif id in ["shop","smith"]: s.spring_progress["friends"][id]=mini(100000000,s.spring_progress["friends"][id]+2)
	else: s.ranch["friends"][id]=mini(100,s.ranch["friends"][id]+2)
	return reply(true,DATA.STORIES[PEOPLE.find(id)][choice+3]+"\n好感+2，這個選擇會留在日常對話裡。")
static func stock(s: RefCounted, key: String) -> Dictionary:
	return s.ranch["stock"] if key=="ranch" else s.life["stock"] if key=="life" else s.get(key)
static func count(s: RefCounted, need: Array) -> int: return int(stock(s,need[0]).get(need[1],0))
static func need_name(s: RefCounted, need: Array) -> String:
	match need[0]:
		"produce": return s.CROPS[need[1]]["name"]
		"materials": return {"wood":"木材","stone":"石料","herb":"霧香草"}[need[1]]
		"goods": return s.PROCESSING.RECIPES[need[1]]["name"]
		"ranch": return s.RANCH_DATA.SPECIES[need[1]]["product"]
		"life": return s.LIFE_DATA.PRODUCTS[need[1]]["name"]
	return "物資"
static func journey(s: RefCounted, index: int) -> Dictionary:
	if index<0 or index>3: return reply(false,"未知的聚落旅章。")
	var stage: int=s.chapter["journeys"][index]
	if stage>=3: return reply(false,"這段旅章已完成，可重讀紀錄。")
	var point: Vector2=s.JOURNEY.CLUES[0] if stage==0 else Vector2(180,169)
	if s.area_id!=DATA.AREAS[index] or s.player_position.distance_to(point)>38: return reply(false,"先到該聚落的第一處記錄點觀察，再到工坊旁交付。")
	var definition: Array=DATA.JOURNEYS[index]
	if stage>0:
		var need: Array=definition[stage+3]
		if count(s,need)<need[2]: return reply(false,"還需要%s ×%d，箱內物品要先取回。" % [need_name(s,need),need[2]])
		if stage==2 and s.money>1000000000000-definition[6]: return reply(false,"銀幣帳簿已滿，先整理再完成旅章。")
		stock(s,need[0])[need[1]]-=need[2]
	s.chapter["journeys"][index]+=1
	if stage==2: s.money+=definition[6]
	return reply(true,"記下這一步。" if stage<2 else "完成旅章，獲得%d銀；這份謝禮只領一次。" % definition[6])
static func order(s: RefCounted, index: int) -> Dictionary:
	var summer: bool=s.JOURNEY.season(s.day)=="夏"
	match index:
		0: return {"title":"共食長桌的時蔬","needs":[["produce","tomato",2],["produce","eggplant",1]] if summer else [["produce","turnip",4],["produce","wheat",4]],"reward":270 if summer else 230}
		1: return {"title":"商隊的加工補給","needs":[["goods","dried_berry",2]] if week(s)%2==0 else [["goods","dried_wheat",3]],"reward":180 if week(s)%2==0 else 165}
		2: return {"title":"棲地的日常交換","needs":[["ranch","duck",2],["ranch","rabbit",1]],"reward":145}
	return {}
static func fingerprint(s: RefCounted) -> String: return JSON.stringify(s.to_data()).sha256_text()
static func order_reason(s: RefCounted, index: int) -> String:
	if index<0 or index>2: return "未知的每週訂單。"
	if s.chapter["order_week"]==week(s) and (s.chapter["order_bits"] & (1<<index))!=0: return "本週這份訂單已完成。"
	if s.area_id!="farm" or s.player_position.distance_to(Vector2(123,139))>30: return "請走近莊園出貨箱交付。"
	var definition := order(s,index)
	for need in definition["needs"]:
		if count(s,need)<need[2]: return "尚缺"+need_name(s,need)+"，請備齊後再確認。"
	if s.money>1000000000000-definition["reward"]: return "銀幣帳簿已滿。"
	return ""
static func deliver_order(s: RefCounted, index: int, guard: String) -> Dictionary:
	if guard!=fingerprint(s): return reply(false,"物資或日期已改變，請重新查看清單。")
	var reason := order_reason(s,index)
	if reason!="": return reply(false,reason)
	var definition := order(s,index)
	for need in definition["needs"]: stock(s,need[0])[need[1]]-=need[2]
	if s.chapter["order_week"]!=week(s):
		s.chapter["order_week"]=week(s)
		s.chapter["order_bits"]=0
	s.chapter["order_bits"]|=1<<index
	s.chapter["orders_done"]+=1
	s.money+=definition["reward"]
	return reply(true,"交付完成，獲得%d銀；本週此單不會重複結算。" % definition["reward"])
static func goal_ready(s: RefCounted, index: int) -> bool:
	match index:
		0: return s.chapter["stories"].values().filter(func(value):return value>0).size()>=3
		1: return s.chapter["journeys"].all(func(value):return value==3)
		2: return s.chapter["orders_done"]>=6
		3:
			var total := 0
			for id in s.RANCH_DATA.ORDER:
				if s.GROWTH.stage(s,id)>=3: total+=1
			return total>=3
	return false
static func claim_goal(s: RefCounted, index: int) -> Dictionary:
	if index<0 or index>3 or s.chapter["goals"][index] or not goal_ready(s,index) or s.money>1000000000000-DATA.GOALS[index][1]: return reply(false,"目標未達成、已領取，或銀幣帳簿已滿。")
	s.chapter["goals"][index]=true
	s.money+=DATA.GOALS[index][1]
	return reply(true,"完成長期目標，謝禮已記入帳簿。")
static func integer(value: Variant, limit: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=0 and value<=limit
static func valid(value: Variant, data: Dictionary) -> bool:
	if not value is Dictionary or value.size()!=6: return false
	if not value.get("stories") is Dictionary or value["stories"].size()!=9: return false
	for id in PEOPLE:
		if not integer(value["stories"].get(id),2): return false
		if value["stories"][id]>0:
			var points: int=int(data["friendship"]) if id=="npc" else int(data.get("spring_progress",{}).get("friends",{}).get(id,0)) if id in ["shop","smith"] else int(data.get("ranch",{}).get("friends",{}).get(id,0))
			if points<7: return false
	if not value.get("journeys") is Array or value["journeys"].size()!=4 or not value["journeys"].all(func(n):return integer(n,3)): return false
	var current_week := int((data["day"]-1)/7)+1
	if not integer(value.get("order_week"),current_week) or not integer(value.get("order_bits"),7) or not integer(value.get("orders_done"),current_week*3): return false
	if value["order_week"]==0 and (value["order_bits"]>0 or value["orders_done"]>0): return false
	var bits := int(value["order_bits"])
	if value["orders_done"]<int((bits&1)>0)+int((bits&2)>0)+int((bits&4)>0): return false
	if not value.get("goals") is Array or value["goals"].size()!=4: return false
	for flag in value["goals"]:
		if not flag is bool: return false
	if value["goals"][0] and value["stories"].values().filter(func(n):return n>0).size()<3: return false
	if value["goals"][1] and not value["journeys"].all(func(n):return n==3): return false
	if value["goals"][2] and value["orders_done"]<6: return false
	if value["goals"][3]:
		var total := 0
		var growth: Dictionary=data.get("growth",{})
		for id in ["hen","duck","rabbit","sheep","bee","worm","deer","carp"]:
			var days: int=int(growth.get("days",{}).get(id,0))
			var points: int=mini(100,days*2+int(growth.get("affinity",{}).get(id,0))) if id=="hen" else int(data.get("ranch",{}).get("animals",{}).get(id,{}).get("bond",0))
			if days>=14 and points>=20: total+=1
		if total<3: return false
	return true
static func normalized(value: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	for id in PEOPLE: result["stories"][id]=int(value["stories"][id])
	for i in range(4): result["journeys"][i]=int(value["journeys"][i])
	for key in ["order_week","order_bits","orders_done"]: result[key]=int(value[key])
	return result
