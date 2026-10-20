extends RefCounted

const ROD_COST := {"wood": 4, "stone": 2, "money": 80}
const ENERGY_COST := 2
const DAILY_LIMIT := 3
const MAX_STOCK := 100000000
const WAIT_SECONDS := 1.8
const ORDER := ["silver_carp", "mist_trout", "star_perch"]
const FISH := {
	"silver_carp": {"name": "銀鱗鯽", "price": 32},
	"mist_trout": {"name": "霧泉鱒", "price": 48},
	"star_perch": {"name": "星紋鱸", "price": 72},
}
const GROUNDS := {
	"farm": {"fish": "silver_carp", "window": 1.6},
	"forest": {"fish": "mist_trout", "window": 1.4},
	"ruins": {"fish": "star_perch", "window": 1.2},
}
