extends RefCounted
const DATA=preload("res://scripts/ranch_data.gd")
const TRAITS := ["愛啄穀粒","喜歡清水","好奇親人","喜歡梳理","偏愛晴日","喜愛安靜","慢熟溫和","偏愛暮色"]
const TIPS := ["上午10時前一起理穀","下午14至17時查看水邊","上午10時前安靜陪伴","下午14至18時梳理捲毛","晴天上午10至下午16時觀察花圃","雨天或下午17時後更換桑葉","上午10時前安靜同行","下午17至19時觀察水面"]
const DAYS := [3,7,14]
const BONDS := [3,10,20]
const REWARDS := [3,5,8]
static func empty() -> Dictionary:
	var value := {"days":{},"last":{},"special":{},"claimed":{},"affinity":{}}
	for id in DATA.ORDER:
		for key in value: value[key][id]=0
	return value
static func owned(s: RefCounted, id: String) -> bool:
	return s.chickens>0 if id=="hen" else s.ranch["animals"][id]["owned"]
static func bond(s: RefCounted, id: String) -> int:
	return mini(100,s.growth["days"][id]*2+s.growth["affinity"][id]) if id=="hen" else int(s.ranch["animals"][id]["bond"])
static func stage(s: RefCounted, id: String) -> int:
	var result := 0
	for tier in range(3):
		if s.growth["days"][id]>=DAYS[tier] and bond(s,id)>=BONDS[tier]: result=tier+1
	return result
static func record(s: RefCounted, id: String) -> void:
	if s.growth["last"][id]!=s.day:
		s.growth["last"][id]=s.day
		s.growth["days"][id]=mini(100000000,s.growth["days"][id]+1)
static func hen_care(s: RefCounted) -> Dictionary:
	if s.area_id!="ranch_poultry" or s.chickens==0 or s.growth["last"]["hen"]==s.day or s.energy<1: return {"ok":false,"text":"到家禽庭院走近母雞，每日可整理一次羽毛，消耗1體力。"}
	s.energy-=1
	record(s,"hen")
	return {"ok":true,"text":"輕輕整理羽毛，記下今天的陪伴。"}
static func moment(s: RefCounted, id: String) -> bool:
	match id:
		"hen","rabbit","deer": return s.minute<600
		"duck": return s.minute>=840 and s.minute<1020
		"sheep": return s.minute>=840 and s.minute<1080
		"bee": return not s.is_raining() and s.minute>=600 and s.minute<960
		"worm": return s.is_raining() or s.minute>=1020
		"carp": return s.minute>=1020 and s.minute<1140
	return false
static func interact(s: RefCounted, id: String) -> Dictionary:
	if id in DATA.ORDER and bond(s,id)>=100: return {"ok":false,"text":"好感已滿，保留體力，平日仍可照料陪伴。"}
	if id not in DATA.ORDER or not owned(s,id) or s.area_id!=DATA.AREAS[DATA.SPECIES[id]["home"]] or s.growth["special"][id]==s.day or not moment(s,id) or s.energy<2 or s.minute>1310:
		return {"ok":false,"text":"到對應棲地，在喜歡的時段互動；每日一次，需2體力與10分鐘。"}
	s.growth["special"][id]=s.day
	s.growth["affinity"][id]=mini(100,s.growth["affinity"][id]+1)
	s.energy-=2
	s.minute+=10
	if id!="hen": s.ranch["animals"][id]["bond"]=mini(100,s.ranch["animals"][id]["bond"]+1)
	return {"ok":true,"text":"留意牠的步調，回應了今天的親近。"}
static func claim(s: RefCounted, id: String, tier: int) -> Dictionary:
	if id not in DATA.ORDER or tier<0 or tier>2 or not owned(s,id) or stage(s,id)<=tier or (s.growth["claimed"][id] & (1<<tier))!=0 or s.ranch["feed"]>100000000-REWARDS[tier]: return {"ok":false,"text":"里程碑未達成、已領取，或飼料空間不足。"}
	s.growth["claimed"][id]|=1<<tier
	s.ranch["feed"]+=REWARDS[tier]
	return {"ok":true,"text":"留下照料里程碑，獲得%d份照料飼料。" % REWARDS[tier]}
static func valid(value: Variant, data: Dictionary) -> bool:
	if not value is Dictionary or value.size()!=5: return false
	for key in ["days","last","special","claimed","affinity"]:
		if not value.get(key) is Dictionary or value[key].size()!=8: return false
		for id in DATA.ORDER:
			var n: Variant=value[key].get(id)
			if not (n is int or n is float) or not is_finite(float(n)) or n!=int(n) or n<0 or n>(7 if key=="claimed" else mini(100,int(data["day"])) if key=="affinity" else data["day"]): return false
	for id in DATA.ORDER:
		if value["affinity"][id]>value["special"][id] or ((value["affinity"][id]==0)!=(value["special"][id]==0)): return false
		if value["days"][id]>value["last"][id] or ((value["days"][id]==0)!=(value["last"][id]==0)): return false
		var is_owned: bool=data.get("chickens",0)>0 if id=="hen" else data.get("ranch",{}).get("animals",{}).get(id,{}).get("owned",false)
		if not is_owned and (value["days"][id]>0 or value["special"][id]>0 or value["claimed"][id]>0 or value["affinity"][id]>0): return false
		var points: int=mini(100,int(value["days"][id])*2+int(value["affinity"][id])) if id=="hen" else int(data.get("ranch",{}).get("animals",{}).get(id,{}).get("bond",0))
		for tier in range(3):
			if (int(value["claimed"][id]) & (1<<tier))!=0 and (value["days"][id]<DAYS[tier] or points<BONDS[tier]): return false
	return true
static func normalized(value: Dictionary) -> Dictionary:
	var result := empty()
	for key in result:
		for id in DATA.ORDER: result[key][id]=int(value[key][id])
	return result
