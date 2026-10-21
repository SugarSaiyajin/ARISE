extends RefCounted
var game: Node
func _init(controller: Node) -> void: game=controller
func storage(page: int = 0, amount: int = 1) -> void:
	var s: RefCounted=game.state
	var pages: int=game.inventory_panels.pages(s.CROP_ORDER)
	page=posmod(page,pages)
	var card: Panel=game._open_modal("農舍收納箱","存入的作物會保留，不參與出貨、料理或送禮。",410)
	for n in range(3):
		var index := page*3+n
		if index>=s.CROP_ORDER.size(): break
		var id: String=s.CROP_ORDER[index]
		game._label(card,s.CROPS[id]["name"],Rect2(28,99+n*54,180,24),16)
		game._label(card,"行囊%d · 箱內%d" % [s.produce.get(id,0),s.home["stored"][id]],Rect2(28,124+n*54,210,22),12)
		var onsite: bool=s.HOME.near(s,s.HOME.STORAGE)
		game._button(card,"存%d" % amount,Rect2(256,101+n*54,92,44),move.bind(id,true,page,amount)).disabled=not onsite or s.produce.get(id,0)<amount or s.home["stored"][id]>100000000-amount
		game._button(card,"取%d" % amount,Rect2(360,101+n*54,92,44),move.bind(id,false,page,amount)).disabled=not onsite or s.home["stored"][id]<amount or s.produce.get(id,0)>100000000-amount
	game._label(card,"%d / %d" % [page+1,pages],Rect2(188,286,100,26),16)
	game._button(card,"上一頁",Rect2(28,278,128,44),storage.bind(posmod(page-1,pages),amount))
	game._button(card,"下一頁",Rect2(324,278,128,44),storage.bind((page+1)%pages,amount))
	game._button(card,"每次%d份" % amount,Rect2(28,346,204,44),storage.bind(page,5 if amount==1 else 1))
	game._button(card,"回到房間",Rect2(248,346,204,44),game._close_modal,true)
func move(id: String, deposit: bool, page: int, amount: int) -> void:
	var result: Dictionary=game.state.HOME.transfer(game.state,id,deposit,amount)
	if result["ok"]: game._save(false)
	storage(page,amount)
	game._update_ui()
	game.toast(result["text"])
func tea_table() -> void:
	var s: RefCounted=game.state
	var card: Panel=game._open_modal("農舍茶桌","休息一下，再安排今天的生活。")
	game._paragraph(card,"%s\n\n小歇20分鐘，恢復最多8體力，每日一次。\n今天%s小歇。\n布置配色可隨時切換，家具通道保留。" % [s.HOME.THEMES[s.home["theme"]],"已經" if s.home["rested_day"]==s.day else "尚未"],Rect2(28,98,424,160)).add_theme_font_size_override("font_size",15)
	game._button(card,"坐下小歇",Rect2(28,282,204,46),rest,true).disabled=not s.HOME.near(s,s.HOME.CHAIR) or s.home["rested_day"]==s.day or s.energy>=100 or s.minute>1300
	game._button(card,"更換布置配色",Rect2(248,282,204,46),theme)
func rest() -> void:
	var result: Dictionary=game.state.HOME.rest(game.state)
	if result["ok"]: game._save(false)
	tea_table()
	game._update_ui()
	game.toast(result["text"])
func theme() -> void:
	var result: Dictionary=game.state.HOME.theme(game.state)
	if result["ok"]: game._save(false)
	tea_table()
	game.toast(result["text"])
