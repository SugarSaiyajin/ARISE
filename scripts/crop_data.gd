extends RefCounted

const LEGACY := ["turnip", "wheat", "berry"]
const SPRING := ["turnip", "wheat", "berry", "carrot", "cabbage", "potato", "pea", "tea"]
const SUMMER := ["tomato", "eggplant", "lotus"]
const FIELD := ["turnip", "wheat", "berry", "carrot", "cabbage", "potato", "pea", "tea", "tomato", "eggplant"]
const ORDER := ["turnip", "wheat", "berry", "carrot", "cabbage", "potato", "pea", "tea", "tomato", "eggplant", "lotus"]
const CROPS := {
	"turnip": {"name": "白玉蕪菁", "days": 2, "seed_cost": 6, "price": 18},
	"wheat": {"name": "金穗小麥", "days": 3, "seed_cost": 10, "price": 32},
	"berry": {"name": "燈籠莓", "days": 4, "seed_cost": 14, "price": 48},
	"carrot": {"name": "紅玉胡蘿蔔", "days": 3, "seed_cost": 12, "price": 36},
	"cabbage": {"name": "青葉甘藍", "days": 5, "seed_cost": 22, "price": 70},
	"potato": {"name": "奶油馬鈴薯", "days": 4, "seed_cost": 18, "price": 56},
	"pea": {"name": "翡翠豌豆", "days": 3, "seed_cost": 16, "price": 45},
	"tea": {"name": "春芽茶", "days": 6, "seed_cost": 28, "price": 96},
	"tomato": {"name":"朱果番茄", "days":5, "seed_cost":20, "price":70},
	"eggplant": {"name":"紫玉茄子", "days":6, "seed_cost":24, "price":90},
	"lotus": {"name":"清池蓮藕", "days":7, "seed_cost":28, "price":110},
}

static func initial_seeds() -> Dictionary:
	return {"turnip": 8, "wheat": 5, "berry": 3, "carrot": 1, "cabbage": 1, "potato": 1, "pea": 1, "tea": 1, "tomato":0, "eggplant":0, "lotus":0}
