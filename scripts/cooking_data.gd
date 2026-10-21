extends RefCounted

const MAX_STOCK := 100000000
const LEGACY := ["turnip_soup", "egg_flatbread", "herb_fish"]
const ORDER := ["turnip_soup", "egg_flatbread", "herb_fish", "garden_stew", "pea_scone", "spring_tea", "honey_cake", "duck_pudding", "star_tea", "summer_stew", "eggplant_bake", "lotus_tea"]
const RECIPES := {
	"summer_stew":{"name":"番茄燉蔬","energy":50,"ingredients":[{"stock":"produce","item":"tomato","amount":1,"name":"朱果番茄"},{"stock":"produce","item":"potato","amount":1,"name":"奶油馬鈴薯"}]},
	"eggplant_bake":{"name":"茄子麥餅","energy":60,"ingredients":[{"stock":"produce","item":"eggplant","amount":1,"name":"紫玉茄子"},{"stock":"produce","item":"wheat","amount":1,"name":"金穗小麥"}]},
	"lotus_tea":{"name":"蓮藕香茶","energy":55,"ingredients":[{"stock":"produce","item":"lotus","amount":1,"name":"清池蓮藕"},{"stock":"materials","item":"herb","amount":1,"name":"霧香草"}]},
	"honey_cake":{"name":"蜂蜜麥餅","energy":65,"ingredients":[{"stock":"ranch","item":"bee","amount":1,"name":"花蜜蜂蜜"},{"stock":"produce","item":"wheat","amount":1,"name":"金穗小麥"}]},
	"duck_pudding":{"name":"莓香鴨蛋布丁","energy":55,"ingredients":[{"stock":"ranch","item":"duck","amount":1,"name":"鴨蛋"},{"stock":"produce","item":"berry","amount":1,"name":"燈籠莓"}]},
	"star_tea":{"name":"星露春茶","energy":70,"ingredients":[{"stock":"ranch","item":"carp","amount":1,"name":"靈池星露"},{"stock":"produce","item":"tea","amount":1,"name":"春芽茶"}]},
	"garden_stew": {"name": "田園燉蔬", "energy": 70, "ingredients": [
		{"stock": "produce", "item": "carrot", "amount": 1, "name": "紅玉胡蘿蔔"},
		{"stock": "produce", "item": "cabbage", "amount": 1, "name": "青葉甘藍"},
		{"stock": "produce", "item": "potato", "amount": 1, "name": "奶油馬鈴薯"}]},
	"pea_scone": {"name": "豌豆麥餅", "energy": 50, "ingredients": [
		{"stock": "produce", "item": "pea", "amount": 1, "name": "翡翠豌豆"},
		{"stock": "produce", "item": "wheat", "amount": 1, "name": "金穗小麥收成"}]},
	"spring_tea": {"name": "春芽香茶", "energy": 30, "ingredients": [
		{"stock": "produce", "item": "tea", "amount": 1, "name": "春芽茶收成"},
		{"stock": "materials", "item": "herb", "amount": 1, "name": "霧香草"}]},
	"turnip_soup": {"name": "白玉香草湯", "energy": 35, "ingredients": [
		{"stock": "produce", "item": "turnip", "amount": 2, "name": "白玉蕪菁收成"},
		{"stock": "materials", "item": "herb", "amount": 1, "name": "霧香草"}]},
	"egg_flatbread": {"name": "金穗煎蛋餅", "energy": 45, "ingredients": [
		{"stock": "produce", "item": "wheat", "amount": 1, "name": "金穗小麥收成"},
		{"stock": "eggs", "item": "", "amount": 1, "name": "行囊雞蛋"}]},
	"herb_fish": {"name": "霧香烤鯽", "energy": 40, "ingredients": [
		{"stock": "fish", "item": "silver_carp", "amount": 1, "name": "銀鱗鯽"},
		{"stock": "materials", "item": "herb", "amount": 1, "name": "霧香草"}]},
}
