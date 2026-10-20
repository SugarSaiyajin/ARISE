extends RefCounted

const Crops = preload("res://scripts/crop_data.gd")
const Stocks = preload("res://scripts/stock_rules.gd")
const Residents = preload("res://scripts/resident_data.gd")
const LENGTH := 28
const FESTIVAL_DAY := 14
const FESTIVAL_PAGES := [
	"市集的長桌上，青瓷茶盞擺在西陸麵包旁。你帶來的收成，與居民的料理一起冒著熱氣。\n\n青禾替每個人斟茶，洛安把第一張春帖貼上橋柱。",
	"雷恩敲響修好的鐘片。殘片在你手中映出微光，像遠處有人回應。\n\n「符印與晶石，守望同一座橋。」你終於懂得碑文裡的約定。",
	"大家把一張印著雲橋的春帖交給你。\n\n「明年，也把田裡的故事帶來吧。」\n\n這一夜，異鄉的鐘聲有了家的方向。"]
const FINALE_PAGES := [
	"你將星紋的記錄攤在公告牌前。青禾、洛安和雷恩看著修好的莊園與重新通行的驛路，替你補上殘片缺失的故事。\n\n星潮曾讓兩地相遇，也把你帶到這裡。",
	"要追尋回去的路，需要更多星紋。但眼前已有你親手種下的田、願意等你喝茶的人，以及一條再次有人往來的商路。\n\n你把這一頁題作「雲橋初晴」。",
	"第一章完成。雲橋將你的名字記入驛站名冊，商隊送來 300 銀作為謝禮。\n\n春日仍在繼續。帶著新的線索，慢慢經營屬於你的生活吧。"]

static func empty_progress() -> Dictionary:
	return {"friends": {"shop": 0, "smith": 0}, "talk_days": {"shop": 0, "smith": 0},
		"events": {"shop": false, "smith": false}, "offering_year": 0, "offerings": [],
		"festival_year": 0, "chapter_done": false, "spring_complete": false}

static func season_day(day: int) -> int:
	return (day - 1) % LENGTH + 1

static func normalized(progress: Dictionary) -> Dictionary:
	var result := progress.duplicate(true)
	for category in ["friends", "talk_days"]:
		for id in ["shop", "smith"]:
			result[category][id] = int(result[category][id])
	for key in ["offering_year", "festival_year"]:
		result[key] = int(result[key])
	return result

static func year(day: int) -> int:
	return (day - 1) / LENGTH + 1

static func festival_open(s: RefCounted) -> bool:
	return season_day(s.day) >= FESTIVAL_DAY

static func talk(s: RefCounted, id: String) -> String:
	if id not in ["shop", "smith"] or s.area_id != "town":
		return "請到雲橋鎮找居民交談。"
	if s.spring_progress["talk_days"][id] != s.day:
		s.spring_progress["talk_days"][id] = s.day
		s.spring_progress["friends"][id] += 1
	if s.is_raining():
		return "雨天就慢慢來。棚下替你留了位置，田裡的水也不用操心。" if id == "shop" else "雨點敲在屋簷，和打鐵的聲音很像。今天先把爐火照顧好。"
	if s.minute >= 1080:
		return "收攤後，我喜歡沿橋走一走。遠方的路很長，眼前的晚風也值得記住。" if id == "shop" else "一天的爐火歇下了，手裡還留著暖意。你也該替自己留一點休息的時間。"
	return "種子裝得下很遠的風景。你今天想讓田裡多一點什麼？" if id == "shop" else "每一枚橋釘都要打得牢。修路、種田也是一樣，一天做一點，就能走得更遠。"

static func event_available(s: RefCounted, id: String) -> bool:
	return id in ["shop", "smith"] and s.area_id == "town" and not s.spring_progress["events"][id] and s.spring_progress["friends"][id] >= 3 and (s.route_restored if id == "shop" else s.relic_recovered)

static func finish_event(s: RefCounted, id: String) -> Dictionary:
	if not event_available(s, id):
		return {"ok": false, "text": "相識的條件尚未齊備，或這段故事已記下。"}
	if s.money > 999999999920:
		return {"ok":false,"text":"銀幣帳簿已滿，先整理後再記下故事。"}
	if (id == "shop" and s.seeds.get("tea", 0) > 99999997) or (id == "smith" and s.materials["stone"] > 99999997):
		return {"ok": false, "text": "獎勵物品已放滿，先整理行囊。"}
	if id == "shop":
		s.seeds["tea"] = s.seeds.get("tea", 0) + 3
	else:
		s.materials["stone"] += 3
	s.money += 80
	s.spring_progress["events"][id] = true
	return {"ok": true, "text": "故事記入手札，獲得 80 銀與%s。" % ("春茶種子 3 包" if id == "shop" else "石料 3 份")}

static func donate(s: RefCounted, crop: String) -> Dictionary:
	if s.area_id != "town" or not festival_open(s) or not Crops.CROPS.has(crop) or s.spring_progress["festival_year"] == year(s.day):
		return {"ok": false, "text": "春日市集於春 14 至 28 日開放，每年共赴春宴一次。"}
	var offerings: Array = s.spring_progress["offerings"] if s.spring_progress["offering_year"] == year(s.day) else []
	if offerings.size() >= 3 or crop in offerings or s.produce.get(crop, 0) < 1:
		return {"ok": false, "text": "請提供三種不同收成，每種一份；已提供或缺少的收成不再扣除。"}
	s.produce[crop] -= 1
	if s.spring_progress["offering_year"] != year(s.day):
		s.spring_progress["offering_year"] = year(s.day)
		s.spring_progress["offerings"] = []
	s.spring_progress["offerings"].append(crop)
	return {"ok": true, "text": "將一份%s放上春宴長桌。" % Crops.CROPS[crop]["name"]}

static func can_celebrate(s: RefCounted) -> bool:
	return s.area_id == "town" and festival_open(s) and s.spring_progress["festival_year"] != year(s.day) and s.spring_progress["offering_year"] == year(s.day) and s.spring_progress["offerings"].size() == 3

static func celebrate(s: RefCounted) -> Dictionary:
	if not can_celebrate(s):
		return {"ok": false, "text": "請在市集開放時備齊三種收成，每年可參加一次。"}
	if s.money > 999999999880:
		return {"ok":false,"text":"銀幣帳簿已滿，春宴準備會保留。"}
	s.spring_progress["festival_year"] = year(s.day)
	s.money += 120
	return {"ok": true, "text": "春宴完成：獲得雲橋春帖與 120 銀，回憶記入手札。"}

static func objectives(s: RefCounted) -> Array:
	return [
		{"text": "收穫五份作物，找青禾領初耕謝禮", "done": s.reward_claimed},
		{"text": "修好莊園圍欄，完成兩件居民委託", "done": s.fence_repaired and s.requests_completed >= 2},
		{"text": "修復霧杉林東側驛路", "done": s.route_restored},
		{"text": "在星潮舊驛收藏星紋殘片", "done": s.relic_recovered},
		{"text": "赴青禾茶會，聽洛安與雷恩的故事", "done": s.tea_event_seen and s.spring_progress["events"]["shop"] and s.spring_progress["events"]["smith"]},
		{"text": "春日市集提供三種收成，共赴春宴", "done": s.spring_progress["festival_year"] > 0},
	]

static func can_finish(s: RefCounted) -> bool:
	return s.area_id == "town" and not s.spring_progress["chapter_done"] and objectives(s).all(func(o): return o["done"])

static func next_objective(s: RefCounted) -> String:
	if s.spring_progress["chapter_done"]:
		return "第一章完成 · 繼續經營你的春日莊園"
	for objective in objectives(s):
		if not objective["done"]:
			return objective["text"]
	return "回雲橋公告牌，記下第一章結尾"

static func finish_chapter(s: RefCounted) -> Dictionary:
	if not can_finish(s):
		return {"ok": false, "text": "請先完成手札上的六項目標，再回公告牌記下第一章。"}
	if s.money > 999999999700:
		return {"ok":false,"text":"銀幣帳簿已滿，章節結尾可稍後再記下。"}
	s.spring_progress["chapter_done"] = true
	s.money += 300
	return {"ok": true, "text": "第一章「雲橋初晴」完成，獲得驛站名冊紀念與 300 銀。"}

static func valid(progress: Variant, data: Dictionary) -> bool:
	if not progress is Dictionary or progress.size() != empty_progress().size():
		return false
	for key in ["friends", "talk_days"]:
		if not Stocks.valid(progress.get(key), ["shop", "smith"], ["shop", "smith"], int(data["day"]) if key == "talk_days" else 100000000):
			return false
	var events: Variant = progress.get("events")
	if not events is Dictionary or events.size() != 2 or not events.get("shop") is bool or not events.get("smith") is bool:
		return false
	for key in ["offering_year", "festival_year"]:
		var value: Variant = progress.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value != int(value) or value < 0 or value > year(int(data["day"])):
			return false
	var offered: Variant = progress.get("offerings")
	if not offered is Array or offered.size() > 3 or (not offered.is_empty() and progress["offering_year"] == 0):
		return false
	var seen := {}
	for crop in offered:
		if not crop is String or not Crops.CROPS.has(crop) or seen.has(crop):
			return false
		seen[crop] = true
	if not progress.get("chapter_done") is bool or not progress.get("spring_complete") is bool:
		return false
	if events["shop"] and not data.get("route_restored", false):
		return false
	for id in ["shop","smith"]:
		if events[id] and progress["friends"][id] < 3:
			return false
	if progress["festival_year"] > progress["offering_year"]:
		return false
	if progress["festival_year"] == year(int(data["day"])) and season_day(int(data["day"])) < FESTIVAL_DAY:
		return false
	if progress["offering_year"] == year(int(data["day"])) and not offered.is_empty() and season_day(int(data["day"])) < FESTIVAL_DAY:
		return false
	if events["smith"] and not data.get("relic_recovered", false):
		return false
	if progress["festival_year"] > 0 and progress["festival_year"] == progress["offering_year"] and offered.size() != 3:
		return false
	if progress["spring_complete"] and data["day"] < 29:
		return false
	if progress["chapter_done"] and (not data.get("relic_recovered", false) or not data.get("route_restored", false) or not data.get("fence_repaired", false) or not data.get("reward_claimed", false) or not data.get("tea_event_seen", false) or data.get("requests_completed", 0) < 2 or not events["shop"] or not events["smith"] or progress["festival_year"] == 0):
		return false
	return true
