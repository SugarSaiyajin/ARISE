extends RefCounted
const F = preload("res://scripts/resident_walk_frames.gd")
const TEXTURES := {
	"qinghe":preload("res://assets/pixel/resident_walk/qinghe.png"),
	"luoan":preload("res://assets/pixel/resident_walk/luoan.png"),
	"rein":preload("res://assets/pixel/resident_walk/rein.png"),
	"lyria":preload("res://assets/pixel/resident_walk/lyria.png"),
	"borin":preload("res://assets/pixel/resident_walk/borin.png"),
	"yunji":preload("res://assets/pixel/resident_walk/yunji.png"),
	"qinglin":preload("res://assets/pixel/resident_walk/qinglin.png"),
}
const IDS := {0:"qinghe",1:"luoan",2:"rein",4:"lyria",5:"borin",6:"yunji",8:"qinglin"}
static func draw(canvas: CanvasItem, feet: Vector2, index: int, height: float, idle: float, walk: float, direction: Vector2) -> void:
	var id: String=IDS[index]
	var row := 0
	if walk>=0: row=1 if direction.x<0 else 2 if direction.x>0 else 3 if direction.y<0 else 0
	var data: Array=F.FRAMES[id][row][int(walk*8)%4 if walk>=0 else 0]
	var factor: float=height*(0.8 if index==5 else 1.0)/F.HEIGHTS[id]
	var origin := feet
	if walk<0 and idle>=0:
		canvas.draw_set_transform(feet,sin(idle*TAU/8)*0.004,Vector2(1,1+sin(idle*TAU/3.4)*0.012))
		origin=Vector2.ZERO
	var texture: Texture2D=TEXTURES[id]
	var ratio := texture.get_size()/Vector2(F.SIZES[id][0],F.SIZES[id][1])
	canvas.draw_texture_rect_region(texture,Rect2((origin-Vector2(data[4],data[5])*factor).floor(),Vector2(data[2],data[3])*factor),Rect2(Vector2(data[0],data[1])*ratio,Vector2(data[2],data[3])*ratio))
	if walk<0 and idle>=0: canvas.draw_set_transform(Vector2.ZERO)
