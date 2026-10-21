extends RefCounted
const RULES = preload("res://scripts/estate_rules.gd")
const ART = preload("res://scripts/approved_art.gd")
var game: Node
var shipping_guard := ""
func _init(controller: Node) -> void: game=controller
func hub() -> void:
	var card: Panel=game._open_modal("莊園經營總覽","先查看清單與消耗，再安排今天的工作。",460)
	var entries := [["田間狀態與批量作業",field],["本地養殖一鍵照料",ranch],["出貨清單與確認",shipping],["設施施工預覽",construction],["夏季聚落週活動",summer],["莊園階段目標",goals]]
	for i in range(6): game._button(card,entries[i][0],Rect2(28,98+i*48,424,44),entries[i][1],i==0)
	game._button(card,"生活手札",Rect2(28,406,204,44),game.journey_panels.hub)
	game._button(card,"回到場景",Rect2(248,406,204,44),game._close_modal)
func field() -> void:
	var status := RULES.crop_status(game.state)
	var card: Panel=game._open_modal("田間照料","角色會逐格走近作業；方向盤、停止或開選單可中止。",410)
	game._paragraph(card,"已種植 %d 格 · 空田 %d 格\n待澆水 %d 格 · 可採收 %d 格\n\n只處理目前符合條件的田格。\n資源逐格扣除，中止後保留已完成成果。\n不會自動播種或出售。" % [status["planted"],status["empty"],status["dry"],status["mature"]],Rect2(28,98,424,181)).add_theme_font_size_override("font_size",15)
	game._button(card,"批量澆水",Rect2(28,290,204,44),field_confirm.bind("water"),true)
	game._button(card,"批量採收",Rect2(248,290,204,44),field_confirm.bind("harvest"))
	game._button(card,"回經營總覽",Rect2(28,354,424,44),hub)
func field_confirm(tool: String) -> void:
	var plan: Dictionary=game.field_batch_plan(tool)
	var card: Panel=game._open_modal("確認田間作業","只會依序處理預覽列出的田格，沒有額外收成。")
	game._paragraph(card,"準備%s %d 格\n最多消耗體力 %d，目前 %d。\n\n%s\n手動移動模式下，也可主動安排這次自動作業。" % ["澆水" if tool=="water" else "採收",plan["ids"].size(),plan["energy"],game.state.energy,plan["text"]],Rect2(28,98,424,166)).add_theme_font_size_override("font_size",15)
	game._button(card,"取消",Rect2(28,282,204,44),field)
	game._button(card,"開始逐格作業",Rect2(248,282,204,44),game.start_field_batch.bind(tool),true).disabled=plan["ids"].is_empty()
func ranch() -> void:
	var card: Panel=game._open_modal("本地養殖照料","莊園可處理母雞；棲地內可處理該處夥伴。",410)
	for i in range(3):
		var action: String=["feed","care","collect"][i]
		game._button(card,["餵養所有待餵夥伴","照顧所有待照顧夥伴","領取所有待領產物"][i],Rect2(28,98+i*58,424,46),ranch_confirm.bind(action))
	game._label(card,"飼料、體力或容量不足時，整批保留，不部分扣除。",Rect2(28,287,424,26),13)
	game._button(card,"回經營總覽",Rect2(28,354,424,44),hub)
func ranch_confirm(action: String) -> void:
	var plan := RULES.ranch_plan(game.state,action)
	var card: Panel=game._open_modal("確認本地照料","已完成項目自動略過；同一項只處理一次。")
	var text: String=plan["text"]
	if plan["ok"]:
		text=""
		for id in plan["ids"]: text+=game.State.RANCH_DATA.SPECIES[id]["name"]+"  "
		text+="\n\n體力 -%d · 照料飼料 -%d · 小麥 -%d\n\n確認後一次結算本地清單。" % [plan["energy"],plan["feed"],plan["wheat"]]
	game._paragraph(card,text,Rect2(28,98,424,166)).add_theme_font_size_override("font_size",15)
	game._button(card,"返回",Rect2(28,282,204,44),ranch)
	game._button(card,"確認處理",Rect2(248,282,204,44),ranch_apply.bind(action,plan.get("guard","")),true).disabled=not plan["ok"]
func ranch_apply(action: String, guard: String) -> void:
	var result := RULES.ranch_apply(game.state,action,guard)
	if result["ok"]:
		game._save(false)
		if game.world.has_method("animate_animal"):
			for id in result["ids"]: game.world.animate_animal(id,"feed" if action=="feed" else "collect" if action=="collect" else "care")
	game._update_ui()
	ranch()
	game.toast(result["text"])
func shipping(page: int = 0) -> void:
	var plan := RULES.shipping_plan(game.state)
	shipping_guard=plan["guard"]
	var pages := maxi(1,ceili(plan["lines"].size()/3.0))
	page=posmod(page,pages)
	var card: Panel=game._open_modal("出貨預覽","預計收入 %d 銀 · %s" % [plan["earnings"],"每種保留2份" if game.state.journey["reserve"] else "出售所有可售品"],460)
	for n in range(3):
		var index := page*3+n
		if index>=plan["lines"].size(): break
		var line: Dictionary=plan["lines"][index]
		game._label(card,"%s ×%d" % [line["name"],line["amount"]],Rect2(28,102+n*48,424,32),17)
	if plan["lines"].is_empty(): game._paragraph(card,plan["text"],Rect2(28,102,424,122))
	game.inventory_panels.pagination(card,page,pages,shipping)
	game._button(card,"保留2份："+("開" if game.state.journey["reserve"] else "關"),Rect2(28,337,204,44),reserve_toggle)
	game._button(card,"確認出貨",Rect2(248,337,204,44),confirm_shipping,true).disabled=not plan["ok"] or game.state.area_id!="farm"
	game._button(card,"取消並返回",Rect2(28,402,424,44),hub)
func reserve_toggle() -> void:
	game.state.journey["reserve"]=not game.state.journey["reserve"]
	game._save(false)
	shipping()
func confirm_shipping() -> void:
	var result := RULES.ship(game.state,shipping_guard)
	if result["ok"]:
		game._save(false)
		game.audio_system.play_effect("coin")
	game._close_modal()
	game._update_ui()
	game.toast(result["text"])
func construction() -> void:
	var card: Panel=game._open_modal("設施施工位置","沿用已通過素材；新增建築美術會另送審。",410)
	for site in range(3):
		game._button(card,"%s · %s" % [RULES.SITE_NAMES[site],RULES.FACILITIES[game.state.estate["fixtures"][site]]],Rect2(28,98+site*56,424,46),facility.bind(site,1))
	game._label(card,"同類設施一座；施工前檢查占位與素材，拆除不退費。",Rect2(28,290,424,24),13)
	game._button(card,"回經營總覽",Rect2(28,354,424,44),hub)
func facility(site: int, kind: int) -> void:
	var reason := RULES.facility_reason(game.state,site,kind)
	var card: Panel=game._open_modal(RULES.SITE_NAMES[site]+" · "+RULES.FACILITIES[kind],"綠色可施工，紅色表示占位、前置條件或材料不足。",500)
	var plan := preload("res://scripts/farm_plan.gd").new()
	plan.state=game.state
	plan.preview_site=site
	plan.preview_kind=kind
	plan.preview_legal=reason==""
	plan.position=Vector2(28,92)
	plan.size=Vector2(424,211)
	card.add_child(plan)
	var detail: String=["拆除現有設施，不退材料。","需符玉灌溉器；夜間自動澆水由前2格擴充至前6格。","養殖照顧不再消耗體力，仍每日一次。","出貨收入+5%，清單顯示的收入已包含加成。"][kind]
	var cost := ""
	for key in RULES.COSTS[kind]: cost+=("銀" if key=="money" else "木材" if key=="wood" else "石料")+str(RULES.COSTS[kind][key])+" "
	game._paragraph(card,detail+"\n"+cost+"\n"+("可以施工。" if reason=="" else reason),Rect2(28,304,424,82)).add_theme_font_size_override("font_size",13)
	game._button(card,"切換設施",Rect2(28,392,204,44),facility.bind(site,kind%3+1))
	game._button(card,"確認施工" if kind else "確認拆除",Rect2(248,392,204,44),build.bind(site,kind),true).disabled=reason!=""
	game._button(card,"返回",Rect2(28,446,204,42),construction)
	game._button(card,"拆除預覽",Rect2(248,446,204,42),facility.bind(site,0))
func build(site: int, kind: int) -> void:
	var result := RULES.build(game.state,site,kind)
	if result["ok"]:
		game._mount_area()
		game._save(false)
	construction()
	game.toast(result["text"])
func activity_choices(id: String) -> void:
	var card: Panel=game._open_modal("約一起活動","熟識後可邀約；每人每週一次，消耗6體力與30分鐘。",410)
	game._paragraph(card,"一起整理田園，或聊聊旅途。\n不同選擇會留在日常對話裡。\n\n先預覽活動，最後確認才消耗時間和體力。\n需走近本人，好感達3。",Rect2(28,100,424,170)).add_theme_font_size_override("font_size",15)
	game._button(card,"田園小事",Rect2(28,294,204,44),activity_preview.bind(id,1))
	game._button(card,"旅途閒談",Rect2(248,294,204,44),activity_preview.bind(id,2),true)
	game._button(card,"返回關係",Rect2(28,354,424,44),game.journey_panels.person.bind(id))
func activity_preview(id: String, choice: int) -> void:
	var card: Panel=game._open_modal("一起度過半小時","完整確認後才記下這次相處；關閉不消耗資源。")
	game._request_body(card,RULES.ACTIVITY_LINES[game.state.JOURNEY.PEOPLE.find(id)][choice-1]+"\n\n將消耗6體力與30分鐘，好感+2。")
	game._button(card,"再想一想",Rect2(28,282,204,44),activity_choices.bind(id))
	game._button(card,"一起參與",Rect2(248,282,204,44),activity_finish.bind(id,choice),true)
func activity_finish(id: String, choice: int) -> void:
	var result := RULES.activity(game.state,id,choice)
	if result["ok"]: game._save(false)
	game._close_modal()
	game._update_ui()
	game.toast(result["text"])
func summer() -> void:
	var card: Panel=game._open_modal("夏季聚落週活動","每聚落每週一次，消耗4體力；週期以莊園日曆計。",410)
	for i in range(4): game._button(card,game.State.LIFE_DATA.NAMES[i],Rect2(28,98+i*52,424,44),summer_preview.bind(i))
	game._button(card,"居民共同活動",Rect2(28,354,204,44),game.journey_panels.people)
	game._button(card,"回經營總覽",Rect2(248,354,204,44),hub)
func summer_preview(index: int) -> void:
	var card: Panel=game._open_modal(game.State.LIFE_DATA.NAMES[index]+" · 夏日協作","到對應聚落參加；每週只能交付一次。")
	var titles := ["替育苗圃備一份莓果，留下夏季種子的記錄。","整理工坊散落的石料，補好避暑水槽。","替旅人備好香草，整理夏日休息棚。","準備一份馬鈴薯，支援夜市的共食長桌。"]
	game._paragraph(card,titles[index]+"\n\n需要%s ×%d（持有%d）\n消耗體力4，謝禮%d銀。" % [game.state.JOURNEY.item_name(RULES.SUMMER_NEEDS[index]),RULES.SUMMER_AMOUNTS[index],game.state.JOURNEY.count(game.state,RULES.SUMMER_NEEDS[index]),RULES.SUMMER_REWARDS[index]],Rect2(28,98,424,174)).add_theme_font_size_override("font_size",15)
	game._button(card,"返回",Rect2(28,282,204,44),summer)
	game._button(card,"確認參與",Rect2(248,282,204,44),summer_finish.bind(index),true)
func summer_finish(index: int) -> void:
	var result := RULES.summer_job(game.state,index)
	if result["ok"]: game._save(false)
	summer_preview(index)
	game._update_ui()
	game.toast(result["text"])
func goals(page: int = 0) -> void:
	page=posmod(page,2)
	var card: Panel=game._open_modal("莊園階段目標","六項獨立目標，不必依序；獎勵只領一次。",460)
	for n in range(3):
		var index := page*3+n
		game._label(card,RULES.GOAL_NAMES[index]+" · %d銀" % RULES.GOAL_REWARDS[index],Rect2(28,98+n*60,300,25),17)
		game._label(card,RULES.GOAL_TEXT[index],Rect2(28,126+n*60,330,22),12)
		game._button(card,"已領" if game.state.estate["milestones"][index] else "領取",Rect2(364,101+n*60,88,44),claim.bind(index)).disabled=game.state.estate["milestones"][index] or not RULES.goal_ready(game.state,index)
	game.inventory_panels.pagination(card,page,2,goals)
	game._label(card,"照料%d次 · 領取工藝%d件 · 夏日協作%d件" % [game.state.estate["care_total"],game.state.estate["craft_total"],game.state.estate["summer_completed"]],Rect2(28,342,424,26),14)
	game._button(card,"回經營總覽",Rect2(28,400,424,44),hub)
func claim(index: int) -> void:
	var result := RULES.claim_goal(game.state,index)
	if result["ok"]: game._save(false)
	goals(index/3)
	game._update_ui()
	game.toast(result["text"])
