extends RefCounted
var game: Node
var furniture: Array=[]
var furniture_guard := ""
var selected := 0
func _init(controller: Node) -> void: game=controller
func hub() -> void:
	var card: Panel=game._open_modal("田園長期發展","慢慢相識、照料與經營，留下屬於莊園的故事。",460)
	var entries := [["居民專屬生活事件",people],["養殖個性與成長",animals],["四聚落探索旅章",journeys],["每週合作訂單",orders],["長期養成目標",goals],["農舍家具布置",furnishings]]
	for i in range(6): game._button(card,entries[i][0],Rect2(28,98+i*48,424,44),entries[i][1],i==0)
	game._button(card,"回經營總覽",Rect2(28,406,424,42),game.estate_panels.hub)
func people(page: int = 0) -> void:
	page=posmod(page,3)
	var card: Panel=game._open_modal("相識的另一頁","好感5可開始；先走近本人，最後選擇才消耗資源。",410)
	for n in range(3):
		var index := page*3+n
		var id: String=game.state.CHAPTER.PEOPLE[index]
		game._button(card,game.state.JOURNEY.NAMES[index]+" · "+("已記下" if game.state.chapter["stories"][id]>0 else "未完成"),Rect2(28,98+n*56,424,46),story.bind(id,0))
	game.inventory_panels.pagination(card,page,3,people)
	game._button(card,"回長期發展",Rect2(28,354,424,44),hub)
func story(id: String, page: int = 0) -> void:
	var s: RefCounted=game.state
	if id not in s.CHAPTER.PEOPLE: return
	var data: Array=s.CHAPTER.DATA.STORIES[s.CHAPTER.PEOPLE.find(id)]
	var choice: int=s.chapter["stories"][id]
	var card: Panel=game._open_modal(data[0],"完成需3體力與20分鐘；好感+2，每段只完成一次。",460)
	var text: String=data[1]
	if choice==0 and page==0: text=s.CHAPTER.DATA.OPENINGS[s.CHAPTER.PEOPLE.find(id)]+"\n\n"+data[1]
	if choice>0: text+="\n\n你選擇了："+data[choice+1]+"\n\n"+data[choice+3]
	else: text+=("\n\n目前好感%d /5。" if page==0 else "\n\n兩種選擇會留下不同的日常回應。\n目前好感%d /5。") % s.JOURNEY.friendship(s,id)
	var body: Label=game._paragraph(card,text,Rect2(28,98,424,226))
	body.add_theme_font_size_override("font_size",15)
	body.add_theme_constant_override("line_spacing",2)
	if choice>0:
		game._button(card,"回生活事件",Rect2(28,408,424,40),people)
	elif page==0:
		game._button(card,"繼續這段相處",Rect2(28,346,424,44),story.bind(id,1),true)
		game._button(card,"改天再來",Rect2(28,408,424,40),people)
	else:
		for i in range(2): game._button(card,data[i+2],Rect2(28,346+i*56,424,46),choose_story.bind(id,i+1),i==0).disabled=not s.JOURNEY.near(s,id) or s.JOURNEY.friendship(s,id)<5 or s.energy<3 or s.minute>1300
func choose_story(id: String, choice: int) -> void:
	finish(game.state.CHAPTER.story(game.state,id,choice))
	story(id)
func finish(result: Dictionary) -> void:
	if result["ok"]: game._save(false)
	game._update_ui()
	game.toast(result["text"])
func animals(page: int = 0) -> void:
	page=posmod(page,3)
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("生靈成長手札","個性、每日照料與親密階段各自記錄。",410)
	for n in range(3):
		var index := page*3+n
		if index>=8: break
		var id: String=s.RANCH_DATA.ORDER[index]
		game._button(card,s.RANCH_DATA.SPECIES[id]["name"]+" · "+["初識","熟悉","信任","親密"][s.GROWTH.stage(s,id)],Rect2(28,98+n*56,424,46),animal.bind(id))
	game.inventory_panels.pagination(card,page,3,animals)
	game._button(card,"回長期發展",Rect2(28,354,424,44),hub)
func animal(id: String) -> void:
	var s: RefCounted=game.state
	var index: int=s.RANCH_DATA.ORDER.find(id)
	var card: Panel=game._open_modal(s.RANCH_DATA.SPECIES[id]["name"]+" · "+s.GROWTH.TRAITS[index],"個性互動每日一次，需2體力與10分鐘。",460)
	game._paragraph(card,"已照料%d日 · 好感%d\n個性互動：%s\n\n熟悉：3日、好感3，謝禮飼料3。\n信任：7日、好感10，謝禮飼料5。\n親密：14日、好感20，謝禮飼料8。" % [s.growth["days"][id],s.GROWTH.bond(s,id),s.GROWTH.TIPS[index]],Rect2(28,98,424,192)).add_theme_font_size_override("font_size",14)
	for tier in range(3):
		var claimed: bool=(s.growth["claimed"][id] & (1<<tier))!=0
		game._button(card,"已領" if claimed else ["熟悉謝禮","信任謝禮","親密謝禮"][tier],Rect2(28+tier*144,292,136,42),growth_claim.bind(id,tier)).disabled=claimed or not s.GROWTH.owned(s,id) or s.GROWTH.stage(s,id)<=tier
	game._button(card,"個性互動",Rect2(28,346,204,44),growth_action.bind(id,true),true)
	game._button(card,"日常照料",Rect2(248,346,204,44),growth_action.bind(id,false))
	game._button(card,"回成長手札",Rect2(28,406,424,42),animals)
func growth_claim(id: String, tier: int) -> void:
	finish(game.state.GROWTH.claim(game.state,id,tier))
	animal(id)
func growth_action(id: String, special: bool) -> void:
	var s: RefCounted=game.state
	var result: Dictionary=s.GROWTH.interact(s,id) if special else s.GROWTH.hen_care(s) if id=="hen" else s.RANCH.care(s,id)
	finish(result)
	if result["ok"] and game.world.has_method("animate_animal"): game.world.animate_animal(id,"care")
	animal(id)
func journeys() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("四方探索旅章","觀察記錄、交付物資、完成工藝，依序留下旅程。",410)
	for i in range(4): game._button(card,s.CHAPTER.DATA.JOURNEYS[i][0]+" %d /3" % s.chapter["journeys"][i],Rect2(28,98+i*54,424,46),journey.bind(i))
	game._button(card,"回長期發展",Rect2(28,354,424,44),hub)
func journey(index: int) -> void:
	var s: RefCounted=game.state
	var data: Array=s.CHAPTER.DATA.JOURNEYS[index]
	var stage: int=s.chapter["journeys"][index]
	var card: Panel=game._open_modal(data[0],"旅章進度 %d /3 · 最終謝禮%d銀" % [stage,data[6]],410)
	var text := ""
	for i in range(3): text+=("✓ " if stage>i else "○ ")+data[i+1]+"\n"
	if stage in [1,2]:
		var need: Array=data[stage+3]
		text+="\n需%s ×%d（行囊%d）\n到該聚落工坊旁交付。" % [s.CHAPTER.need_name(s,need),need[2],s.CHAPTER.count(s,need)]
	elif stage==0: text+="\n先到該聚落的第一處記錄點觀察。"
	else: text+="\n旅章已記錄，謝禮不會重複領取。"
	game._paragraph(card,text,Rect2(28,98,424,198)).add_theme_font_size_override("font_size",15)
	game._button(card,"確認這一步",Rect2(28,300,424,42),journey_apply.bind(index,stage),true).disabled=stage>=3
	game._button(card,"回四方旅章",Rect2(28,354,424,44),journeys)
func journey_apply(index: int, expected: int) -> void:
	var s: RefCounted=game.state
	if s.chapter["journeys"][index]!=expected: game.toast("進度已改變，請重新查看。")
	else: finish(s.CHAPTER.journey(s,index))
	journey(index)
func orders() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("每週合作訂單","第%d週 · 走近莊園出貨箱，確認後交付。" % s.CHAPTER.week(s),410)
	for i in range(3):
		var data: Dictionary=s.CHAPTER.order(s,i)
		var done: bool=s.chapter["order_week"]==s.CHAPTER.week(s) and (s.chapter["order_bits"] & (1<<i))!=0
		game._button(card,data["title"]+(" · 已完成" if done else " · %d銀" % data["reward"]),Rect2(28,98+i*56,424,46),order_preview.bind(i))
	game._label(card,"累計完成%d單，跨週未交付物資仍保留。" % s.chapter["orders_done"],Rect2(28,282,424,30),14)
	game._button(card,"回長期發展",Rect2(28,354,424,44),hub)
func order_preview(index: int) -> void:
	var s: RefCounted=game.state
	var data: Dictionary=s.CHAPTER.order(s,index)
	var guard: String=s.CHAPTER.fingerprint(s)
	var card: Panel=game._open_modal(data["title"],"本週此單只能交付一次；取消不消耗物資。",410)
	var text := ""
	for need in data["needs"]: text+="%s ×%d（行囊%d）\n" % [s.CHAPTER.need_name(s,need),need[2],s.CHAPTER.count(s,need)]
	var reason: String=s.CHAPTER.order_reason(s,index)
	text+="\n謝禮%d銀。\n%s" % [data["reward"],"可以交付。" if reason=="" else reason]
	game._paragraph(card,text,Rect2(28,98,424,180)).add_theme_font_size_override("font_size",15)
	game._button(card,"確認交付",Rect2(28,292,424,44),order_apply.bind(index,guard),true).disabled=reason!=""
	game._button(card,"取消",Rect2(28,354,424,44),orders)
func order_apply(index: int, guard: String) -> void:
	finish(game.state.CHAPTER.deliver_order(game.state,index,guard))
	orders()
func goals() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("長期養成目標","每項謝禮只領一次，不必依序完成。",460)
	var descriptions := ["完成3名居民專屬生活事件","完成4個聚落探索旅章","累計交付6份每週合作訂單","3種生物達到親密階段"]
	for i in range(4):
		game._label(card,s.CHAPTER.DATA.GOALS[i][0]+" · %d銀" % s.CHAPTER.DATA.GOALS[i][1],Rect2(28,98+i*66,300,26),17)
		game._label(card,descriptions[i],Rect2(28,125+i*66,330,24),13)
		game._button(card,"已領" if s.chapter["goals"][i] else "領取",Rect2(364,102+i*66,88,44),goal_claim.bind(i)).disabled=s.chapter["goals"][i] or not s.CHAPTER.goal_ready(s,i)
	game._button(card,"回長期發展",Rect2(28,406,424,42),hub)
func goal_claim(index: int) -> void:
	finish(game.state.CHAPTER.claim_goal(game.state,index))
	goals()
func furnishings() -> void:
	furniture=game.state.interior.duplicate(true)
	furniture_guard=JSON.stringify(game.state.to_data()).sha256_text()
	selected=0
	furniture_page()
func furniture_page() -> void:
	var s: RefCounted=game.state
	var reason: String=s.INTERIOR.reason(furniture)
	if reason=="" and s.area_id=="house" and s.INTERIOR.blocked(furniture,s.player_position): reason="家具會蓋住主角，請先移開角色。"
	if s.area_id!="house": reason="可先預覽；回到農舍才能確認布置。"
	var card: Panel=game._open_modal("農舍家具布置","每次移動8像素；確認前不改變房間或存檔。",500)
	var preview := preload("res://scripts/furniture_preview.gd").new()
	preview.position=Vector2(28,92)
	preview.size=Vector2(424,174)
	preview.clip_contents=true
	card.add_child(preview)
	var canvas := preload("res://scripts/furniture_canvas.gd").new()
	var factor := minf(preview.size.x/280,preview.size.y/145)
	canvas.position=Vector2((preview.size.x-264*factor)/2,3)-Vector2(108,76)*factor
	canvas.scale=Vector2.ONE*factor
	canvas.layout=furniture
	canvas.selected=selected
	canvas.legal=reason==""
	preview.add_child(canvas)
	game._label(card,"可以套用；出口與家具皆可走近。" if reason=="" else reason,Rect2(28,270,424,26),13)
	game._button(card,"上一件",Rect2(28,302,100,40),furniture_select.bind(-1))
	game._label(card,s.INTERIOR.NAMES[selected]+" · %d°" % (int(furniture[selected][2])*90),Rect2(142,310,200,26),17)
	game._button(card,"下一件",Rect2(352,302,100,40),furniture_select.bind(1))
	for i in range(4): game._button(card,["←","↑","↓","→"][i],Rect2(28+i*64,350,58,44),furniture_move.bind([Vector2(-8,0),Vector2(0,-8),Vector2(0,8),Vector2(8,0)][i]))
	game._button(card,"旋轉90°",Rect2(284,350,168,44),furniture_rotate)
	game._button(card,"確認布置",Rect2(28,402,424,44),furniture_apply,true).disabled=reason!=""
	game._button(card,"還原原始配置",Rect2(28,454,204,40),furniture_reset)
	game._button(card,"取消並返回",Rect2(248,454,204,40),hub)
func furniture_select(delta: int) -> void:
	selected=posmod(selected+delta,8)
	furniture_page()
func furniture_move(offset: Vector2) -> void:
	furniture[selected][0]+=int(offset.x)
	furniture[selected][1]+=int(offset.y)
	furniture_page()
func furniture_rotate() -> void:
	furniture[selected][2]=(int(furniture[selected][2])+1)%4
	furniture_page()
func furniture_reset() -> void:
	furniture=game.state.INTERIOR.defaults()
	furniture_page()
func furniture_apply() -> void:
	var result: Dictionary=game.state.INTERIOR.apply(game.state,furniture,furniture_guard)
	if result["ok"]:
		game._mount_area()
		finish(result)
		furnishings()
	else: game.toast(result["text"])
