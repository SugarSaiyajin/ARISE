extends Resource

@export var area_id := ""
@export var title := ""
@export var walkable := Rect2(9, 44, 462, 172)
@export var obstacles: Array[Rect2] = []
@export var anchors: Dictionary = {}
@export var hitboxes: Dictionary = {}
@export var spawn := Vector2(232, 200)
