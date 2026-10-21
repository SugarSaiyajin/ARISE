extends RefCounted

const Archive = preload("res://scripts/save_archive.gd")
var game: Node
var archive: RefCounted
var import_box: TextEdit

func _init(controller: Node) -> void:
	game=controller
	archive=Archive.new("user://smoke_archives" if "--smoke" in OS.get_cmdline_user_args() else "user://archives")

func hub() -> void:
	var card: Panel=game._open_modal("存檔、備份與試玩","備份留在本機，解除安裝會刪除；請另存備份碼。",460)
	game._button(card,"立即儲存",Rect2(28,98,204,44),func(): game._save(true))
	game._button(card,"操作與入門",Rect2(248,98,204,44),guide)
	for i in range(1,4):
		var entry: Dictionary=archive.read_slot(i)
		var caption := "空白"
		if not entry.is_empty(): caption="第%d日 · %d銀" % [entry["data"]["day"],entry["data"]["money"]]
		game._button(card,"備份%d：%s" % [i,caption],Rect2(28,152+(i-1)*52,280,44),slot.bind(i))
		var button: Button=game._button(card,"還原",Rect2(324,152+(i-1)*52,128,44),confirm.bind(entry.get("data",{})))
		button.disabled=entry.is_empty() or not game.save_allowed
	game._button(card,"匯出備份碼",Rect2(28,312,204,44),export_code)
	game._button(card,"匯入備份碼",Rect2(248,312,204,44),import_code)
	game._button(card,"效能：%d FPS" % Engine.max_fps,Rect2(28,364,204,44),toggle_fps)
	game._button(card,"還原前的進度",Rect2(248,364,204,44),confirm.bind(archive.read_slot(0).get("data",{}))).disabled=archive.read_slot(0).is_empty() or not game.save_allowed
	game._button(card,"回到手札",Rect2(28,414,424,36),game._show_menu)

func slot(index: int) -> void:
	var card: Panel=game._open_modal("建立備份%d" % index,"手動備份不會被自動存檔更新。")
	game._paragraph(card,"將目前進度存入此欄位。\n若欄位已有備份，確認後會替換。\n\n要保留到手機以外，請使用匯出備份碼。",Rect2(28,100,424,160))
	game._button(card,"返回",Rect2(28,282,204,44),hub)
	game._button(card,"確認建立",Rect2(248,282,204,44),func():
		var error: Error=archive.write_slot(index,game.state)
		hub()
		game.toast("手動備份已建立。" if error==OK else "備份失敗："+error_string(error)),true)

func confirm(data: Dictionary) -> void:
	if data.is_empty() or not game.save_allowed:
		game.toast("沒有可還原的有效備份；受保護存檔請先保留原檔。")
		return
	var card: Panel=game._open_modal("確認還原進度","還原會替換目前進度；先自動保留一份還原前備份。")
	game._paragraph(card,"目標進度：第%d日，%d銀。\n\n目前進度可由「還原前的進度」取回。\n再次還原會更新那份備份，請先另存重要進度。" % [data["day"],data["money"]],Rect2(28,100,424,165))
	game._button(card,"取消",Rect2(28,282,204,44),hub)
	game._button(card,"確認還原",Rect2(248,282,204,44),func():
		var error: Error=archive.restore(data,game.state,"user://smoke_session.json" if game.simulation else "user://farm_save.json")
		if error==OK:
			game._mount_area()
			game.audio_system.set_weather(game.state.is_raining())
			game._update_ui()
		hub()
		game.toast("進度已還原。" if error==OK else "還原失敗，當前進度保留："+error_string(error)),true)

func export_code() -> void:
	var card: Panel=game._open_modal("匯出備份碼","請複製完整文字，貼到自己的筆記並保存。",410)
	var box := TextEdit.new()
	box.position=Vector2(28,100)
	box.size=Vector2(424,182)
	box.text=archive.encode(game.state)
	box.editable=false
	card.add_child(box)
	game._button(card,"複製備份碼",Rect2(28,300,424,44),func():
		DisplayServer.clipboard_set(box.text)
		game.toast("已送至剪貼簿；請貼到筆記確認完整保存。"))
	game._button(card,"返回",Rect2(28,354,424,44),hub)

func import_code() -> void:
	var card: Panel=game._open_modal("匯入備份碼","貼上完整 ARISE1 備份碼，驗證後再確認還原。",410)
	import_box=TextEdit.new()
	import_box.position=Vector2(28,100)
	import_box.size=Vector2(424,182)
	import_box.placeholder_text="長按貼上，或使用下方剪貼簿按鈕"
	card.add_child(import_box)
	game._button(card,"貼上剪貼簿",Rect2(28,298,204,44),func(): import_box.text=DisplayServer.clipboard_get().left(Archive.MAX_BYTES+1))
	game._button(card,"驗證備份碼",Rect2(248,298,204,44),func():
		var data: Dictionary=archive.decode(import_box.text)
		if data.is_empty(): game.toast("備份碼不完整、已損壞或版本不相容；進度未變更。")
		else: confirm(data),true)
	game._button(card,"返回",Rect2(28,354,424,44),hub)

func guide() -> void:
	var card: Panel=game._open_modal("旅人入門","可隨時從手札重看；視窗開啟時時間暫停。",460)
	game._paragraph(card,"移動：按住方向盤，放開即停；異常時按停止。\n作業：選工具後點目標；點空地不會自動行走。\n\n第一天：澆左上四株蕪菁 → 回屋點床休息。\n成熟後：採收 → 出貨箱換錢 → 補種與澆水。\n牧場：建棲地、準備飼料，每天餵食與照顧。\n行旅：聚落工坊接單，休息後回原工坊領取。\n\n試玩前先建立備份；更新採覆蓋安裝。\n回報問題請附手機型號、地點和操作步驟。",Rect2(28,99,424,300)).add_theme_font_size_override("font_size",15)
	game._button(card,"返回",Rect2(28,414,424,36),hub)

func toggle_fps() -> void:
	var target := 60 if Engine.max_fps==30 else 30
	var config := ConfigFile.new()
	config.set_value("display","fps",target)
	var error := config.save("user://display_preferences.cfg")
	if error==OK: Engine.max_fps=target
	hub()
	game.toast("30 FPS 較省資源，60 FPS 移動較流暢。" if error==OK else "設定未儲存："+error_string(error))
