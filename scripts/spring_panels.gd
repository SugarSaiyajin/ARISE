extends RefCounted

var game: Node

func _init(controller: Node) -> void:
	game = controller

func hub() -> void:
	var card: Panel = game._open_modal("春日手札","第 %d 年 · %s %d / 28 日" % [game.state.JOURNEY.year(game.state.day),game.state.JOURNEY.season(game.state.day),game.state.SPRING.season_day(game.state.day)],410)
	for entry in [["當季日曆與今日安排",calendar],["第一章 · 雲橋初晴",chapter],["居民行蹤與相識",residents],["重讀春日回憶",memories]]:
		var i: int = [calendar,chapter,residents,memories].find(entry[1])
		game._button(card,entry[0],Rect2(28,98+i*56,424,46),entry[1],i==1)
	game._button(card,"回到選單",Rect2(28,344,424,46),game._show_menu)

func board() -> void:
	var card: Panel = game._open_modal("雲橋公告牌","委託、春宴與驛站故事，都從這裡相遇。",410)
	game._button(card,"今日居民委託",Rect2(28,100,424,46),game._show_requests,true)
	game._button(card,"春日市集 · 收成共宴" if game.state.JOURNEY.season(game.state.day)=="春" else "夏夜星燈會",Rect2(28,156,424,46),festival if game.state.JOURNEY.season(game.state.day)=="春" else game.journey_panels.summer)
	game._button(card,"第一章 · 驛站名冊",Rect2(28,212,424,46),chapter)
	game._button(card,"居民行蹤",Rect2(28,268,424,46),residents)
	game._button(card,"回到街道",Rect2(28,344,424,46),game._close_modal)

func calendar() -> void:
	game.journey_panels.calendar()

func chapter() -> void:
	var s: RefCounted = game.state
	var card: Panel = game._open_modal("第一章 · 雲橋初晴","從一片舊田，到重新響起的鐘聲。",410)
	var objectives: Array = s.SPRING.objectives(s)
	for i in range(objectives.size()):
		game._label(card,("✓ " if objectives[i]["done"] else "○ ")+objectives[i]["text"],Rect2(28,99+i*27,424,25),14)
	game._label(card,"第一章已完成，謝禮已領取。" if s.spring_progress["chapter_done"] else "六項完成後，在鎮上記下結尾；謝禮 300 銀。",Rect2(28,270,424,26),14,"dfcd96")
	game._button(card,"春日市集",Rect2(28,303,424,44),festival)
	game._button(card,"回到手札",Rect2(28,354,204,44),hub)
	var ending: Button = game._button(card,"重讀結尾" if s.spring_progress["chapter_done"] else "記下第一章",Rect2(248,354,204,44),finale.bind(0,s.spring_progress["chapter_done"]),true)
	ending.disabled = not s.spring_progress["chapter_done"] and not s.SPRING.can_finish(s)

func residents() -> void:
	var s: RefCounted = game.state
	var card: Panel = game._open_modal("居民行蹤","晴天會散步，雨天留在屋簷下；交談時時間暫停。",410)
	for i in range(3):
		var id: String = s.RESIDENTS.ORDER[i]
		var name: String = s.RESIDENTS.NAMES[id]
		var friendship: int = s.friendship if id=="npc" else s.spring_progress["friends"][id]
		game._label(card,"%s · 好感 %d" % [name,friendship],Rect2(28,99+i*69,270,27),18)
		game._label(card,s.RESIDENTS.location_name(id,s.minute,s.is_raining()),Rect2(28,129+i*69,270,22),13)
		var find: Button = game._button(card,"去找"+name,Rect2(310,102+i*69,142,46),game._find_resident.bind(id),true)
		find.disabled = s.area_id != "town"
	game._label(card,"請先前往雲橋鎮，再選擇帶路。" if s.area_id!="town" else "帶路會持續追蹤居民，不會對著舊位置交談。",Rect2(28,310,424,22),13)
	game._button(card,"回到手札",Rect2(28,354,424,44),hub)

func memories() -> void:
	var s: RefCounted = game.state
	var card: Panel = game._open_modal("春日回憶","已記下的故事可重讀，獎勵不會重複發放。",410)
	var tea: Button = game._button(card,"青禾 · 窗邊茶會",Rect2(28,98,424,44),game._show_tea_event.bind(0,true))
	tea.disabled = not s.tea_event_seen
	for i in range(2):
		var id: String = ["shop","smith"][i]
		var button: Button = game._button(card,s.RESIDENTS.EVENTS[id]["title"],Rect2(28,146+i*48,424,44),game.resident_panels.event_page.bind(id,0,true))
		button.disabled = not s.spring_progress["events"][id]
	var feast: Button = game._button(card,"雲橋春宴",Rect2(28,242,424,44),festival_page.bind(0,true))
	feast.disabled = s.spring_progress["festival_year"] == 0
	var ending: Button = game._button(card,"第一章 · 雲橋初晴",Rect2(28,290,424,44),finale.bind(0,true))
	ending.disabled = not s.spring_progress["chapter_done"]
	game._button(card,"回到手札",Rect2(28,354,424,44),hub)

func festival() -> void:
	var s: RefCounted = game.state
	var current: bool = s.spring_progress["offering_year"] == s.SPRING.year(s.day)
	var offered: Array = s.spring_progress["offerings"] if current else []
	var card: Panel = game._open_modal("雲橋春日市集","春 14 至 28 日 · 三種不同收成，各提供一份。",410)
	var lines := "把田裡的故事帶上長桌，和居民一起迎接春日。\n\n已提供 %d / 3 種：\n" % offered.size()
	for crop in offered: lines += s.CROPS[crop]["name"] + "  "
	if s.spring_progress["festival_year"] == s.SPRING.year(s.day): lines += "\n本年的春宴已完成，春帖已記入手札。"
	game._paragraph(card,lines,Rect2(28,98,424,120)).add_theme_font_size_override("font_size",14)
	var give: Button = game._button(card,"提供一份收成",Rect2(28,230,424,44),donation_page.bind(0),true)
	give.disabled = s.area_id!="town" or not s.SPRING.festival_open(s) or s.spring_progress["festival_year"]==s.SPRING.year(s.day) or offered.size()>=3
	var feast: Button = game._button(card,"共赴春宴",Rect2(28,284,424,44),festival_page.bind(0,false),true)
	feast.disabled = not s.SPRING.can_celebrate(s)
	game._button(card,"回到手札",Rect2(28,344,424,46),hub)

func donation_page(page: int = 0) -> void:
	var s: RefCounted = game.state
	var order: Array = s.CROP_ORDER
	page = posmod(page,3)
	var card: Panel = game._open_modal("準備春宴收成","每種只提供一次；確認按下即放上長桌並保存。",410)
	for n in range(3):
		var i := page*3+n
		if i>=order.size(): break
		var crop: String = order[i]
		var button: Button = game._button(card,"%s · 持有 %d" % [s.CROPS[crop]["name"],s.produce.get(crop,0)],Rect2(28,100+n*56,424,46),donate.bind(crop))
		button.disabled = s.produce.get(crop,0)<1 or (s.spring_progress["offering_year"]==s.SPRING.year(s.day) and crop in s.spring_progress["offerings"])
	game.inventory_panels.pagination(card,page,3,donation_page)
	game._button(card,"回到市集",Rect2(28,344,424,46),festival)

func donate(crop: String) -> void:
	var result: Dictionary = game.state.SPRING.donate(game.state,crop)
	if result["ok"]: game._save(false)
	festival()
	game._update_ui()
	game.toast(result["text"])

func festival_page(page: int = 0, replay: bool = false) -> void:
	if page<0 or page>=3: return
	if (replay and game.state.spring_progress["festival_year"]==0) or (not replay and not game.state.SPRING.can_celebrate(game.state)): return
	var card: Panel = game._open_modal("雲橋春宴","%s · 第 %d / 3 幕" % ["手札回憶" if replay else "春日相聚",page+1])
	game._request_body(card,game.state.SPRING.FESTIVAL_PAGES[page])
	game._button(card,"繼續" if page<2 else "收好春帖",Rect2(28,282,424,46),festival_page.bind(page+1,replay) if page<2 else (game._close_modal if replay else finish_festival),true)

func finish_festival() -> void:
	var result: Dictionary = game.state.SPRING.celebrate(game.state)
	game._close_modal()
	if result["ok"]:
		game._save(false)
		game.audio_system.play_effect("coin")
	game._update_ui()
	game.toast(result["text"])

func finale(page: int = 0, replay: bool = false) -> void:
	if page<0 or page>=3: return
	if (replay and not game.state.spring_progress["chapter_done"]) or (not replay and not game.state.SPRING.can_finish(game.state)): return
	var card: Panel = game._open_modal("第一章 · 雲橋初晴","%s · 第 %d / 3 幕" % ["手札回憶" if replay else "星潮與歸途",page+1])
	game._request_body(card,game.state.SPRING.FINALE_PAGES[page])
	game._button(card,"繼續" if page<2 else "把名字留在雲橋",Rect2(28,282,424,46),finale.bind(page+1,replay) if page<2 else (game._close_modal if replay else finish_chapter),true)

func finish_chapter() -> void:
	var result: Dictionary = game.state.SPRING.finish_chapter(game.state)
	game._close_modal()
	if result["ok"]:
		game._save(false)
		game.audio_system.play_effect("coin")
	game._update_ui()
	game.toast(result["text"])
