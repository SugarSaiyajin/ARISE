extends RefCounted
const F=preload("res://scripts/autumn_frames.gd")
const CROPS=preload("res://assets/pixel/autumn/crops.png")
const OBJECTS=preload("res://assets/pixel/autumn/objects.png")
const SUMMER=preload("res://scripts/summer_art.gd")
static func crop(canvas: CanvasItem, id: String, feet: Vector2, stage: int) -> void:
	var data: Array=F.CROPS[["pumpkin","sweet_potato","grape"].find(id)][clampi(stage,0,4)]
	var scale_factor:=minf(16.0/data[2],23.0/data[3])
	canvas.draw_texture_rect_region(CROPS,Rect2((feet-Vector2(data[2]/2.0,data[3])*scale_factor).floor(),Vector2(data[2],data[3])*scale_factor),SUMMER.frame_region(CROPS,data,Vector2(1536,1024)))
static func object(canvas: CanvasItem, index: int, feet: Vector2, height: float) -> void:
	var data: Array=F.OBJECTS[index/4][index%4]
	var factor: float=height/data[3]
	canvas.draw_texture_rect_region(OBJECTS,Rect2((feet-Vector2(data[2]/2.0,data[3])*factor).floor(),Vector2(data[2],data[3])*factor),SUMMER.frame_region(OBJECTS,data,Vector2(1536,1024)))
static func icon(parent: Control, id: String, rectangle: Rect2) -> void:
	var atlas:=AtlasTexture.new()
	atlas.atlas=CROPS
	atlas.region=SUMMER.frame_region(CROPS,F.CROPS[["pumpkin","sweet_potato","grape"].find(id)][4],Vector2(1536,1024))
	var view:=TextureRect.new()
	view.texture=atlas
	view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.position=rectangle.position
	view.size=rectangle.size
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
