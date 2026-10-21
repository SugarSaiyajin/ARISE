extends RefCounted
const NAMES := ["床鋪","書桌","爐灶","茶桌","書架","屏風","收納箱","地毯"]
const RECTS := [Rect2(302,76,50,38),Rect2(146,82,49,30),Rect2(109,133,29,38),Rect2(216,130,35,25),Rect2(334,139,33,40),Rect2(275,82,22,35),Rect2(154,162,26,19),Rect2(197,127,66,43)]
const SOLIDS := [Rect2(305,81,45,30),Rect2(146,84,49,25),Rect2(112,136,23,33),Rect2(218,137,30,18),Rect2(335,145,30,28),Rect2(275,88,22,21),Rect2(154,165,26,16)]
const DEFAULT_ANCHORS := {"home_storage":Vector2(187,180),"home_chair":Vector2(201,154),"bed":Vector2(312,120),"journal":Vector2(172,120),"tea":Vector2(146,158),"farm":Vector2(239,197)}
const INTERACTIONS := {"bed":0,"journal":1,"tea":2,"home_chair":3,"home_storage":6}
const WALKABLE := Rect2(112,80,256,128)
const VISUAL_ROOM := Rect2(108,76,264,135)
static var validation_cache: Dictionary={}
static func defaults() -> Array:
	var result: Array=[]
	for rect in RECTS: result.append([int(rect.position.x),int(rect.position.y),0])
	return result
static func rotate(point: Vector2, turns: int) -> Vector2:
	match turns:
		1: return Vector2(-point.y,point.x)
		2: return -point
		3: return Vector2(point.y,-point.x)
	return point
static func shape(layout: Array, index: int, solid: bool = false) -> Rect2:
	if solid and index==7: return Rect2()
	var base: Rect2=RECTS[index]
	var source: Rect2=SOLIDS[index] if solid else base
	var turns: int=int(layout[index][2])
	var size: Vector2=Vector2(source.size.y,source.size.x) if turns%2==1 else source.size
	var center := Vector2(layout[index][0],layout[index][1])+base.size/2+rotate(source.get_center()-base.get_center(),turns)
	return Rect2(center-size/2,size)
static func blocked(layout: Array, point: Vector2) -> bool:
	if not WALKABLE.has_point(point): return true
	for i in range(7):
		if shape(layout,i,true).grow(3).has_point(point): return true
	return false
static func anchors(layout: Array) -> Dictionary:
	if layout==defaults(): return DEFAULT_ANCHORS.duplicate()
	var result := {"farm":Vector2(239,197)}
	for key in INTERACTIONS:
		var rect := shape(layout,INTERACTIONS[key],true)
		result[key]=Vector2(-1,-1)
		var candidates := [Vector2(rect.get_center().x,rect.end.y+10),Vector2(rect.position.x-10,rect.get_center().y),Vector2(rect.end.x+10,rect.get_center().y),Vector2(rect.get_center().x,rect.position.y-10)]
		for point in candidates:
			var snapped := Vector2(Vector2i(point/8))*8+Vector2(4,4)
			if not blocked(layout,snapped):
				result[key]=snapped
				break
	return result
static func navigation(layout: Array) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region=Rect2i(0,0,60,28)
	grid.cell_size=Vector2(8,8)
	grid.offset=Vector2(4,4)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(28):
		for x in range(60): grid.set_point_solid(Vector2i(x,y),blocked(layout,Vector2(x*8+4,y*8+4)))
	return grid
static func reason(value: Variant) -> String:
	if not value is Array or value.size()!=8: return "家具配置資料不完整。"
	for entry in value:
		if not entry is Array or entry.size()!=3: return "家具位置格式不正確。"
		for number in entry:
			if not (number is int or number is float) or not is_finite(float(number)) or number!=int(number) or absf(float(number))>1000: return "家具位置需要有限整數。"
		if entry[2]<0 or entry[2]>3: return "旋轉只能為四個直角方向。"
	var key := JSON.stringify(value)
	if validation_cache.has(key): return validation_cache[key]
	var result := ""
	for i in range(8):
		if not VISUAL_ROOM.encloses(shape(value,i)): result="家具超出房間，請向內移動。"
		if i<7:
			for j in range(i):
				if shape(value,i,true).intersects(shape(value,j,true)): result="家具占位重疊；地毯可鋪在家具下方。"
	if blocked(value,Vector2(239,185)) or blocked(value,Vector2(239,197)): result="請保留入口與出門位置。"
	if result=="":
		var grid := navigation(value)
		for point in anchors(value).values():
			var end := Vector2i(point/8)
			if point.x<0 or not grid.is_in_boundsv(end) or grid.is_point_solid(end) or grid.get_point_path(Vector2i(239/8,197/8),end).is_empty(): result="有家具或出口無法走近，請留出通道。"
	if validation_cache.size()>128: validation_cache.clear()
	validation_cache[key]=result
	return result
static func valid(value: Variant) -> bool: return reason(value)==""
static func apply(s: RefCounted, layout: Array, guard: String) -> Dictionary:
	if s.area_id!="house" or guard!=JSON.stringify(s.to_data()).sha256_text(): return {"ok":false,"text":"請回農舍並重新預覽配置。"}
	var error := reason(layout)
	if error!="": return {"ok":false,"text":error}
	if blocked(layout,s.player_position): return {"ok":false,"text":"家具會蓋住主角，請先移開角色或調整位置。"}
	var grid := navigation(layout)
	var start := Vector2i(s.player_position/8)
	if grid.is_point_solid(start) or grid.get_point_path(start,Vector2i(239/8,197/8)).is_empty(): return {"ok":false,"text":"主角目前位置會被困住，請調整配置。"}
	s.interior=layout.duplicate(true)
	return {"ok":true,"text":"布置已套用，家具與互動通道一起更新。"}
static func draw(canvas: CanvasItem, layout: Array, index: int, tint: Color = Color.WHITE) -> void:
	var base: Rect2=RECTS[index]
	var position := Vector2(layout[index][0],layout[index][1])
	canvas.draw_set_transform(position+base.size/2,int(layout[index][2])*PI/2)
	var art=preload("res://scripts/approved_art.gd")
	canvas.draw_texture_rect_region(art.FURNITURE,Rect2(-base.size/2,base.size),art.region(art.FURNITURE_FRAMES.FRAMES[index/4][index%4]),tint)
	canvas.draw_set_transform(Vector2.ZERO)
