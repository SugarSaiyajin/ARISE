extends RefCounted

const MAX_STOCK := 100000000
const LEGACY := ["turnip_soup", "egg_flatbread", "herb_fish"]
const ORDER := ["turnip_soup", "egg_flatbread", "herb_fish", "garden_stew", "pea_scone", "spring_tea"]
const RECIPES := {
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
