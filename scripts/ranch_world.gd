extends "res://scripts/farm_world.gd"

const DATA = preload("res://scripts/ranch_data.gd")
const ART = preload("res://scripts/approved_art.gd")
const PENS := [Vector2(173,151),Vector2(336,153)]

func home_index() -> int:
	return DATA.AREAS.find(area_id)

func display_name() -> String:
	return DATA.HOMES[home_index()]

func entry_spawn(_from: String = "") -> Vector2:
	return Vector2(239,193)

func plot_at(_point: Vector2) -> int:
	return -1

func edge_destination(p: Vector2) -> String:
	return "farm" if p.y >= 211 and p.x > 216 and p.x < 264 else ""

func interactions() -> Dictionary:
	var result := {"farm":Vector2(240,205),"ranch_board":Vector2(70,181)}
	for i in range(2):
		result["animal:"+DATA.ORDER[home_index()*2+i]] = PENS[i]+Vector2(0,24)
	var n := 0
	for id in DATA.VISITORS:
		if DATA.RESIDENTS[id]["home"] == home_index():
			result["visitor:"+id] = Vector2(110+n*110,193)
			n += 1
	return result

func interaction_hitbox(id: String) -> Rect2:
	var anchor: Vector2 = interactions()[id]
	if id.begins_with("animal:"): return Rect2(anchor-Vector2(27,50),Vector2(54,55))
	return Rect2(anchor-Vector2(16,33),Vector2(32,43))

func blocked(p: Vector2) -> bool:
	if not Rect2(12,53,456,164).has_point(p): return true
	for block in [Rect2(65,76,112,43),Rect2(292,73,110,44)]:
		if block.grow(3).has_point(p): return true
	# The pond is solid; animal care is reached from the path beside it.
	if home_index() in [0,3] and Rect2(306,120,68,35).has_point(p): return true
	return false

func _draw() -> void:
	if state == null: return
	var home := home_index()
	ART.tile(self,0,Rect2(0,0,480,270))
	ART.tile(self,4,Rect2(22,77,24,99))
	ART.tile(self,4,Rect2(422,92,34,84))
	ART.tile(self,1,Rect2(18,176,444,28))
	ART.tile(self,7,Rect2(224,108,30,108))
	for x in range(24,465,16):
		if x in [24,456]: r(x,70,2,90,"aa8c60")
		else: r(x,69,16,3,"c6ae7a")
		if x<216 or x>264:
			r(x,213,16,3,"a18356")
			r(x,209,3,10,"ddc398")
	var buildings := [[5,2],[6,9],[7,1],[8,2]]
	ART.building(self,buildings[home][0],Rect2(59,48,126,82))
	ART.building(self,buildings[home][1],Rect2(289,45,118,83))
	if home in [0,3]:
		draw_rect(Rect2(302,118,76,40),Color("b7c7a5"))
		ART.tile(self,3,Rect2(306,121,68,34))
		for n in range(7): r(310+n*8+sin(elapsed+n)*2,127+(n%3)*8,6,1,"a5d3c5")
	elif home == 2:
		for x in range(293,390,13):
			r(x,141,2,9,"638955")
			r(x-2,139,6,3,"edcf83")
	for i in range(2):
		var id: String = DATA.ORDER[home*2+i]
		var owned: bool = state.chickens>0 if id=="hen" else state.ranch["animals"][id]["owned"]
		if owned:
			var baby: bool = false if id=="hen" else state.ranch["animals"][id]["age"]<DATA.SPECIES[id]["days"]
			var frame := 3 if baby else int(elapsed*1.4)%3
			var point: Vector2 = PENS[i]+Vector2(sin(elapsed*0.8+i)*6,0)
			var heights := [14.0,14.0,16.0,22.0,9.0,8.0,27.0,15.0]
			ART.animal(self,point,home*2+i,frame,heights[home*2+i]*(0.65 if baby else 1.0))
			if id=="hen":
				for n in range(1,state.chickens): ART.animal(self,point+Vector2(22*n,8),0,int(elapsed)%3,20)
		else:
			r(PENS[i].x-6,PENS[i].y-2,12,3,"b29b71")
		label_at(PENS[i]+Vector2(0,12),DATA.SPECIES[id]["name"]+(" · 未入住" if not owned else ""))
	var layers: Array = [{"y":actor.y,"id":"hero","point":actor}]
	for key in interactions():
		if key.begins_with("visitor:"):
			var p: Vector2 = interactions()[key]
			layers.append({"y":p.y,"id":key.trim_prefix("visitor:"),"point":p})
	layers.sort_custom(func(a,b): return a["y"]<b["y"])
	for item in layers:
		if item["id"]=="hero": person(actor)
		else:
			ART.resident(self,item["point"],DATA.RESIDENTS[item["id"]]["sprite"])
			label_at(item["point"]-Vector2(0,34),DATA.RESIDENTS[item["id"]]["name"])
	ART.building(self,10,Rect2(4,55,57,73))
	ART.building(self,11,Rect2(416,70,60,76))
	label_at(Vector2(70,177),"牧場手冊")
	label_at(Vector2(240,215),"回莊園 ↓")
	if not state.RANCH.home_open(state,home):
		label_at(Vector2(240,94),"棲地尚未建造 · 點牧場手冊安排")
	if state.is_raining():
		for i in range(45):
			var p := Vector2(fmod(i*37,480),45+fmod(i*23+elapsed*70,172))
			draw_line(p,p+Vector2(-2,5),Color("d6e4d488"),1)
