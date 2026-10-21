extends RefCounted

const DATA = preload("res://scripts/ranch_data.gd")
const RULES = preload("res://scripts/ranch_rules.gd")
const ART = preload("res://scripts/approved_art.gd")
var game: Node

func _init(controller: Node) -> void:
	game = controller

func hub() -> void:
	var card: Panel = game._open_modal("雲橋牧場", "八種夥伴 · 四組棲地 · 幼體成長、照料與產物", 420)
	for i in range(4):
		var opened := RULES.home_open(game.state,i)
		game._label(card,DATA.HOMES[i]+(" · 已建好" if opened else " · 未建造"),Rect2(28,100+i*52,266,25),18)
		game._button(card,"前往照料",Rect2(310,97+i*52,142,44),visit.bind(i),true)
	game._label(card,"飼料 %d 份 · 各棲地建材與費用見手冊" % game.state.ranch["feed"],Rect2(28,310,424,22),13)
	game._button(card,"採買飼料 10份／20銀",Rect2(28,341,204,46),supplies)
	game._button(card,"養殖產物行囊",Rect2(248,341,204,46),products)

func visit(home: int) -> void:
	if game.state.area_id != "farm" and game.state.area_id not in DATA.AREAS:
		game.toast("請先回莊園，再從牧場入口出發。")
		return
	game._close_modal()
	game._change_area(DATA.AREAS[home])

func supplies() -> void:
	var answer := RULES.buy_feed(game.state)
	if answer["ok"]: game._save(false)
	hub()
	game._update_ui()
	game.toast(answer["text"])

func home(home_id: int) -> void:
	var card: Panel = game._open_modal(DATA.HOMES[home_id],"每種夥伴到對應棲地照料，回莊園出貨。",420)
	for i in range(2):
		var index := home_id*2+i
		var id: String = DATA.ORDER[index]
		ART.icon(card,ART.ANIMALS,ART.A.FRAMES[index][0],Rect2(28,100+i*94,72,75))
		game._button(card,DATA.SPECIES[id]["name"]+" · 查看",Rect2(120,107+i*94,332,58),animal.bind(id),true)
	var opened := RULES.home_open(game.state,home_id)
	var button: Button = game._button(card,"棲地已建好" if opened else "建造 木%d／石%d／%d銀" % [DATA.HOME_COST[home_id]["wood"],DATA.HOME_COST[home_id]["stone"],DATA.HOME_COST[home_id]["money"]],Rect2(28,299,424,44),build.bind(home_id),true)
	button.disabled = opened
	game._button(card,"牧場總覽",Rect2(28,357,424,44),hub)

func build(home_id: int) -> void:
	var answer := RULES.build(game.state,home_id)
	if answer["ok"]: game._save(false)
	home(home_id)
	game._update_ui()
	game.toast(answer["text"])

func animal(id: String) -> void:
	if not DATA.SPECIES.has(id): return
	var s: RefCounted = game.state
	var definition: Dictionary = DATA.SPECIES[id]
	var owned: bool = s.chickens>0 if id=="hen" else s.ranch["animals"][id]["owned"]
	var card: Panel = game._open_modal(definition["name"],definition["hint"],430)
	var baby: bool = false if id=="hen" else s.ranch["animals"][id]["age"]<definition["days"]
	ART.icon(card,ART.ANIMALS,ART.A.FRAMES[DATA.ORDER.find(id)][3 if owned and baby else 0],Rect2(28,102,100,100))
	var text := "尚未入住。領養 %d 銀。\n請先建造棲地，再迎接夥伴。" % definition["price"]
	if owned:
		if id=="hen":
			text = "%s · 成雞 %d /3\n今日已餵 %d · 巢箱 %d 蛋\n消耗收成小麥，隔日產蛋。" % [s.ranch["hen_name"],s.chickens,s.fed_chickens,s.nest_eggs]
		else:
			var a: Dictionary = s.ranch["animals"][id]
			text = "%s · %s\n成長 %d /%d · 好感 %d /100\n今日餵養：%s · 照料：%s\n待領 %s ×%d\n成年產物進度 %d /%d" % [a["name"],"幼體" if baby else "成年",a["age"],definition["days"],a["bond"],"已餵" if a["fed"] else "未餵","完成" if a["cared"] else "未做",definition["product"],a["ready"],a["cycle"],definition["interval"]]
	game._paragraph(card,text,Rect2(142,100,310,145)).add_theme_font_size_override("font_size",14)
	var local := RULES.on_site(s,id)
	var feed: Button = game._button(card,"餵收成小麥" if id=="hen" else ("好友回饋 · 今日免飼料" if RULES.feed_cost(s,id)==0 else "餵養 1份飼料"),Rect2(28,250,204,44),action.bind(id,"feed"),true)
	feed.disabled = not owned or not local
	var care: Button = game._button(card,"照料／觀察",Rect2(248,250,204,44),action.bind(id,"care"))
	care.disabled = not owned or not local or id=="hen"
	var collect: Button = game._button(card,"領取產物",Rect2(28,302,204,44),action.bind(id,"collect"),true)
	collect.disabled = not owned or not local
	var name_button: Button = game._button(card,"取個名字",Rect2(248,302,204,44),rename.bind(id))
	name_button.disabled = not owned or not local
	game._button(card,"回到棲地",Rect2(28,366,204,44),home.bind(definition["home"]))
	var adopt: Button = game._button(card,"領養 %d 銀" % definition["price"],Rect2(248,366,204,44),action.bind(id,"buy"),true)
	adopt.disabled = not local or (owned and id!="hen") or not RULES.home_open(s,definition["home"])

func action(id: String, kind: String) -> void:
	var answer: Dictionary
	match kind:
		"buy": answer = RULES.buy(game.state,id)
		"feed": answer = RULES.feed(game.state,id)
		"care": answer = RULES.care(game.state,id)
		_: answer = RULES.collect(game.state,id)
	if answer["ok"]:
		if game.world.has_method("animate_animal"): game.world.animate_animal(id,kind)
		game._save(false)
		game.audio_system.play_effect("harvest" if kind=="collect" else "seed")
	animal(id)
	game._update_ui()
	game.toast(answer["text"])

func rename(id: String) -> void:
	var card: Panel = game._open_modal("為夥伴取名","一至十二個字；蜂蠶的名字代表整個飼養群。")
	var input := LineEdit.new()
	input.position = Vector2(28,130)
	input.size = Vector2(424,54)
	input.max_length = 12
	input.text = game.state.ranch["hen_name"] if id=="hen" else game.state.ranch["animals"][id]["name"]
	card.add_child(input)
	game._button(card,"保存名字",Rect2(28,282,424,46),save_name.bind(id,input),true)

func save_name(id: String, field: LineEdit) -> void:
	var answer := RULES.rename(game.state,id,field.text)
	if answer["ok"]: game._save(false)
	animal(id)
	game.toast(answer["text"])

func products(page: int = 0) -> void:
	page = posmod(page,3)
	var card: Panel = game._open_modal("養殖產物","領取後才進入行囊；在莊園出貨箱一起出售。",410)
	for n in range(3):
		var i := page*3+n
		if i>=8: break
		var id: String = DATA.ORDER[i]
		var count: int = game.state.eggs if id=="hen" else game.state.ranch["stock"][id]
		ART.icon(card,ART.ITEMS,ART.I.FRAMES[1][i],Rect2(28,98+n*58,46,46))
		game._label(card,"%s ×%d · 每份%d銀" % [DATA.SPECIES[id]["product"],count,DATA.SPECIES[id]["sell"]],Rect2(88,108+n*58,364,35),16)
	game.inventory_panels.pagination(card,page,3,products)
	game._button(card,"牧場總覽",Rect2(28,354,424,44),hub,true)

func visitor(id: String) -> void:
	var answer := RULES.talk(game.state,id)
	if not answer["ok"]:
		game.toast(answer["text"])
		return
	var d: Dictionary = DATA.RESIDENTS[id]
	var card: Panel = game._open_modal(d["name"]+" · "+d["role"],"好感 %d · 每日初次交談增加一次" % game.state.ranch["friends"][id])
	ART.icon(card,ART.RESIDENTS,ART.R.FRAMES[d["sprite"]/3][d["sprite"]%3],Rect2(28,100,92,155))
	game._paragraph(card,game.state.ESTATE.daily_line(game.state,id)+("\n\n雨天路滑，走動時記得小心。" if game.state.is_raining() else ""),Rect2(137,100,315,155)).add_theme_font_size_override("font_size",15)
	game._button(card,"故事與委託",Rect2(28,282,204,46),game.life_panels.resident.bind(id),true)
	game._button(card,"改天再聊",Rect2(248,282,204,46),game._close_modal)
	game._save(false)
	game.audio_system.play_effect("talk")
