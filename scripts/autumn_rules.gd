extends RefCounted
const J=preload("res://scripts/journey_rules.gd")
const CROPS=preload("res://scripts/crop_data.gd")
const STAND := Vector2(210,174)
const RECIPES := ["harvest_soup","grape_juice"]
static func empty() -> Dictionary:
	return {"cycle":0,"offered":[],"done":0,"choice":0,"learned":false,"exchanged_day":0}
static func normalized(v: Dictionary) -> Dictionary:
	var out:=v.duplicate(true)
	for key in ["cycle","done","choice","exchanged_day"]: out[key]=int(out[key])
	return out
static func valid(v: Variant, data: Dictionary) -> bool:
	if not v is Dictionary or v.size()!=6: return false
	var day:=int(data["day"])
	var offset:=int(data.get("calendar_offset",J.legacy_offset(day)))
	for key in ["cycle","done"]:
		if not J.number(v.get(key),J.year(day,offset)): return false
	if not J.number(v.get("choice"),2) or not J.number(v.get("exchanged_day"),day) or not v.get("learned") is bool: return false
	if not v.get("offered") is Array or v["offered"].size()>3: return false
	var seen:={}
	for id in v["offered"]:
		if id not in CROPS.AUTUMN or seen.has(id): return false
		seen[id]=true
	if not seen.is_empty() and v["cycle"]==0: return false
	if v["done"]>v["cycle"]: return false
	if (v["done"]>0)!=(v["choice"]>0) or v["learned"]!=(v["done"]>0): return false
	if v["done"]>0 and v["done"]==v["cycle"] and seen.size()!=3: return false
	if (v["cycle"]==J.year(day,offset) and not seen.is_empty()) or v["done"]==J.year(day,offset):
		if (day+offset-1)%84+1<70: return false
	if v["exchanged_day"]>0 and not v["learned"]: return false
	return true
static func on_site(s: RefCounted) -> bool:
	return s.area_id=="town" and s.player_position.distance_to(STAND)<=52
static func in_season(s: RefCounted) -> bool:
	return s.season()=="秋" and (s.day-1)%28+1>=14
static func open(s: RefCounted) -> bool:
	return on_site(s) and in_season(s) and s.autumn["done"]!=s.calendar_year()
static func donate(s: RefCounted, id: String) -> Dictionary:
	if not open(s) or id not in CROPS.AUTUMN or s.produce.get(id,0)<1: return J.result(false,"秋14至28日，帶三種秋收各一份到鎮上共收長桌。")
	var current: bool=s.autumn["cycle"]==s.calendar_year()
	if current and id in s.autumn["offered"]: return J.result(false,"這種收成已入籃；請帶另一種。")
	if not current:
		s.autumn["cycle"]=s.calendar_year()
		s.autumn["offered"]=[]
	s.produce[id]-=1
	s.autumn["offered"].append(id)
	return J.result(true,"將"+CROPS.CROPS[id]["name"]+"放入共收籃。")
static func finish(s: RefCounted, choice: int) -> Dictionary:
	if choice not in [1,2] or not open(s) or s.autumn["cycle"]!=s.calendar_year() or s.autumn["offered"].size()!=3 or s.money>999999999800: return J.result(false,"請先備齊三種秋收；本年謝禮只領一次。")
	s.autumn["done"]=s.calendar_year()
	s.autumn["choice"]=choice
	s.autumn["learned"]=true
	s.money+=200
	return J.result(true,"共收月會記入手札，收到200銀；學會共收暖湯與紫露葡萄汁。")
static func exchange(s: RefCounted, id: String) -> Dictionary:
	if not on_site(s) or not in_season(s) or not s.autumn["learned"] or s.autumn["exchanged_day"]==s.day or id not in CROPS.AUTUMN or s.produce.get(id,0)<1 or s.seeds[id]>99999998: return J.result(false,"月會完成後，每日可用一份秋收換同種種苗兩包。")
	s.produce[id]-=1
	s.seeds[id]+=2
	s.autumn["exchanged_day"]=s.day
	return J.result(true,"收成留給共食長桌，帶回兩包種苗；今天已交換。")
static func remembered(s: RefCounted) -> String:
	return "青禾留了一碗暖湯，博林把麥穗與月燈繩結編在一起。你們決定：明年仍把第一份收成留給鄰人。" if s.autumn["choice"]==1 else "莉莉雅把葡萄汁分給巡夜的艾德里克，素月記下每戶的食譜。你們決定：讓旅人也能在長桌找到位置。"
