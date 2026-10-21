extends RefCounted
const RULES = preload("res://scripts/journey_rules.gd")
const ART = preload("res://scripts/approved_art.gd")
var game: Node
func _init(controller: Node) -> void: game=controller

func hub() -> void:
	var card: Panel=game._open_modal("莊園生活手札","%s季 · 第%d年 · %s" % [game.state.season(),game.state.calendar_year(),game.state.weather()],460)
	var entries := [["新手與今日任務",tutorial],["農場配置與裝飾",farm],["居民關係與禮物",people],["收益與保留出貨",economy],["聚落探索委託",quests],["季節日曆與節慶",calendar]]
	for i in range(entries.size()):
		game._button(card,entries[i][0],Rect2(28,98+i*48,424,44),entries[i][1],i==0)
	game._button(card,"第一章與春日回憶",Rect2(28,400,204,44),game.spring_panels.hub)
	game._button(card,"經營總覽",Rect2(248,400,204,44),game.estate_panels.hub)

func tutorial() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("第一輪田園生活","每一步依實際操作記錄；完成後可重看，不重複發資源。",460)
	for i in range(5):
		game._label(card,("✓ " if s.journey["tutorial"][RULES.TASKS[i]] else "○ ")+RULES.TASK_TEXT[i],Rect2(28,98+i*32,424,28),16)
	var current: String=RULES.next_task(s)
	var tips := {"water":"選澆水工具，點田裡的作物。點目標會自動走近，可隨時按停止。","rest":"先走進左側農舍，點床鋪睡到明天。","harvest":"選採收工具，點成熟作物；未成熟可再澆水休息。","ship":"走到農舍旁的出貨箱；保留出貨可替每種物品留兩份。","seed":"選一種種子，選播種工具，再點已開墾的空田。","":"已完成第一輪！可試養殖、烘乾架、居民委託或聚落探索。"}
	game._paragraph(card,tips[current],Rect2(28,270,424,88)).add_theme_font_size_override("font_size",15)
	game._button(card,"回手札",Rect2(28,400,204,44),hub)
	game._button(card,"準備這一步",Rect2(248,400,204,44),prepare.bind(current),true)

func prepare(task: String) -> void:
	game._close_modal()
	if task in ["water","harvest","seed"]:
		game._select_tool({"water":2,"harvest":3,"seed":1}[task])
	game.toast("請先回莊園，按照畫面上方的任務提示操作。" if game.state.area_id!="farm" else "已準備工具；點選目標，或用方向盤走近操作。")

func farm() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("農場配置","固定住宅、田區、作業區；六處裝飾位保留主要通道。",460)
	game._button(card,"查看平面圖：住宅 ← 田區 → 作業區",Rect2(28,94,424,38),view_farm)
	for i in range(6):
		game._button(card,"%d · %s" % [i+1,RULES.DECOR[s.journey["decor"][i]]],Rect2(28+(i%2)*220,141+(i/2)*54,204,46),decor.bind(i))
	var names := ["環田主路","南側直路","作業環路"]
	game._button(card,"路面："+names[s.journey["layout"]],Rect2(28,314,424,44),layout_next)
	game._label(card,"裝飾不擋路；更換或拆除不退素材。",Rect2(28,367,424,24),13)
	game._button(card,"回手札",Rect2(28,408,204,44),hub)
	game._button(card,"水壺升級",Rect2(248,408,204,44),upgrade,true)

func view_farm() -> void:
	var card: Panel=game._open_modal("莊園平面配置","六處編號對應裝飾位置；中央田格與東側入口保持暢通。",410)
	var plan := preload("res://scripts/farm_plan.gd").new()
	plan.state=game.state
	plan.position=Vector2(28,92)
	plan.size=Vector2(424,215)
	card.add_child(plan)
	game._label(card,"1住宅西南 · 2住宅南側 · 3田東 · 4茶亭東側",Rect2(28,302,424,22),13)
	game._label(card,"5茶亭南側 · 6工坊南側；建築與田地保留原位。",Rect2(28,326,424,22),13)
	game._button(card,"回配置",Rect2(28,354,204,44),farm)
	game._button(card,"查看場景",Rect2(248,354,204,44),game._close_modal,true)

func layout_next() -> void:
	if game.state.area_id!="farm":
		game.toast("請回莊園安排路面。")
		return
	game.state.journey["layout"]=(game.state.journey["layout"]+1)%3
	game._save(false)
	if is_instance_valid(game.world.terrain_layer):
		game.world.terrain_layer.layout=game.state.journey["layout"]
		game.world.terrain_layer.queue_redraw()
	farm()

func decor(slot: int) -> void:
	var card: Panel=game._open_modal("裝飾位置 %d" % (slot+1),"位置固定於通道旁；確認放置會扣除素材。",410)
	for i in range(4):
		var cost := ""
		for key in RULES.COSTS[i]: cost+="%s%d " % [RULES.item_name("materials:"+key),RULES.COSTS[i][key]]
		game._button(card,RULES.DECOR[i]+"  "+cost,Rect2(28,98+i*52,424,44),place.bind(slot,i))
	game._button(card,"返回配置",Rect2(28,354,424,44),farm)

func place(slot: int, kind: int) -> void:
	var result := RULES.decorate(game.state,slot,kind)
	if result["ok"]: game._save(false)
	farm()
	game.toast(result["text"])

func people(page: int = 0) -> void:
	page=posmod(page,3)
	var card: Panel=game._open_modal("居民關係","每日交談＋送禮；好感3熟識、10信賴、25知心。",410)
	for n in range(3):
		var i := page*3+n
		var id: String=RULES.PEOPLE[i]
		var points := RULES.friendship(game.state,id)
		game._button(card,"%s · %s %d" % [RULES.NAMES[i],RULES.stage(points),points],Rect2(28,98+n*56,424,46),person.bind(id))
	game.inventory_panels.pagination(card,page,3,people)
	game._button(card,"回手札",Rect2(28,354,424,44),hub)

func person(id: String) -> void:
	var s: RefCounted=game.state
	var points := RULES.friendship(s,id)
	var card: Panel=game._open_modal(RULES.NAMES[RULES.PEOPLE.find(id)]+" · "+RULES.stage(points),"好感%d · 每位居民每天送禮一次" % points,460)
	var likes := "喜歡："
	for item in RULES.LIKES[id]: likes+=RULES.item_name(item)+"  "
	var where: String=s.RESIDENTS.location_name(id,s.minute,s.is_raining())+" · 雲橋鎮" if id in ["npc","shop","smith"] else game.life_panels.DATA.NAMES[game.life_panels.DATA.AREAS.find(game.State.RANCH_DATA.CULTURES[id])] if not s.is_raining() and s.minute>=660 and s.minute<1080 else game.State.RANCH_DATA.HOMES[game.State.RANCH_DATA.RESIDENTS[id]["home"]]
	game._paragraph(card,likes+"\n\n目前位置："+where+"\n喜愛禮物好感+2，其他禮物+1。\n信賴與知心各有一段相處回憶。\n贈送與新回憶需走近本人。",Rect2(28,100,424,172)).add_theme_font_size_override("font_size",15)
	game._button(card,"選擇禮物",Rect2(28,284,204,44),gifts.bind(id))
	var tier: int=mini(2,s.journey["events"][id]+1)
	game._button(card,"信賴回憶" if tier==1 else "知心回憶",Rect2(248,284,204,44),event.bind(id,tier,0),true)
	game._button(card,"一起活動",Rect2(28,354,204,44),game.estate_panels.activity_choices.bind(id))
	game._button(card,"重讀已完成回憶",Rect2(248,354,204,44),replay.bind(id))

	game._button(card,"專屬生活事件",Rect2(28,408,424,40),game.chapter_panels.story.bind(id,0))

func gifts(id: String, page: int = 0) -> void:
	var pages: int=game.inventory_panels.pages(RULES.GIFTS)
	page=posmod(page,pages)
	var card: Panel=game._open_modal("送禮給"+RULES.NAMES[RULES.PEOPLE.find(id)],"按下即送出一份；走近本人才能交付。",410)
	for n in range(3):
		var index := page*3+n
		if index>=RULES.GIFTS.size(): break
		var item: String=RULES.GIFTS[index]
		var text := RULES.item_name(item)+" ×%d" % RULES.count(game.state,item)+(" ♥" if item in RULES.LIKES[id] else "")
		var button: Button=game._button(card,text,Rect2(28,98+n*56,424,46),give.bind(id,item))
		button.disabled=not RULES.near(game.state,id) or RULES.count(game.state,item)<1 or game.state.journey["gifts"][id]==game.state.day
	game._button(card,"上一頁",Rect2(28,278,128,44),gifts.bind(id,posmod(page-1,pages)))
	game._label(card,"%d /%d" % [page+1,pages],Rect2(190,286,100,26))
	game._button(card,"下一頁",Rect2(324,278,128,44),gifts.bind(id,(page+1)%pages))
	game._button(card,"返回",Rect2(28,354,424,44),person.bind(id))

func give(id: String, item: String) -> void:
	var result := RULES.gift(game.state,id,item)
	if result["ok"]: game._save(false)
	person(id)
	game._update_ui()
	game.toast(result["text"])

func replay(id: String) -> void:
	var tier: int=game.state.journey["events"][id]
	var card: Panel=game._open_modal("相處回憶","完成後可重讀，重讀不重複領取心意。")
	for index in range(2):
		game._button(card,"信賴回憶" if index==0 else "知心回憶",Rect2(28,104+index*58,424,46),event.bind(id,index+1,0,true)).disabled=tier<index+1
	game._button(card,"返回",Rect2(28,282,424,44),person.bind(id))

func event(id: String, tier: int, page: int = 0, replaying: bool = false) -> void:
	if tier not in [1,2] or page not in [0,1]: return
	var available: bool=game.state.journey["events"][id]>=tier if replaying else RULES.near(game.state,id) and game.state.journey["events"][id]==tier-1 and RULES.friendship(game.state,id)>=(10 if tier==1 else 25)
	if not available:
		game.toast("請走近本人，達成好感10／25並依次完成回憶。")
		return
	var card: Panel=game._open_modal(("信賴" if tier==1 else "知心")+" · "+RULES.NAMES[RULES.PEOPLE.find(id)],"相處回憶 · 第%d /2幕" % (page+1))
	var line: String=RULES.EVENT_LINES[RULES.PEOPLE.find(id)][tier-1]
	game._request_body(card,line if page==0 else ("你們約定明天再聊，讓這份相識留在每日的生活裡。\n\n"+line if tier==1 else "熟悉的聲音，已成為你在異世界的歸處。\n\n"+line))
	game._button(card,"繼續" if page==0 else "收好回憶",Rect2(28,282,424,44),event.bind(id,tier,1,replaying) if page==0 else (game._close_modal if replaying else finish_event.bind(id,tier)),true)

func finish_event(id: String, tier: int) -> void:
	var result := RULES.finish_event(game.state,id,tier)
	if result["ok"]: game._save(false)
	person(id)
	game._update_ui()
	game.toast(result["text"])

func quests() -> void:
	var card: Panel=game._open_modal("四聚落探索手札","走訪記錄點，準備物資；每個聚落委託可完成一次。",410)
	for i in range(4):
		game._button(card,game.life_panels.DATA.NAMES[i]+(" ✓" if game.state.journey["quests"][i] else ""),Rect2(28,98+i*52,424,44),quest.bind(i))
	game._button(card,"回手札",Rect2(28,354,424,44),hub)

func quest(index: int) -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal(game.life_panels.DATA.NAMES[index]+" · 探索","三處記錄點位於聚落道路旁，可走近點選。",410)
	var text := ""
	for i in range(3): text+=("✓ " if s.journey["clues"][index] & (1<<i) else "○ ")+RULES.CLUE_TITLES[index][i]+"\n"
	var need: Array=RULES.QUEST_NEEDS[index]
	text+="\n交付：%s ×%d" % [RULES.item_name(need[0]),need[1]]
	if index==2: text+="、銀鱗鯽 ×1"
	if index==3: text+="、小麥 ×1"
	text+="\n謝禮：%d 銀＋%s" % [80+index*10,["莓果種子3包","飼料10份","星露茶1份","馬鈴薯種子3包"][index]]
	game._paragraph(card,text,Rect2(28,98,424,181)).add_theme_font_size_override("font_size",15)
	game._button(card,"回探索手札",Rect2(28,294,204,44),quests)
	var button: Button=game._button(card,"已完成" if s.journey["quests"][index] else "確認交付",Rect2(248,294,204,44),finish_quest.bind(index),true)
	button.disabled=s.journey["quests"][index] or s.area_id!=game.life_panels.DATA.AREAS[index] or s.journey["clues"][index]!=7
	game._button(card,"收好手札",Rect2(28,354,424,44),game._close_modal)

func finish_quest(index: int) -> void:
	var result := RULES.quest(game.state,index)
	if result["ok"]: game._save(false)
	quest(index)
	game._update_ui()
	game.toast(result["text"])

func clue(index: int) -> void:
	var area: int=game.life_panels.DATA.AREAS.find(game.state.area_id)
	var result := RULES.inspect_clue(game.state,index)
	if not result["ok"]:
		game.toast(result["text"])
		return
	game._save(false)
	var card: Panel=game._open_modal(RULES.CLUE_TITLES[area][index],"記錄已收入探索手札。")
	game._request_body(card,result["text"])
	game._button(card,"查看聚落委託",Rect2(28,282,204,44),quest.bind(area))
	game._button(card,"繼續探索",Rect2(248,282,204,44),game._close_modal,true)

func calendar() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("春夏秋日曆","每季28日：春 → 夏 → 秋 → 下一年春；跨季作物保留。",460)
	var first: int=((s.day-1)/28)*28+1
	for i in range(28):
		var x := 28+(i%7)*61
		var y := 98+(i/7)*40
		game._panel(card,Rect2(x,y,56,36),"60764c" if first+i==s.day else "2c493c")
		game._label(card,"%02d%s" % [i+1,"雨" if RULES.rain(first+i,s.calendar_offset) else ""],Rect2(x+4,y+6,50,24),13)
	var text := "春季每四日細雨；春14至28日收成共宴。" if s.season()=="春" else "夏季有連續夏雨；夏14至28日星燈夜。\n莓果、馬鈴薯、茶售價+20%，每逢第3日多長1格。"
	if s.season()=="秋": text="秋季每七日一場秋雨；秋14至28日共收月會。\n三種秋收入籃，分享兩道食譜與月燈回憶。"
	game._paragraph(card,text+"\n今天："+s.weather()+"；明天："+s.weather(1),Rect2(28,270,424,96)).add_theme_font_size_override("font_size",14)
	game._button(card,"當季節慶",Rect2(28,368,424,40),game.autumn_panels.hub if s.season()=="秋" else summer if s.season()=="夏" else game.spring_panels.festival,true)
	game._button(card,"回手札",Rect2(28,414,424,36),hub)

func summer(page: int = 0) -> void:
	var s: RefCounted=game.state
	var pages: int = game.inventory_panels.pages(s.CROP_ORDER)
	page=posmod(page,pages)
	var card: Panel=game._open_modal("夏夜星燈會","夏14至28日於雲橋鎮；三種收成，每種一份。",460)
	var offered: Array=s.journey["summer_offered"] if s.journey["summer_cycle"]==s.calendar_year() else []
	game._label(card,"已提供%d /3 · %s" % [offered.size(),"本年已完成" if s.journey["summer_done"]==s.calendar_year() else "謝禮150銀"],Rect2(28,98,424,26),16)
	for n in range(3):
		var i := page*3+n
		if i>=s.CROP_ORDER.size(): break
		var id: String=s.CROP_ORDER[i]
		var button: Button=game._button(card,s.CROPS[id]["name"]+" ×%d" % s.produce[id],Rect2(28,136+n*45,424,40),summer_give.bind(id,page))
		button.disabled=not RULES.summer_open(s) or id in offered or offered.size()>=3 or s.produce[id]<1
	game.inventory_panels.pagination(card,page,pages,summer)
	game._button(card,"共赴星燈夜",Rect2(28,337,424,44),summer_story.bind(0),true).disabled=not RULES.summer_open(s) or offered.size()!=3
	game._button(card,"重讀星燈夜",Rect2(28,392,204,44),summer_story.bind(0,true)).disabled=s.journey["summer_done"]==0
	game._button(card,"回日曆",Rect2(248,392,204,44),calendar)

func summer_give(id: String, page: int) -> void:
	var result := RULES.summer_donate(game.state,id)
	if result["ok"]: game._save(false)
	summer(page)
	game._update_ui()
	game.toast(result["text"])

func summer_story(page: int, replaying: bool = false) -> void:
	if replaying and game.state.journey["summer_done"]==0: return
	if not replaying and (not RULES.summer_open(game.state) or game.state.journey["summer_offered"].size()!=3): return
	var card: Panel=game._open_modal("星燈照雲橋","夏夜相聚 · 第%d /2幕" % (page+1))
	var texts := ["青瓷燈座映著西陸的彩色窗燈，橋邊長桌擺滿收成。\n\n雷恩調好燈架，雲霽替孩子解說星紋。莉莉雅把新茶遞到你手中：這是來到雲橋後的第一個夏天。","你們沿河放下一串倒映星光的燈影。艾德里克守著橋頭，素月與青禾把剩下的料理分給夜行商旅。\n\n兩地的節日有不同名字，今夜卻都記得替遠行的人留一盞燈。"]
	game._request_body(card,texts[page])
	game._button(card,"繼續" if page==0 else "記下夏夜",Rect2(28,282,424,44),summer_story.bind(1,replaying) if page==0 else (game._close_modal if replaying else summer_finish),true)

func summer_finish() -> void:
	var result := RULES.summer_finish(game.state)
	if result["ok"]: game._save(false)
	game._close_modal()
	game._update_ui()
	game.toast(result["text"])

func economy() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("收益與經營","銀幣與素材不會因瀏覽改變；各配方顯示實際工費。",410)
	game._paragraph(card,"種田：短期蕪菁回本快；茶需長期照料。\n養殖：先建棲地；每日餵養才成長與生產。\n工藝：扣材料與工費，休息一日再領成品。\n料理：換取體力，留給採集、耕作與照顧。\n\n保留出貨：每種作物、養殖品與工藝品留2份，\n避免把委託、送禮與加工材料一次賣光。\n材料、種子與料理一律保留。",Rect2(28,98,424,224)).add_theme_font_size_override("font_size",15)
	game._button(card,"保留出貨："+("開" if s.journey["reserve"] else "關"),Rect2(28,354,204,44),toggle_reserve,true)
	game._button(card,"回手札",Rect2(248,354,204,44),hub)

func toggle_reserve() -> void:
	game.state.journey["reserve"]=not game.state.journey["reserve"]
	game._save(false)
	economy()

func upgrade() -> void:
	var card: Panel=game._open_modal("水壺調校","保留原有外觀，升級後每次澆水體力2 → 1。")
	game._paragraph(card,"施工地點：莊園\n費用：180銀、木材8、石料6。\n\n工具只需升級一次，重開遊戲仍保留。\n不影響既有作物與灌溉器。",Rect2(28,100,424,166))
	game._button(card,"返回配置",Rect2(28,282,204,44),farm)
	game._button(card,"已升級" if game.state.journey["tool_level"] else "確認升級",Rect2(248,282,204,44),upgrade_finish,true).disabled=game.state.journey["tool_level"]==1

func upgrade_finish() -> void:
	var result := RULES.upgrade_tool(game.state)
	if result["ok"]: game._save(false)
	upgrade()
	game._update_ui()
	game.toast(result["text"])

func controls() -> void:
	var prefs: RefCounted=game.mobile_preferences
	var card: Panel=game._open_modal("手機手感","更改會先停止移動；實際手感可依手機調整。",410)
	game._button(card,"方向盤："+("加大" if prefs.stick_size==160 else "標準"),Rect2(28,98,424,44),change_control.bind("size"))
	game._button(card,"中央防誤觸："+("較強" if prefs.deadzone>0.3 else "標準"),Rect2(28,151,424,44),change_control.bind("zone"))
	game._button(card,"點目標走近："+("開啟" if prefs.tap_navigation else "關閉，手動移動"),Rect2(28,204,424,44),change_control.bind("tap"),true)
	game._paragraph(card,"手動模式：先用方向盤走近，再點目標或按作業。\n關閉點擊走近，可避免誤點物件後自動行走。\n若仍不受控，按停止並回報手機型號與步驟。",Rect2(28,262,424,76)).add_theme_font_size_override("font_size",14)
	game._button(card,"回選單",Rect2(28,354,424,44),game._show_menu)

func change_control(kind: String) -> void:
	game._stop_moving()
	var prefs: RefCounted=game.mobile_preferences
	var original := [prefs.stick_size,prefs.deadzone,prefs.tap_navigation]
	if kind=="size": prefs.stick_size=160 if prefs.stick_size==148 else 148
	elif kind=="zone": prefs.deadzone=0.35 if prefs.deadzone<0.3 else 0.25
	elif kind=="tap": prefs.tap_navigation=not prefs.tap_navigation
	else: return
	var error: Error=prefs.save_settings()
	if error!=OK:
		prefs.stick_size=original[0]
		prefs.deadzone=original[1]
		prefs.tap_navigation=original[2]
	game.stick.size=Vector2.ONE*prefs.stick_size
	game.stick.position=Vector2(4 if prefs.stick_size==160 else 8,530-prefs.stick_size)
	game.stick.deadzone=prefs.deadzone
	controls()
	if error!=OK: game.toast("設定未儲存："+error_string(error))
