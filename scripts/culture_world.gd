extends "res://scripts/farm_world.gd"

const DATA = preload("res://scripts/life_data.gd")
const RESIDENTS = preload("res://scripts/ranch_data.gd")

func place_index() -> int:
	return DATA.AREAS.find(area_id)

func display_name() -> String:
	return DATA.NAMES[place_index()]

func entry_spawn(_from: String = "") -> Vector2:
	return Vector2(240,200)

func plot_at(_p: Vector2) -> int:
	return -1

func edge_destination(p: Vector2) -> String:
	return "town" if p.y>=211 and p.x>216 and p.x<264 else ""

func blocked(p: Vector2) -> bool:
	if not Rect2(12,52,456,165).has_point(p): return true
	for rect in [Rect2(64,92,112,48),Rect2(304,92,94,40)]:
		if rect.grow(3).has_point(p): return true
	if place_index() in [0,2] and Rect2(322,140,74,28).has_point(p): return true
	return false

func resident_position(id: String) -> Vector2:
	return RESIDENTS.visitor_position(id,area_id,state.minute,state.is_raining())

func interactions() -> Dictionary:
	var result := {"town":Vector2(240,207),"culture_craft":Vector2(180,169),"culture_gather":Vector2(360,183)}
	for id in RESIDENTS.VISITORS:
		if RESIDENTS.visitor_area(id,state.minute,state.is_raining())==area_id: result["visitor:"+id]=resident_position(id)
	return result

func interaction_hitbox(id: String) -> Rect2:
	return Rect2(interactions()[id]-Vector2(17,32),Vector2(34,40))

func _draw() -> void:
	if state==null: return
	var index := place_index()
	ApprovedArt.calm_tile(self,0,Rect2(0,0,480,270))
	ApprovedArt.calm_tile(self,1 if index in [1,3] else 3,Rect2(35,172,410,32))
	ApprovedArt.calm_tile(self,1,Rect2(225,112,30,104))
	var building_ids := [[2,8],[9,3],[8,2],[1,4]]
	ApprovedArt.culture_building(self,index,Rect2(53,57,138,91))
	ApprovedArt.building(self,building_ids[index][1],Rect2(298,61,112,79))
	if index in [0,2]:
		ApprovedArt.tile(self,3,Rect2(322,140,74,28))
		for n in range(5): r(329+n*12+sin(elapsed+n)*2,150+(n%2)*9,6,1,"bcd6c3")
	if index==0:
		ApprovedArt.building(self,10,Rect2(198,52,68,74))
	elif index==1:
		for x in [280,292,304]:
			r(x,150,8,7,"667f81")
			r(x+2,148,5,3,"b7cac0")
	elif index==2:
		for x in range(268,315,12):
			r(x,147,7,8,"578966")
			r(x+1,145,5,3,"b6c991")
	else:
		for x in [270,290,310]:
			r(x,152,16,8,"9d754e")
			r(x,150,16,3,"e4c797")
	for p in [Vector2(8,98),Vector2(427,91),Vector2(24,225),Vector2(445,225)]:
		ApprovedArt.building(self,11 if index==2 else 10,Rect2(p,Vector2(47,61)))
	var layers: Array = [{"id":"hero","p":actor}]
	for id in RESIDENTS.VISITORS:
		if RESIDENTS.visitor_area(id,state.minute,state.is_raining())==area_id:
			layers.append({"id":id,"p":resident_position(id)})
	layers.sort_custom(func(a,b): return a["p"].y<b["p"].y)
	for item in layers:
		if item["id"]=="hero": person(actor)
		else:
			ApprovedArt.resident(self,item["p"],RESIDENTS.RESIDENTS[item["id"]]["sprite"],30,elapsed)
			label_at(item["p"]-Vector2(0,34),RESIDENTS.RESIDENTS[item["id"]]["name"])
	label_at(Vector2(180,160),"聚落工坊")
	label_at(Vector2(360,179),"今日已採集" if state.life["gathered"][area_id]==state.day else "聚落採集")
	label_at(Vector2(240,216),"返回雲橋鎮 ↓")
	if state.is_raining():
		for i in range(38):
			var p:=Vector2(fmod(i*37,480),50+fmod(i*23+elapsed*70,162))
			draw_line(p,p+Vector2(-2,5),Color("d6e4d488"),1)
