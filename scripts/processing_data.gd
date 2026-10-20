extends RefCounted

const BUILD_COST := {"wood": 4, "stone": 2, "money": 60}
const LEGACY := ["dried_turnip", "dried_wheat", "dried_berry"]
const ORDER := ["dried_turnip", "dried_wheat", "dried_berry", "dried_carrot", "pickled_cabbage", "potato_crisps", "pea_crisps", "spring_tea"]
const RECIPES := {
	"dried_carrot": {"name": "胡蘿蔔乾", "crop": "carrot", "price": 54},
	"pickled_cabbage": {"name": "甘藍漬", "crop": "cabbage", "price": 108},
	"potato_crisps": {"name": "薄薯片", "crop": "potato", "price": 84},
	"pea_crisps": {"name": "豌豆脆", "crop": "pea", "price": 68},
	"spring_tea": {"name": "初晴春茗", "crop": "tea", "price": 144},
	"dried_turnip": {"name": "蕪菁乾", "crop": "turnip", "price": 28},
	"dried_wheat": {"name": "乾燥麥穗", "crop": "wheat", "price": 46},
	"dried_berry": {"name": "莓果乾", "crop": "berry", "price": 72},
}
const MAX_STOCK := 100000000
