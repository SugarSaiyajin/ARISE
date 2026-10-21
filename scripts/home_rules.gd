extends RefCounted
const STOCKS=preload("res://scripts/stock_rules.gd")
const CROPS=preload("res://scripts/crop_data.gd")
const STORAGE := Vector2(187,180)
const CHAIR := Vector2(201,154)
const THEMES := ["青瓷木居","暖麥晨光","月葉清居"]
static func empty() -> Dictionary:
	return {"stored":STOCKS.normalized({},CROPS.ORDER),"theme":0,"rested_day":0}
static func normalized(value: Dictionary) -> Dictionary:
	return {"stored":STOCKS.normalized(value.get("stored",{}),CROPS.ORDER),"theme":int(value.get("theme",0)),"rested_day":int(value.get("rested_day",0))}
static func valid(value: Variant, day: int) -> bool:
	if not value is Dictionary or value.size()!=3 or not STOCKS.valid(value.get("stored"),CROPS.ORDER): return false
	for key in ["theme","rested_day"]:
		var n: Variant=value.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or n!=int(n) or n<0: return false
	return value["theme"]<=2 and value["rested_day"]<=day
static func near(s: RefCounted, point: Vector2) -> bool:
	return s.area_id=="house" and s.player_position.distance_to(point)<=30
static func transfer(s: RefCounted, id: String, deposit: bool, amount: int = 1) -> Dictionary:
	if id not in CROPS.ORDER or amount not in [1,5] or not near(s,STORAGE): return {"ok":false,"text":"請走近農舍收納箱；每次移動1或5份收成。"}
	var source: Dictionary=s.produce if deposit else s.home["stored"]
	var target: Dictionary=s.home["stored"] if deposit else s.produce
	if source.get(id,0)<amount or target.get(id,0)>100000000-amount: return {"ok":false,"text":"數量不足，或目的行囊已滿。"}
	source[id]-=amount
	target[id]=target.get(id,0)+amount
	return {"ok":true,"text":"已收好；箱內作物不參與出貨、料理或送禮，取回後可使用。" if deposit else "已取回行囊。"}
static func rest(s: RefCounted) -> Dictionary:
	if not near(s,CHAIR) or s.home["rested_day"]==s.day or s.energy>=100 or s.minute>1300: return {"ok":false,"text":"請走近茶桌；每日可小歇一次，體力滿或時間太晚時不消耗時間。"}
	s.energy=mini(100,s.energy+8)
	s.minute+=20
	s.home["rested_day"]=s.day
	return {"ok":true,"text":"喝口熱茶，小歇20分鐘，恢復最多8體力。"}
static func theme(s: RefCounted) -> Dictionary:
	if s.area_id!="house": return {"ok":false,"text":"回到農舍後再布置。"}
	s.home["theme"]=(s.home["theme"]+1)%3
	return {"ok":true,"text":"已換成"+THEMES[s.home["theme"]]+"；家具位置與通道保留。"}
