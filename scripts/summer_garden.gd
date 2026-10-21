extends RefCounted
const POINT := Vector2(313,97)
const ANCHOR := Vector2(318,116)
const COST := {"wood":6,"stone":4,"money":90}
static func empty() -> Dictionary:
	return {"built":false,"planted":false,"growth":0}
static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=3: return false
	if not value.get("built") is bool or not value.get("planted") is bool: return false
	var growth: Variant=value.get("growth")
	if not (growth is int or growth is float) or not is_finite(growth) or growth!=int(growth) or growth<0 or growth>7: return false
	return (value["built"] or not value["planted"]) and (value["planted"] or growth==0)
static func reason(s: RefCounted, action: String) -> String:
	if s.area_id!="farm" or s.player_position.distance_to(ANCHOR)>30: return "請先走近莊園池邊的蓮藕水槽。"
	var g: Dictionary=s.summer_garden
	match action:
		"build":
			if g["built"]: return "水槽已建好，不需重複建造。"
			if s.money<COST["money"] or s.materials["wood"]<COST["wood"] or s.materials["stone"]<COST["stone"]: return "需木材6、石料4與90銀。"
		"plant":
			if not g["built"] or g["planted"]: return "先建好空水槽再栽種。"
			if s.JOURNEY.season(s.day)!="夏": return "蓮藕僅夏季開始栽種；跨季保留並繼續成長。"
			if s.seeds.get("lotus",0)<1: return "需要一包蓮藕種苗，夏季可到種子鋪購買。"
			if s.energy<1: return "先休息恢復體力再栽種。"
		"harvest":
			if not g["planted"] or g["growth"]<7: return "蓮藕仍在成長，保持水槽蓄水，睡醒後成長一天。"
			if s.energy<1 or s.produce.get("lotus",0)>=100000000: return "體力或行囊空間不足。"
		_: return "未知的水槽操作。"
	return ""
static func apply(s: RefCounted, action: String) -> Dictionary:
	var error := reason(s,action)
	if error!="": return {"ok":false,"text":error}
	match action:
		"build":
			s.money-=COST["money"]
			s.materials["wood"]-=COST["wood"]
			s.materials["stone"]-=COST["stone"]
			s.summer_garden["built"]=true
		"plant":
			s.seeds["lotus"]-=1
			s.energy-=1
			s.summer_garden["planted"]=true
			s.summer_garden["growth"]=0
		"harvest":
			s.energy-=1
			s.produce["lotus"]=s.produce.get("lotus",0)+1
			s.harvested+=1
			s.summer_garden["planted"]=false
			s.summer_garden["growth"]=0
	return {"ok":true,"text":{"build":"池邊水槽建好了。","plant":"種下蓮藕；水槽自動蓄水，每次睡醒成長一天。","harvest":"收穫一份蓮藕，可預覽出貨或保留參加節慶。"}[action]}
static func advance(s: RefCounted) -> void:
	if s.summer_garden["planted"]: s.summer_garden["growth"]=mini(7,s.summer_garden["growth"]+1)
static func draw(canvas: CanvasItem, garden: Dictionary) -> void:
	if not garden["built"]: return
	if garden["planted"]:
		preload("res://scripts/summer_art.gd").crop(canvas,"lotus",POINT,3 if garden["growth"]>=7 else 2 if garden["growth"]>=4 else 1 if garden["growth"]>=2 else 0)
	else:
		canvas.draw_rect(Rect2(POINT-Vector2(13,8),Vector2(26,8)),Color("86613c"))
		canvas.draw_rect(Rect2(POINT-Vector2(11,7),Vector2(22,4)),Color("4f9faf"))
		canvas.draw_rect(Rect2(POINT-Vector2(10,3),Vector2(20,3)),Color("326278"))
