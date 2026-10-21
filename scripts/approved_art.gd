extends RefCounted

const MALE = preload("res://assets/pixel/hero_m_approved.png")
const FEMALE = preload("res://assets/pixel/hero_f_approved.png")
const NE = preload("res://assets/pixel/hero_ne_approved.png")
const M = preload("res://scripts/approved_m_frames.gd")
const F = preload("res://scripts/approved_f_frames.gd")
const N = preload("res://scripts/approved_ne_frames.gd")
const ANIMALS = preload("res://assets/pixel/animals_approved.png")
const A = preload("res://scripts/animal_frames.gd")
const RESIDENTS = preload("res://assets/pixel/residents_approved.png")
const R = preload("res://scripts/residents_frames.gd")
const BUILDINGS = preload("res://assets/pixel/buildings_approved.png")
const B = preload("res://scripts/building_frames.gd")
const CULTURE = preload("res://assets/pixel/culture_buildings.png")
const CULTURE_FRAMES = preload("res://scripts/culture_frames.gd")
const CALM = preload("res://assets/pixel/calm_ground.png")
const FURNITURE = preload("res://assets/pixel/furniture_approved.png")
const FURNITURE_FRAMES = preload("res://scripts/furniture_frames.gd")
const TERRAIN = preload("res://assets/pixel/terrain_approved.png")
const ITEMS = preload("res://assets/pixel/items_approved.png")
const I = preload("res://scripts/item_frames.gd")

static func region(data: Array) -> Rect2:
	return Rect2(data[0],data[1],data[2],data[3])

static func hero_frame(style: String, row: int, frame: int) -> Array:
	return N.FRAMES[0 if style == "male" else 1][frame] if row == 7 else (F.FRAMES[row][frame] if style == "female" else M.FRAMES[row][frame])

static func hero_texture(style: String, row: int) -> Texture2D:
	return NE if row == 7 else (FEMALE if style == "female" else MALE)

static func sprite(canvas: CanvasItem, texture: Texture2D, data: Array, feet: Vector2, height: float) -> void:
	var source := region(data)
	var factor: float = height / (data[5]-4.0)
	var pivot: Vector2 = Vector2(data[4],data[5])*factor
	canvas.draw_texture_rect_region(texture,Rect2((feet-pivot).floor(),source.size*factor),source)

static func hero(canvas: CanvasItem, feet: Vector2, style: String, row: int, frame: int, height: float = 30, idle_seconds: float = -1) -> void:
	# One fixed scale per character keeps walk/tool poses from breathing in size.
	var layout: GDScript = F if style == "female" else M
	var data := hero_frame(style,row,frame)
	var factor: float = N.PIXEL_SCALE if row == 7 else layout.PIXEL_SCALE
	factor *= height/30.0
	var source := region(data)
	var origin := feet
	if idle_seconds >= 0:
		canvas.draw_set_transform(feet,sin(idle_seconds*TAU/7)*0.008,idle_scale(idle_seconds))
		origin = Vector2.ZERO
	canvas.draw_texture_rect_region(hero_texture(style,row),Rect2((origin-Vector2(data[4],data[5])*factor).floor(),source.size*factor),source)
	if idle_seconds>=0 and row==0 and frame==0 and fmod(idle_seconds,5.1)>4.94:
		# Eye rectangles are registered to the approved front pose's source pixels.
		var eyes := [Rect2(93,62,7,7),Rect2(117,61,8,8)] if style!="female" else [Rect2(125,74,6,5),Rect2(145,72,7,6)]
		for eye in eyes:
			var eyelid := Rect2(origin+(eye.position-source.position-Vector2(data[4],data[5]))*factor,eye.size*factor)
			canvas.draw_rect(eyelid,Color("f4c38a"))
			canvas.draw_line(eyelid.position+Vector2(0,eyelid.size.y*0.65),eyelid.position+Vector2(eyelid.size.x,eyelid.size.y*0.65),Color("65402b"),maxf(0.4,height*0.008))
	if idle_seconds >= 0: canvas.draw_set_transform(Vector2.ZERO)

static func animal(canvas: CanvasItem, feet: Vector2, index: int, frame: int, height: float = 22) -> void:
	sprite(canvas,ANIMALS,A.FRAMES[index][frame],feet,height)

static func resident(canvas: CanvasItem, feet: Vector2, index: int, height: float = 30, idle_seconds: float = -1, walk_seconds: float = -1, direction: Vector2 = Vector2.DOWN) -> void:
	if index in [3,7]:
		preload("res://scripts/summer_art.gd").resident(canvas,feet,index,height,idle_seconds,walk_seconds,direction)
		return
	var origin := feet
	if idle_seconds>=0:
		canvas.draw_set_transform(feet,0,idle_scale(idle_seconds+index*0.6))
		origin=Vector2.ZERO
	var data: Array=R.FRAMES[index/3][index%3]
	var actual_height := height*(0.8 if index==5 else 1.0)
	if walk_seconds<0:
		sprite(canvas,RESIDENTS,data,origin,actual_height)
	else:
		var source := region(data)
		var factor: float=actual_height/(data[5]-4.0)
		var target := Rect2((origin-Vector2(data[4],data[5])*factor).floor(),source.size*factor)
		var upper := source.size.y*0.73
		canvas.draw_texture_rect_region(RESIDENTS,Rect2(target.position,Vector2(target.size.x,upper*factor)),Rect2(source.position,Vector2(source.size.x,upper)))
		for leg in range(2):
			var offset := sin(walk_seconds*TAU*2.5+leg*PI)*actual_height*0.025
			canvas.draw_texture_rect_region(RESIDENTS,Rect2(target.position+Vector2(leg*target.size.x/2,upper*factor+offset),Vector2(target.size.x/2,target.size.y-upper*factor)),Rect2(source.position+Vector2(leg*source.size.x/2,upper),Vector2(source.size.x/2,source.size.y-upper)))
	if idle_seconds>=0: canvas.draw_set_transform(Vector2.ZERO)

static func building(canvas: CanvasItem, index: int, rectangle: Rect2) -> void:
	var source := region(B.FRAMES[index/4][index%4])
	canvas.draw_texture_rect_region(BUILDINGS,rectangle,source)

static func icon(parent: Control, texture: Texture2D, data: Array, rectangle: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region(data)
	var view := TextureRect.new()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.texture = atlas
	view.position = rectangle.position
	view.size = rectangle.size
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(view)
	return view

static func tile(canvas: CanvasItem, index: int, rect: Rect2) -> void:
	var size := Vector2(TERRAIN.get_width()/4.0,TERRAIN.get_height()/2.0)
	var source := Rect2(Vector2(index%4,index/4)*size,size)
	for y in range(int(rect.position.y),int(rect.end.y),16):
		for x in range(int(rect.position.x),int(rect.end.x),16):
			var target := Rect2(x,y,minf(16,rect.end.x-x),minf(16,rect.end.y-y))
			canvas.draw_texture_rect_region(TERRAIN,target,Rect2(source.position,source.size*target.size/16.0))

static func idle_scale(seconds: float) -> Vector2:
	var phase := sin(seconds*TAU/3.4)
	var stretch := sin(clampf((fmod(seconds,12.0)-10.4)/1.6,0,1)*PI)
	return Vector2(1+phase*0.006-stretch*0.02,1+phase*0.018+stretch*0.035)

static func calm_tile(canvas: CanvasItem, index: int, rect: Rect2) -> void:
	var source := Rect2(index*CALM.get_width()/4.0,0,CALM.get_width()/4.0,CALM.get_height())
	for y in range(int(rect.position.y),int(rect.end.y),24):
		for x in range(int(rect.position.x),int(rect.end.x),24):
			var target := Rect2(x,y,minf(24,rect.end.x-x),minf(24,rect.end.y-y))
			canvas.draw_texture_rect_region(CALM,target,Rect2(source.position,source.size*target.size/24.0))

static func furniture(canvas: CanvasItem, index: int, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(FURNITURE,rect,region(FURNITURE_FRAMES.FRAMES[index/4][index%4]))

static func ground(canvas: CanvasItem, town: bool = false) -> void:
	calm_tile(canvas,0,Rect2(0,0,480,270))
	if town:
		# Plazas sit on quiet warm limestone, with planted edges and one clear bridge.
		calm_tile(canvas,1,Rect2(34,123,412,41))
		calm_tile(canvas,1,Rect2(178,104,66,99))
		calm_tile(canvas,1,Rect2(292,132,148,80))
		tile(canvas,3,Rect2(247,42,37,190))
		calm_tile(canvas,1,Rect2(247,138,37,18))
	else:
		# House -> field edge -> work yard -> east town gate; no paths through plots.
		calm_tile(canvas,3,Rect2(28,192,427,24))
		calm_tile(canvas,3,Rect2(132,115,15,86))
		calm_tile(canvas,3,Rect2(72,118,73,24))
		calm_tile(canvas,3,Rect2(280,111,27,102))
		calm_tile(canvas,3,Rect2(304,114,160,24))
		tile(canvas,3,Rect2(249,64,77,41))
		calm_tile(canvas,3,Rect2(86,181,47,26))

static func culture_building(canvas: CanvasItem, index: int, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(CULTURE,rect,region(CULTURE_FRAMES.FRAMES[index/2][index%2]))

static func farm_ground(canvas: CanvasItem, layout: int) -> void:
	ground(canvas)
	if layout==1:
		calm_tile(canvas,1,Rect2(128,192,182,19))
		calm_tile(canvas,1,Rect2(275,116,14,92))
	elif layout==2:
		calm_tile(canvas,3,Rect2(128,110,180,10))
		calm_tile(canvas,3,Rect2(274,113,15,99))
		calm_tile(canvas,1,Rect2(70,186,64,26))
