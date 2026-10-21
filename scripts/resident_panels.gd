extends RefCounted

var game: Node

func _init(controller: Node) -> void:
	game = controller

func portrait(card: Panel, id: String) -> void:
	var art = preload("res://scripts/approved_art.gd")
	var index: int = {"npc":0,"shop":1,"smith":2}[id]
	art.icon(card,art.RESIDENTS,art.R.FRAMES[index/3][index%3],Rect2(28,100,84,136))

func show(id: String) -> void:
	if id not in game.State.RESIDENTS.ORDER: return
	var s: RefCounted = game.state
	var text: String = s.talk() if id == "npc" else s.SPRING.talk(s,id)
	var friendship: int = s.friendship if id == "npc" else s.spring_progress["friends"][id]
	var card: Panel = game._open_modal(game.State.RESIDENTS.NAMES[id] + " · 雲橋的日常", "好感 %d · %s" % [friendship,game.State.RESIDENTS.location_name(id,s.minute,s.is_raining())])
	portrait(card,id)
	var body: Label = game._paragraph(card,text,Rect2(132,98,320,122))
	body.add_theme_font_size_override("font_size",14)
	if id == "npc":
		var tea: Button = game._button(card,"重讀窗邊茶會" if s.tea_event_seen else "赴窗邊茶會",Rect2(28,230,424,44),game._show_tea_event.bind(0,s.tea_event_seen),true)
		tea.disabled = not s.tea_event_seen and not s.tea_event_available()
	elif id == "shop":
		game._button(card,"買種子",Rect2(28,230,204,44),game._show_shop,true)
		var event: Button = game._button(card,"遠路的帳簿",Rect2(248,230,204,44),event_page.bind(id,0,s.spring_progress["events"][id]))
		event.disabled = not s.spring_progress["events"][id] and not s.SPRING.event_available(s,id)
	else:
		var event: Button = game._button(card,"鐘聲與星紋",Rect2(28,230,424,44),event_page.bind(id,0,s.spring_progress["events"][id]),true)
		event.disabled = not s.spring_progress["events"][id] and not s.SPRING.event_available(s,id)
	game._button(card,"送禮與關係",Rect2(28,282,204,46),game.journey_panels.person.bind(id))
	game._button(card,"稍後再聊",Rect2(248,282,204,46),game._close_modal)
	game.audio_system.play_effect("talk")
	game._save(false)
	game._update_ui()

func event_page(id: String, page: int = 0, replay: bool = false) -> void:
	if id not in ["shop","smith"] or page < 0 or page >= 3: return
	if (replay and not game.state.spring_progress["events"][id]) or (not replay and not game.state.SPRING.event_available(game.state,id)): return
	var event: Dictionary = game.State.RESIDENTS.EVENTS[id]
	var card: Panel = game._open_modal(event["title"],"%s · 第 %d / 3 幕" % ["手札回憶" if replay else "相識故事",page+1])
	game._request_body(card,event["pages"][page])
	if page < 2:
		game._button(card,"繼續聽",Rect2(28,282,424,46),event_page.bind(id,page+1,replay),true)
	else:
		game._button(card,"收好回憶" if replay else "記下這段相識",Rect2(28,282,424,46),game._close_modal if replay else finish.bind(id),true)

func finish(id: String) -> void:
	var result: Dictionary = game.state.SPRING.finish_event(game.state,id)
	game._close_modal()
	if result["ok"]:
		game._save(false)
		game.audio_system.play_effect("talk")
	game._update_ui()
	game.toast(result["text"])
