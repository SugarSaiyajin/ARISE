extends RefCounted
var game: Node
func _init(controller: Node) -> void: game=controller
func hub() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("共收月會","秋14至28日 · 雲橋鎮中央長桌旁 · 三種秋收各一份。",460)
	var offered: Array=s.autumn["offered"] if s.autumn["cycle"]==s.calendar_year() else []
	game._label(card,"已入籃 %d /3 · %s" % [offered.size(),"本年已完成" if s.autumn["done"]==s.calendar_year() else "謝禮200銀與兩道食譜"],Rect2(28,96,424,26),15)
	for i in range(3):
		var id: String=s.CROP_DATA.AUTUMN[i]
		preload("res://scripts/autumn_art.gd").icon(card,id,Rect2(28,134+i*44,30,30))
		game._button(card,s.CROPS[id]["name"]+(" · 已入籃" if id in offered else " ×%d" % s.produce[id]),Rect2(66,130+i*44,386,40),donate.bind(id)).disabled=not s.AUTUMN.open(s) or id in offered or s.produce[id]<1
	game._button(card,"點亮月燈，入席共收",Rect2(28,270,424,42),story,true).disabled=not s.AUTUMN.open(s) or offered.size()!=3
	game._button(card,"收成交換與食譜",Rect2(28,320,424,42),workshop)
	game._button(card,"重讀月會",Rect2(28,370,204,42),memory).disabled=not s.autumn["learned"]
	game._button(card,"回日曆",Rect2(248,370,204,42),game.journey_panels.calendar)
	game._button(card,"回街道",Rect2(28,418,424,32),game._close_modal)
func apply(result: Dictionary, callback: Callable) -> void:
	if result["ok"]: game._save(false)
	callback.call()
	game._update_ui()
	game.world.queue_redraw()
	game.toast(result["text"])
func donate(id: String) -> void: apply(game.state.AUTUMN.donate(game.state,id),hub)
func story() -> void:
	var s: RefCounted=game.state
	if not s.AUTUMN.open(s) or s.autumn["cycle"]!=s.calendar_year() or s.autumn["offered"].size()!=3: return
	var card: Panel=game._open_modal("同一張長桌","青瓷湯鍋冒著熱氣，月燈照著麥穗編成的繩結。",440)
	game._paragraph(card,"青禾端來暖湯，博林調好葡萄壓榨器。莉莉雅把一張空椅子拉到桌邊：這張長桌，還可以為誰留一個位置？",Rect2(28,100,424,145))
	game._button(card,"先把收成分給鄰人",Rect2(28,280,424,46),finish.bind(1),true)
	game._button(card,"也為遠行旅人留座",Rect2(28,336,424,46),finish.bind(2))
func finish(choice: int) -> void: apply(game.state.AUTUMN.finish(game.state,choice),memory)
func memory() -> void:
	if not game.state.autumn["learned"]: return
	var card: Panel=game._open_modal("共收月會的回憶","回憶可重讀；本年的謝禮不會重複發放。",410)
	game._paragraph(card,game.state.AUTUMN.remembered(game.state),Rect2(28,100,424,160))
	game._button(card,"查看食譜與交換",Rect2(28,284,424,44),workshop,true)
	game._button(card,"收好回憶",Rect2(28,344,424,44),hub)
func workshop() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("共收籃與秋食譜","交換：秋14至28日長桌旁，每日一份秋收換兩包同種種苗。",460)
	for i in range(3):
		var id: String=s.CROP_DATA.AUTUMN[i]
		game._button(card,"交換"+s.CROPS[id]["name"]+" ×1 → 種苗 ×2",Rect2(28,98+i*46,424,42),exchange.bind(id)).disabled=not s.AUTUMN.in_season(s) or not s.AUTUMN.on_site(s) or not s.autumn["learned"] or s.produce[id]<1 or s.autumn["exchanged_day"]==s.day
	game._label(card,"暖湯：南瓜1、甘薯1 → 恢復65體力",Rect2(28,244,290,24),14)
	game._label(card,"果汁：葡萄2 → 恢復45體力",Rect2(28,284,290,24),14)
	game._button(card,"煮湯",Rect2(328,238,124,36),cook.bind("harvest_soup")).disabled=not s.can_cook("harvest_soup")
	game._button(card,"壓汁",Rect2(328,278,124,36),cook.bind("grape_juice")).disabled=not s.can_cook("grape_juice")
	game._paragraph(card,"月會完成後學會兩道食譜，可全年在長桌或農舍爐灶製作；料理保留在行囊，不會隨出貨售出。",Rect2(28,330,424,65)).add_theme_font_size_override("font_size",14)
	game._button(card,"回月會",Rect2(28,410,424,40),hub,true)
func exchange(id: String) -> void: apply(game.state.AUTUMN.exchange(game.state,id),workshop)

func cook(id: String) -> void: apply(game.state.cook(id),workshop)
