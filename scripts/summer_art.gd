extends RefCounted
const FRAMES = preload("res://scripts/summer_frames.gd")
const CROPS = preload("res://assets/pixel/summer/crops.png")
const FACILITIES = preload("res://assets/pixel/summer/facilities.png")
const EDRIC = preload("res://assets/pixel/summer/edric.png")
const SUYUE = preload("res://assets/pixel/summer/suyue.png")
static func region(data: Array) -> Rect2:
	return Rect2(data[0],data[1],data[2],data[3])
static func frame_region(texture: Texture2D, data: Array, original_size: Vector2) -> Rect2:
	var ratio := texture.get_size()/original_size
	var raw := region(data)
	return Rect2(raw.position*ratio,raw.size*ratio)
static func facility_region(data: Array) -> Rect2:
	return frame_region(FACILITIES,data,Vector2(2172,724))
static func crop(canvas: CanvasItem, id: String, feet: Vector2, stage: int) -> void:
	var row: int=["tomato","eggplant","lotus"].find(id)
	var data: Array=FRAMES.CROPS[row][clampi(stage,0,4)]
	var source := region(data)
	# Fit the canopy inside a 17px field cell; the lotus has its own pond planter.
	var width: float=26 if id=="lotus" else 16
	var height: float=22 if id=="lotus" else 21
	var scale_factor: float=minf(width/source.size.x,height/source.size.y)
	canvas.draw_texture_rect_region(CROPS,Rect2((feet-Vector2(source.size.x/2,source.size.y)*scale_factor).floor(),source.size*scale_factor),frame_region(CROPS,data,Vector2(1536,1024)))
static func resident(canvas: CanvasItem, feet: Vector2, index: int, height: float, idle: float, walk: float, direction: Vector2) -> void:
	var frames: Array=FRAMES.EDRIC if index==3 else FRAMES.SUYUE
	var row := 0
	if walk>=0:
		row=1 if direction.x<0 else 2 if direction.x>0 else 3 if direction.y<0 else 0
	var frame: int=int(walk*8)%4 if walk>=0 else 0
	var data: Array=frames[row][frame]
	var factor: float=height/(190.0 if index==3 else 296.0)
	var origin := feet
	if walk<0 and idle>=0:
		canvas.draw_set_transform(feet,0,Vector2(1,1+sin(idle*TAU/3.4)*0.012))
		origin=Vector2.ZERO
	canvas.draw_texture_rect_region(EDRIC if index==3 else SUYUE,Rect2((origin-Vector2(data[4],data[5])*factor).floor(),Vector2(data[2],data[3])*factor),frame_region(EDRIC if index==3 else SUYUE,data,Vector2(1024,1536) if index==3 else Vector2(1254,1254)))
	if walk<0 and idle>=0: canvas.draw_set_transform(Vector2.ZERO)
static func icon(parent: Control, id: String, rectangle: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas=CROPS
	atlas.region=frame_region(CROPS,FRAMES.CROPS[["tomato","eggplant","lotus"].find(id)][4],Vector2(1536,1024))
	var view := TextureRect.new()
	view.texture=atlas
	view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.position=rectangle.position
	view.size=rectangle.size
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(view)
	return view
