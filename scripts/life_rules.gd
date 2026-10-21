extends RefCounted

const DATA = preload("res://scripts/life_data.gd")
const RANCH = preload("res://scripts/ranch_data.gd")
const LIMIT := 100000000

static func empty() -> Dictionary:
	var v := {"stock":{},"job":{},"events":{},"requests":{},"gathered":{},"irrigator":false}
	for id in DATA.GOODS: v["stock"][id]=0
	for id in RANCH.VISITORS:
		v["events"][id]=false
		v["requests"][id]=0
	for id in DATA.AREAS: v["gathered"][id]=0
	return v

static func answer(ok: bool, text: String) -> Dictionary:
	return {"ok":ok,"text":text}

static func count(s: RefCounted, source: Array) -> int:
	if source[0]=="ranch": return int(s.ranch["stock"].get(source[1],0))
	return int(s.get(source[0]).get(source[1],0))

static func can_craft(s: RefCounted, id: String) -> bool:
	if not DATA.RECIPES.has(id): return false
	var recipe: Dictionary = DATA.RECIPES[id]
	if s.area_id!=recipe["area"] or s.money<DATA.FEES[id]: return false
	if id in ["grain_feed","herb_feed"]:
		if s.ranch["feed"]>LIMIT-recipe["output"]: return false
	elif not s.life["job"].is_empty() or (id=="irrigator" and s.life["irrigator"]): return false
	for ingredient in recipe["needs"]:
		if count(s,ingredient)<ingredient[2]: return false
	return true

static func craft(s: RefCounted, id: String) -> Dictionary:
	if not can_craft(s,id): return answer(false,"請到指定工坊備齊材料；也請先領取上一件成品。")
	var recipe: Dictionary = DATA.RECIPES[id]
	s.money-=DATA.FEES[id]
	for ingredient in recipe["needs"]:
		if ingredient[0]=="ranch": s.ranch["stock"][ingredient[1]]-=ingredient[2]
		else: s.get(ingredient[0])[ingredient[1]]-=ingredient[2]
	if id in ["grain_feed","herb_feed"]:
		s.ranch["feed"]+=recipe["output"]
		return answer(true,"製成 %d 份照料飼料，已收入倉庫。" % recipe["output"])
	s.life["job"]={"id":id,"ready_day":s.day+1}
	return answer(true,"工坊已收下材料，休息一天後回來領取。")

static func collect(s: RefCounted) -> Dictionary:
	var job: Dictionary = s.life["job"]
	if job.is_empty() or s.day<job["ready_day"]: return answer(false,"工坊還沒有完成的委託。")
	var id: String = job["id"]
	if s.area_id!=DATA.RECIPES[id]["area"]: return answer(false,"請回接單的工坊領取。")
	if id=="irrigator":
		if s.life["irrigator"]: return answer(false,"灌溉器已安裝。")
		s.life["irrigator"]=true
	else:
		if s.life["stock"][id]>=LIMIT: return answer(false,"工藝行囊已滿，成品仍由工坊保管。")
		s.life["stock"][id]+=1
	s.estate["craft_total"]=mini(100000000,s.estate["craft_total"]+1)
	s.life["job"]={}
	return answer(true,"已領取"+DATA.RECIPES[id]["name"]+("，每晚會替前兩格作物補水。" if id=="irrigator" else "，可保留或回莊園出貨。"))

static func near_resident(s: RefCounted, id: String) -> bool:
	return RANCH.RESIDENTS.has(id) and s.area_id==RANCH.visitor_area(id,s.minute,s.is_raining())

static func deliver(s: RefCounted, id: String) -> Dictionary:
	if not near_resident(s,id): return answer(false,"居民已移動，請到目前所在的地方交付。")
	var request: Dictionary = DATA.REQUESTS[id]
	if s.life["requests"][id]==s.day or s.ranch["stock"][request["item"]]<1 or s.money>1000000000000-request["reward"]:
		return answer(false,"今天已交付、材料不足，或帳簿金額已滿。")
	s.ranch["stock"][request["item"]]-=1
	s.money+=request["reward"]
	s.life["requests"][id]=s.day
	s.ranch["friends"][id]=mini(100,s.ranch["friends"][id]+1)
	return answer(true,"完成「%s」，獲得 %d 銀與好感。" % [request["purpose"],request["reward"]])

static func event_available(s: RefCounted, id: String) -> bool:
	return near_resident(s,id) and s.ranch["friends"][id]>=3 and not s.life["events"][id]

static func finish_event(s: RefCounted, id: String) -> Dictionary:
	if not event_available(s,id) or s.money>1000000000000-50: return answer(false,"這段故事尚未開啟，或已記入手札。")
	s.life["events"][id]=true
	s.money+=50
	return answer(true,"相識故事已記入手札，收到居民的 50 銀謝禮。")

static func gather(s: RefCounted) -> Dictionary:
	if s.area_id not in DATA.AREAS or s.energy<2: return answer(false,"請到聚落採集點，並保留兩點體力。")
	var kind: String = ["herb","stone","herb","wood"][DATA.AREAS.find(s.area_id)]
	if s.life["gathered"][s.area_id]==s.day or s.materials[kind]>=LIMIT: return answer(false,"今天已採集，或素材行囊已滿。")
	s.life["gathered"][s.area_id]=s.day
	s.materials[kind]+=1
	s.energy-=2
	return answer(true,"收下一份聚落素材，明天可再來看看。")

static func integer(v: Variant, limit: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v>=0 and v<=limit and v==int(v)

static func valid(v: Variant, day: int) -> bool:
	if not v is Dictionary or v.size()!=6: return false
	for key in empty():
		if not v.has(key): return false
	if not v["irrigator"] is bool: return false
	for key in ["stock","job","events","requests","gathered"]:
		if not v[key] is Dictionary: return false
	if v["stock"].size()!=5 or v["events"].size()!=6 or v["requests"].size()!=6 or v["gathered"].size()!=4: return false
	for id in DATA.GOODS:
		if not integer(v["stock"].get(id),LIMIT): return false
	for id in RANCH.VISITORS:
		if not v["events"].get(id) is bool or not integer(v["requests"].get(id),day): return false
	for id in DATA.AREAS:
		if not integer(v["gathered"].get(id),day): return false
	var job: Dictionary = v["job"]
	if not job.is_empty():
		if job.size()!=2 or job.get("id") not in DATA.GOODS+["irrigator"] or not integer(job.get("ready_day"),day+1) or job["ready_day"]<2: return false
		if job["id"]=="irrigator" and v["irrigator"]: return false
	return true

static func normalized(v: Dictionary) -> Dictionary:
	var copy := v.duplicate(true)
	for key in ["stock","requests","gathered"]:
		for id in copy[key]: copy[key][id]=int(copy[key][id])
	if not copy["job"].is_empty(): copy["job"]["ready_day"]=int(copy["job"]["ready_day"])
	return copy
