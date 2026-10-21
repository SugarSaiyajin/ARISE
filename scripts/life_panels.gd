extends RefCounted

const DATA = preload("res://scripts/life_data.gd")
const RULES = preload("res://scripts/life_rules.gd")
const RANCH = preload("res://scripts/ranch_data.gd")
const ART = preload("res://scripts/approved_art.gd")
var game: Node

func _init(controller: Node) -> void:
	game=controller

func hub() -> void:
	var card: Panel = game._open_modal("行旅與工藝","居民上午在牧場，晴天11至18時前往聚落，雨天留在牧場。",410)
	for i in range(4):
		game._button(card,DATA.NAMES[i],Rect2(28,98+i*49,424,44),travel.bind(i),true)
	game._label(card,"飼料在莊園製作；工藝品由各聚落工坊接單。",Rect2(28,302,424,24),13)
	game._button(card,"工坊與配方",Rect2(28,354,204,44),workshop)
	game._button(card,"工藝行囊",Rect2(248,354,204,44),goods)

func travel(index: int) -> void:
	if game.state.area_id=="house":
		game.toast("請先走出農舍，再隨商隊出發。")
		return
	game._close_modal()
	game._change_area(DATA.AREAS[index])

func item_name(source: Array) -> String:
	match source[0]:
		"ranch": return RANCH.SPECIES[source[1]]["product"]
		"produce": return game.State.CROPS[source[1]]["name"]
		_: return game.State.FORAGE.MATERIALS[source[1]]["name"]

func where(id: String) -> String:
	var area: String = DATA.RECIPES[id]["area"]
	return "莊園作業區" if area=="farm" else DATA.NAMES[DATA.AREAS.find(area)]

func workshop(page: int = 0) -> void:
	page=posmod(page,3)
	var card: Panel = game._open_modal("聚落工坊與飼料","飼料現做現取，其他工藝需一個休息日；同時接一單。",410)
	for n in range(3):
		var index := page*3+n
		if index>=DATA.ORDER.size(): break
		var id: String = DATA.ORDER[index]
		game._button(card,DATA.RECIPES[id]["name"]+" · "+where(id),Rect2(28,98+n*56,424,46),recipe.bind(id))
	game.inventory_panels.pagination(card,page,3,workshop)
	game._button(card,"查看工單／領成品",Rect2(28,354,424,44),job,true)

func recipe(id: String) -> void:
	var recipe_data: Dictionary = DATA.RECIPES[id]
	var card: Panel = game._open_modal(recipe_data["name"],"製作地點："+where(id),410)
	var text := "材料與持有數：\n"
	for source in recipe_data["needs"]:
		text+="%s ×%d（持有%d）\n" % [item_name(source),source[2],RULES.count(game.state,source)]
	text += "\n完成 %d 份飼料，立即入庫。" % recipe_data["output"] if id in ["grain_feed","herb_feed"] else "\n休息一天後回本工坊領取。"
	if id=="irrigator": text+="\n一次安裝，每晚替前兩格作物補水。"
	game._paragraph(card,text,Rect2(28,101,424,186)).add_theme_font_size_override("font_size",15)
	game._button(card,"回配方表",Rect2(28,350,204,46),workshop)
	var button: Button = game._button(card,"確認備料製作",Rect2(248,350,204,46),craft.bind(id),true)
	button.disabled = not RULES.can_craft(game.state,id)

func craft(id: String) -> void:
	var result := RULES.craft(game.state,id)
	if result["ok"]: game._save(false)
	recipe(id)
	game._update_ui()
	game.toast(result["text"])

func job() -> void:
	var card: Panel = game._open_modal("工坊委託單","未領成品由工坊保管；重開遊戲不會重複發放。")
	var text := "目前沒有工單。\n\n可先製作飼料，或帶養殖產物到聚落加工。"
	var task: Dictionary = game.state.life["job"]
	if not task.is_empty():
		text="%s\n領取地點：%s\n預計春第%d日完成。\n\n%s" % [DATA.RECIPES[task["id"]]["name"],where(task["id"]),game.state.SPRING.season_day(task["ready_day"]),"成品已完成。" if game.state.day>=task["ready_day"] else "材料已交付，請休息後再來。"]
	game._paragraph(card,text,Rect2(28,100,424,165)).add_theme_font_size_override("font_size",15)
	game._button(card,"回配方表",Rect2(28,282,204,46),workshop)
	game._button(card,"領取成品",Rect2(248,282,204,46),collect,true)

func collect() -> void:
	var result := RULES.collect(game.state)
	if result["ok"]: game._save(false)
	job()
	game._update_ui()
	game.toast(result["text"])

func goods(page: int = 0) -> void:
	page=posmod(page,2)
	var card: Panel = game._open_modal("工藝行囊","工藝品可保留收藏，或在莊園出貨箱出售。",410)
	for n in range(3):
		var index := page*3+n
		if index>=5: break
		var id: String = DATA.GOODS[index]
		var item: Dictionary = DATA.PRODUCTS[id]
		ART.icon(card,ART.ITEMS,ART.I.FRAMES[1][item["icon"]],Rect2(28,99+n*56,44,44))
		game._label(card,"%s ×%d · %d銀" % [item["name"],game.state.life["stock"][id],item["price"]],Rect2(88,108+n*56,364,30),17)
	game.inventory_panels.pagination(card,page,2,goods)
	game._button(card,"行旅總覽",Rect2(28,354,424,44),hub)

func resident(id: String) -> void:
	if not RULES.near_resident(game.state,id):
		game.toast("居民已前往下一個地方，請依行旅時段再找他。")
		return
	var request: Dictionary = DATA.REQUESTS[id]
	var card: Panel = game._open_modal(RANCH.RESIDENTS[id]["name"]+" · 故事與委託","好感 %d · 每位居民每天可交付一次" % game.state.ranch["friends"][id],410)
	var species: String = request["item"]
	var text := "%s\n需要 %s ×1（持有%d）\n謝禮 %d 銀與好感。\n\n相識故事：%s\n好感達3開啟，完整讀完才領一次謝禮。" % [request["purpose"],RANCH.SPECIES[species]["product"],game.state.ranch["stock"][species],request["reward"],DATA.STORIES[id]["title"]]
	game._paragraph(card,text,Rect2(28,99,424,181)).add_theme_font_size_override("font_size",15)
	var give: Button = game._button(card,"交付物資",Rect2(28,294,204,44),deliver.bind(id),true)
	give.disabled = game.state.life["requests"][id]==game.state.day or game.state.ranch["stock"][species]<1
	var replay: bool = game.state.life["events"][id]
	var story_button: Button = game._button(card,"重讀故事" if replay else "相識故事",Rect2(248,294,204,44),story.bind(id,0,replay))
	story_button.disabled = not replay and not RULES.event_available(game.state,id)
	game._button(card,"稍後再聊",Rect2(28,354,424,44),game._close_modal)

func deliver(id: String) -> void:
	var result := RULES.deliver(game.state,id)
	if result["ok"]: game._save(false)
	resident(id)
	game._update_ui()
	game.toast(result["text"])

func story(id: String, page: int = 0, replay: bool = false) -> void:
	if not DATA.STORIES.has(id) or page<0 or page>=2: return
	if (replay and not game.state.life["events"][id]) or (not replay and not RULES.event_available(game.state,id)): return
	var card: Panel = game._open_modal(DATA.STORIES[id]["title"],"相識回憶 · 第%d /2幕" % (page+1))
	game._request_body(card,DATA.STORIES[id]["pages"][page])
	if page==0: game._button(card,"繼續聽",Rect2(28,282,424,46),story.bind(id,1,replay),true)
	else: game._button(card,"收好回憶",Rect2(28,282,424,46),game._close_modal if replay else finish.bind(id),true)

func finish(id: String) -> void:
	var result := RULES.finish_event(game.state,id)
	if result["ok"]: game._save(false)
	game._close_modal()
	game._update_ui()
	game.toast(result["text"])
