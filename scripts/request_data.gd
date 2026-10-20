extends RefCounted

const ORDER := ["tea_vegetables", "bridge_repairs", "caravan_treats"]
const REQUESTS := {
	"tea_vegetables": {"title": "茶館的時蔬", "recipient": "npc", "resident": "青禾", "produce": {"turnip": 2}, "materials": {}, "goods": {}, "reward": 50, "friendship": 1},
	"bridge_repairs": {"title": "橋邊的小修繕", "recipient": "smith", "resident": "雷恩", "produce": {}, "materials": {"wood": 4, "stone": 2}, "goods": {}, "reward": 50, "friendship": 0},
	"caravan_treats": {"title": "商隊的茶點", "recipient": "shop", "resident": "洛安", "produce": {}, "materials": {}, "goods": {"dried_berry": 1}, "reward": 100, "friendship": 0},
}
const TEA_PAGES := [
	"青禾把窗邊的位置留給了你。\n\n「以前商隊過橋，總會在這裡歇腳。有人帶來西陸的鐘，也有人帶來東洲的茶種。」",
	"風掀起茶簾，橋頭的鐘恰好響了一聲。\n\n「後來商路冷清了。你把莊園的田種起來，我忽然覺得，窗外又有了等人的理由。」",
	"青禾把一小包霧香草推到你面前。\n\n「下次路過，帶一點田裡的故事來就好。雲橋很大，也可以慢慢變成你的家。」",
]
