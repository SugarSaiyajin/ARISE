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

static func hero(canvas: CanvasItem, feet: Vector2, style: String, row: int, frame: int, height: float = 30) -> void:
	# One fixed scale per character keeps walk/tool poses from breathing in size.
	var layout: GDScript = F if style == "female" else M
	var data := hero_frame(style,row,frame)
	var factor: float = N.PIXEL_SCALE if row == 7 else layout.PIXEL_SCALE
	factor *= height/30.0
	var source := region(data)
	canvas.draw_texture_rect_region(hero_texture(style,row),Rect2((feet-Vector2(data[4],data[5])*factor).floor(),source.size*factor),source)

static func animal(canvas: CanvasItem, feet: Vector2, index: int, frame: int, height: float = 22) -> void:
	sprite(canvas,ANIMALS,A.FRAMES[index][frame],feet,height)

static func resident(canvas: CanvasItem, feet: Vector2, index: int, height: float = 30) -> void:
	sprite(canvas,RESIDENTS,R.FRAMES[index/3][index%3],feet,height*(0.8 if index==5 else 1.0))

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

static func ground(canvas: CanvasItem, town: bool = false) -> void:
	tile(canvas,2 if town else 0,Rect2(0,0,480,270))
	if town:
		tile(canvas,3,Rect2(247,42,37,190))
		tile(canvas,7,Rect2(247,138,37,18))
	else:
		tile(canvas,1,Rect2(45,191,394,21))
		tile(canvas,1,Rect2(274,107,24,105))
		tile(canvas,1,Rect2(68,113,76,18))
		tile(canvas,1,Rect2(296,114,166,17))
		tile(canvas,3,Rect2(249,64,77,41))
		tile(canvas,4,Rect2(30,67,110,14))
