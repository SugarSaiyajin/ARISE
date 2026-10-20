extends RefCounted

const ORDER := ["npc", "shop", "smith"]
const NAMES := {"npc": "青禾", "shop": "洛安", "smith": "雷恩"}
const HOMES := {"npc": Vector2(108, 144), "shop": Vector2(367, 144), "smith": Vector2(331, 181)}
const SCHEDULES := {
	"npc": [[420, Vector2(108,144)], [600, Vector2(108,144)], [620, Vector2(190,144)], [760, Vector2(190,144)], [780, Vector2(108,144)], [1080, Vector2(108,144)], [1095, Vector2(190,144)], [1105, Vector2(190,180)], [1260, Vector2(190,180)], [1270, Vector2(190,144)], [1285, Vector2(108,144)], [1320, Vector2(108,144)]],
	"shop": [[420, Vector2(367,144)], [600, Vector2(367,144)], [620, Vector2(300,147)], [760, Vector2(300,147)], [780, Vector2(367,144)], [1080, Vector2(367,144)], [1095, Vector2(430,147)], [1105, Vector2(430,180)], [1260, Vector2(430,180)], [1270, Vector2(430,147)], [1285, Vector2(367,144)], [1320, Vector2(367,144)]],
	"smith": [[420, Vector2(331,181)], [600, Vector2(331,181)], [608, Vector2(315,181)], [620, Vector2(315,147)], [760, Vector2(315,147)], [772, Vector2(315,181)], [780, Vector2(331,181)], [1080, Vector2(331,181)], [1090, Vector2(315,181)], [1105, Vector2(315,147)], [1110, Vector2(300,147)], [1260, Vector2(300,147)], [1265, Vector2(315,147)], [1275, Vector2(315,181)], [1285, Vector2(331,181)], [1320, Vector2(331,181)]],
}
const EVENTS := {
	"shop": {"title": "洛安 · 遠路的帳簿", "pages": [
		"洛安翻開一冊用麻繩繫住的帳簿。東洲茶種的名字旁，寫著西陸港口的收貨記號。\n\n「路斷了以後，這些名字就只剩墨跡。你修好的，是人們能再次來往的日子。」",
		"你提起舊驛站的兩種文字。洛安指著帳頁邊上的星紋：那是舊商隊約定平安歸來的記號。\n\n「把田種好，把橋留給別人走。這就是雲橋人的約定。」",
		"他把一小袋春茶種子放進你的掌心。\n\n「市集開幕時，帶一份自己的收成來。到那時，帳簿上也該有你的名字了。」"]},
	"smith": {"title": "雷恩 · 鐘聲與星紋", "pages": [
		"雷恩把星紋殘片放在柔軟的布上，取出師父留下的鐘樓圖紙。圖紙上的符環，與殘片邊緣互相呼應。\n\n「這不是武器，是記錄潮汐的刻度。」",
		"東洲的符印引導星光，西陸的晶石保存回聲。舊驛曾靠兩者合力，為遠行的人照亮歸途。\n\n雷恩輕敲鐘片，殘片亮起了一瞬。你記得，那正是初到雲橋時聽見的聲音。",
		"「答案還沒找齊，但你已經不是獨自一人。」\n\n雷恩將修整過的石料交給你。「等春日市集那天，我們一起讓鐘聲再響一次。」"]},
}

static func position(id: String, minute: float, raining: bool = false) -> Vector2:
	if raining:
		return HOMES[id]
	var points: Array = SCHEDULES[id]
	for i in range(1, points.size()):
		if minute <= points[i][0]:
			var a: Array = points[i-1]
			var b: Array = points[i]
			return (a[1] as Vector2).lerp(b[1], clampf((minute - a[0]) / float(b[0] - a[0]), 0, 1))
	return HOMES[id]

static func location_name(id: String, minute: float, raining: bool) -> String:
	if raining or minute < 600 or (minute >= 780 and minute < 1080) or minute >= 1285:
		return {"npc": "茶館前", "shop": "種子攤前", "smith": "鍛冶鋪前"}[id]
	return "廣場與橋邊" if minute < 780 else "晚間散步路線"
