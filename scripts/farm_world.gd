extends Node2D

const ApprovedArt = preload("res://scripts/approved_art.gd")
const MAP = preload("res://data/maps/farm.tres")
const State = preload("res://scripts/farm_state.gd")
const FacingFilter = preload("res://scripts/facing_filter.gd")
const CropVisual = preload("res://scripts/crop_visual.gd")
const FIELD := Vector2(150, 122)
const CELL := 17
const HOUSE := Vector2(81, 123)
const BOX := Vector2(123, 139)
const SHOP := Vector2(367, 132)
const NEIGHBOR := Vector2(329, 164)
const TOWN_GATE := Vector2(454, 116)
const FARM_FISHING := Vector2(282, 116)
const FENCE := Vector2(330, 195)
const COOP := Vector2(310, 177)
const COOP_SPRITES = preload("res://assets/pixel/chicken_coop.png")
const HEN = preload("res://assets/pixel/hen.png")
const DRYER := Vector2(105, 198)
const DRYER_SPRITES = preload("res://assets/pixel/drying_rack.png")
const OBSTACLES := [Rect2(39, 72, 74, 44), Rect2(249, 64, 77, 41), Rect2(353, 85, 61, 38), Rect2(376, 159, 42, 28), Rect2(218, 95, 12, 12), Rect2(87, 170, 36, 14), Rect2(321, 160, 43, 24)]
const TREE_POINTS := [Vector2(18,80),Vector2(20,174),Vector2(451,80),Vector2(463,173)]
const GROUND = preload("res://assets/pixel/ground.png")
const SOIL = preload("res://assets/pixel/soil.png")
const HERO = preload("res://assets/pixel/hero_eight.png")
const HERO_LAYOUT = preload("res://scripts/hero_frames.gd")
const QINGHE = preload("res://assets/pixel/qinghe.png")
const TREE = preload("res://assets/pixel/tree.png")
const AUTUMN = preload("res://assets/pixel/tree_autumn.png")
const FARMHOUSE = preload("res://assets/pixel/farmhouse.png")
const MARKET = preload("res://assets/pixel/market.png")
const TEA = preload("res://assets/pixel/tea_pavilion.png")
const CROPS = preload("res://assets/pixel/crops.png")
const PROPS = preload("res://assets/pixel/props.png")
const ACTION_DURATION := preload("res://scripts/tool_action.gd").DURATION
var state: RefCounted
var area_id: String = "farm"
var actor := Vector2(232, 200)
var facing := Vector2.DOWN
var facing_filter := FacingFilter.new()
var walking := false
var selected_plot := -1
var elapsed := 0.0
var walk_time := 0.0
var particles: Array = []
var font: Font
var action_age := ACTION_DURATION
var action_managed := false
var action_tool := 0
var action_target := Vector2.ZERO
var action_crop := "turnip"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func interactions() -> Dictionary:
	return MAP.anchors.duplicate()

func interaction_hitbox(id: String) -> Rect2:
	return MAP.hitboxes.get(id, Rect2(interactions()[id] - Vector2(15,32), Vector2(30,42)))

func entry_spawn(from_area: String = "") -> Vector2:
	if from_area == "house":
		return Vector2(81, 132)
	if from_area == "town":
		return Vector2(440, 116)
	return MAP.spawn

func edge_destination(p: Vector2) -> String:
	return "town" if p.x >= 465 and p.y > 100 and p.y < 132 else ""

func display_name() -> String:
	return MAP.title

func plot_center(index: int) -> Vector2:
	return FIELD + Vector2(index % State.COLS, index / State.COLS) * CELL + Vector2(8, 8)

func plot_at(p: Vector2) -> int:
	var local := p - FIELD
	if local.x < 0 or local.y < 0 or local.x >= State.COLS * CELL or local.y >= State.ROWS * CELL:
		return -1
	return int(local.y / CELL) * State.COLS + int(local.x / CELL)

func blocked(p: Vector2) -> bool:
	if not MAP.walkable.has_point(p):
		return true
	for rect in MAP.obstacles:
		if rect.grow(3).has_point(p):
			return true
	for tree_pos in TREE_POINTS:
		if Rect2(tree_pos - Vector2(3, 3), Vector2(6, 6)).has_point(p):
			return true
	return false

static func direction_row(direction: Vector2) -> int:
	return FacingFilter.nearest(direction)

func update_facing(direction: Vector2, snap: bool = false) -> void:
	facing = direction
	facing_filter.select(direction, snap)

static func cardinal_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x < 0 else 2
	return 3 if direction.y < 0 else 0

static func hero_region(row: int, frame: int) -> Rect2i:
	var data: Array = HERO_LAYOUT.FRAMES[row][frame]
	return Rect2i(data[0], data[1], data[2], data[3])

func play_action(tool: int, target: Vector2, crop: String = "turnip") -> void:
	action_tool = tool
	action_target = target
	action_crop = crop if State.CROPS.has(crop) else "turnip"
	action_age = 0
	if actor.distance_to(target) > 1:
		update_facing(actor.direction_to(target), true)
	else:
		update_facing(facing, true)

func emit_spark(p: Vector2, color: Color) -> void:
	for i in range(7):
		particles.append({"p": p + Vector2(0, -5), "v": Vector2(randf_range(-15, 15), randf_range(-30, -10)), "life": 0.7, "color": color})

func _process(delta: float) -> void:
	elapsed += delta
	if not action_managed:
		action_age = minf(action_age + delta, ACTION_DURATION)
	walk_time = walk_time + delta if walking else 0.0
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] -= delta
		particles[i]["p"] += particles[i]["v"] * delta
		particles[i]["v"].y += delta * 32
		if particles[i]["life"] <= 0:
			particles.remove_at(i)
	queue_redraw()

func r(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(floor(x), floor(y), w, h), Color(color))

func label_at(p: Vector2, text: String) -> void:
	if font == null:
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_rect(Rect2(p.x - width / 2 - 4, p.y - 9, width + 8, 13), Color("233e36e8"))
	draw_string(font, Vector2(p.x - width / 2, p.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f5e7c3"))

func hint_at(p: Vector2, text: String) -> void:
	if actor.distance_to(p)<88: label_at(p,text)

func prop(pos: Vector2, source: Rect2) -> void:
	var index := -1
	if source.position == Vector2(0,0): index = 4
	elif source.position == Vector2(24,0): index = 6
	elif source.position == Vector2(0,40): index = 7
	elif source.position.y == 40 and source.position.x >= 64: index = int((source.position.x-64)/16)
	if index >= 0:
		draw_texture_rect_region(ApprovedArt.ITEMS,Rect2(pos.floor(),source.size),ApprovedArt.region(ApprovedArt.I.FRAMES[0][index]))
	else:
		draw_texture_rect_region(PROPS, Rect2(pos.floor(), source.size), source)

func tree(pos: Vector2, autumn: bool = false) -> void:
	ApprovedArt.building(self,11 if autumn else 10,Rect2((pos-Vector2(24,52)).floor(),Vector2(48,56)))

func person(p: Vector2, npc: bool = false, sprite: Texture2D = null) -> void:
	draw_rect(Rect2((p - Vector2(5, 1)).floor(), Vector2(11, 2)), Color("314a3e80"))
	var direction := facing
	if npc:
		direction = p.direction_to(actor) if actor.distance_to(p) < 70 else Vector2.DOWN
	var texture: Texture2D = sprite if sprite != null else (QINGHE if npc else HERO)
	var row := facing_filter.row if texture == HERO else cardinal_row(direction)
	var frame := int(walk_time * 9) % 4 if walking and not npc else 0
	if not npc and action_age < ACTION_DURATION:
		frame = 4 + mini(3, int(action_age / ACTION_DURATION * 4))
	if texture == HERO:
		ApprovedArt.hero(self,p,state.hero_style if state != null else "male",row,frame,30,elapsed if not walking and action_age >= ACTION_DURATION else -1)
	else:
		draw_texture_rect_region(texture,
			Rect2((p - Vector2(16, 30)).floor(), Vector2(32, 32)),
			Rect2(frame * 32, row * 32, 32, 32))
	if not npc and action_age < ACTION_DURATION:
		var progress := action_age / ACTION_DURATION
		var offset := direction.normalized() * 8 + Vector2(0, -11 - sin(progress * PI) * 5)
		var tool_angle := (-0.8 + progress * 1.6) if action_tool in [0, 3] else sin(progress * PI) * 0.3
		draw_set_transform((p + offset).floor(), tool_angle)
		prop(Vector2(-8, -8), Rect2(64 + action_tool * 16, 40, 16, 16))
		draw_set_transform(Vector2.ZERO)

func crop_at(index: int, p: Dictionary) -> void:
	if p["crop"] == "":
		return
	var center := plot_center(index)
	var row := State.CROP_ORDER.find(p["crop"])
	var stage: int = 3 if state.is_mature(p) else mini(int(p["growth"] * 3.0 / State.CROPS[p["crop"]]["days"]), 2)
	CropVisual.draw(self,p["crop"],center,stage)
	if state.is_mature(p) and int(elapsed * 2 + index) % 4 == 0:
		r(center.x + 5, center.y - 15, 1, 3, "fff0b7")
		r(center.x + 4, center.y - 14, 3, 1, "fff0b7")

func _depth_layer() -> void:
	var objects: Array = [
		{"y": 121.0, "kind": "house"}, {"y": 126.0, "kind": "market"},
		{"y": 143.0, "kind": "well"}, {"y": 143.0, "kind": "crate"},
		{"y": 189.0, "kind": "tea"}, {"y": 187.0, "kind": "coop"},
		{"y": actor.y, "kind": "hero"},
		{"y": 183.0, "kind": "dryer"},
	]
	for i in range(state.chickens):
		var point := Vector2(333 + (i % 2) * 16, 187 + (i / 2) * 10) + Vector2(sin(elapsed * 1.5 + i * 2) * 2, 0)
		objects.append({"y": point.y, "kind": "hen", "p": point, "i": i})
	for p in TREE_POINTS:
		objects.append({"y": p.y, "kind": "tree", "p": p})
	for i in range(state.plots.size()):
		if state.plots[i]["crop"] != "":
			objects.append({"y": plot_center(i).y + 2, "kind": "crop", "index": i})
	objects.sort_custom(func(a: Dictionary, b: Dictionary): return a["y"] < b["y"])
	for item in objects:
		match item["kind"]:
			"coop":
				ApprovedArt.building(self,5,Rect2(315,141,56,48))
			"hen":
				var frame := int(elapsed * 2 + item["i"]) % 4
				ApprovedArt.animal(self,item["p"],0,1 if frame==1 else 0,16)
			"dryer":
				var stage := 0
				if state.rack_built:
					stage = 1 if state.processing_job.is_empty() else (3 if state.processing_ready() else 2)
				draw_texture_rect_region(ApprovedArt.ITEMS,Rect2(81,145,48,40),ApprovedArt.region(ApprovedArt.I.FRAMES[0][5]))
			"tree": tree(item["p"])
			"autumn": tree(Vector2(429, 145), true)
			"house": ApprovedArt.building(self,0,Rect2(36,49,96,74))
			"market": ApprovedArt.building(self,1,Rect2(354,65,80,62))
			"well": prop(Vector2(213, 78), Rect2(24, 0, 23, 34))
			"crate": prop(Vector2(111, 123), Rect2(0, 0, 24, 24))
			"cart": prop(Vector2(308, 183), Rect2(56, 0, 40, 24))
			"tea": ApprovedArt.building(self,2,Rect2(377,146,52,42))
			"npc": person(NEIGHBOR, true)
			"hero": person(actor)
			"crop": crop_at(item["index"], state.plots[item["index"]])

func _draw() -> void:
	if state == null:
		return
	ApprovedArt.ground(self)
	for i in range(state.plots.size()):
		var p: Dictionary = state.plots[i]
		var center := plot_center(i)
		var soil_stage := (2 if p["watered"] else 1) if p["tilled"] else 0
		draw_texture_rect_region(SOIL, Rect2(center - Vector2(8, 8), Vector2(17, 17)),
			Rect2(soil_stage * 17, 0, 17, 17))
	for x in range(141, 272, 16):
		prop(Vector2(x, 104), Rect2(0, 40, 16, 16))
		if x < 205 or x > 229:
			prop(Vector2(x, 185), Rect2(0, 40, 16, 16))
	if selected_plot >= 0:
		var c := plot_center(selected_plot)
		for offset in [Vector2(-8, -8), Vector2(5, -8), Vector2(-8, 5), Vector2(5, 5)]:
			draw_rect(Rect2(c + offset, Vector2(4, 4)), Color("f5dba480"))
	# The repaired boundary remains decorative and keeps the walking routes open.
	for x in range(300, 371, 14):
		if state.fence_repaired:
			r(x, 205, 14, 4, "9eaa90")
			r(x + 2, 195, 3, 13, "b69564")
			r(x, 198, 14, 2, "d8bd85")
		else:
			r(x + 2, 202, 3, 6, "7f7155")
	label_at(Vector2(330, 213), "圍欄已修復" if state.fence_repaired else "待修圍欄")
	_depth_layer()
	if state.life["irrigator"]:
		r(138,104,11,4,"9b774f")
		r(141,96,5,10,"719c96")
		r(142,94,3,7,"badfd0")
		r(137,100,13,2,"c9a66f")
		hint_at(Vector2(143,92),"符玉灌溉器")
	# Actual water ripples, smoke and fireflies are the animated layer over the atlas.
	for i in range(8):
		var x := 262 + (i * 11) % 48
		var y := 74 + (i * 7) % 20
		r(x + int(sin(elapsed + i) * 2), y, 4, 1, "b1cdc088")
	for i in range(3):
		var phase := fmod(elapsed * 5 + i * 8, 25)
		r(109 + sin(phase / 6) * 2, 51 - phase, 3 + phase / 10, 2, "ecdfbf55")
	hint_at(Vector2(280, 62), "池塘釣點")
	hint_at(Vector2(80, 72), "雲棲莊園")
	hint_at(Vector2(382, 88), "行旅種子鋪")
	hint_at(Vector2(123, 119), "出貨")
	hint_at(Vector2(343, 140), ("雞舍 · 有蛋" if state.nest_eggs > 0 else "雞舍") if state.coop_built else "建造雞舍")
	hint_at(Vector2(105, 143), "烘乾架" if state.rack_built else "建造烘乾架")
	hint_at(Vector2(397, 161), "歇腳茶亭")
	r(446, 117, 2, 11, "846743")
	r(438, 117, 23, 7, "b28b58")
	label_at(Vector2(440, 109), "雲橋鎮 →")
	for x in [15,463]:
		tree(Vector2(x,254))
	for particle in particles:
		draw_rect(Rect2(particle["p"].floor(), Vector2(2, 2)), particle["color"])
	if action_age < ACTION_DURATION:
		var progress := action_age / ACTION_DURATION
		if action_tool == 2:
			for i in range(5):
				var p := actor.lerp(action_target, progress) + Vector2(i - 2, -6 + progress * 6)
				r(p.x, p.y, 1, 2, "c3e1d9")
		elif action_tool == 3:
			var row := State.CROP_ORDER.find(action_crop)
			var p := action_target - Vector2(8, 14 + sin(progress * PI) * 12)
			if row >= 3:
				CropVisual.draw(self,action_crop,p+Vector2(8,12),3)
			else:
				draw_texture_rect_region(CROPS, Rect2(p.floor(), Vector2(16, 16)),
					Rect2(3 * 24 + 4, row * 24 + 4, 16, 16))
	if state.is_raining():
		draw_rect(Rect2(0, 40, 480, 185), Color("425b7b20"))
		for i in range(55):
			var x := fposmod(i * 37.0 - elapsed * 18, 480)
			var y := fmod(i * 23.0 + elapsed * 70, 175) + 42
			draw_line(Vector2(x, y), Vector2(x - 2, y + 4), Color("d0e4de66"), 1)
	if state.minute >= 1080:
		var alpha := clampf((state.minute - 1080) / 240.0, 0, 1) * 0.36
		draw_rect(Rect2(0, 0, 480, 270), Color(0.14, 0.18, 0.3, alpha))
