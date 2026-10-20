extends RefCounted

var game: Node
const PAGE_SIZE := 3

func _init(controller: Node) -> void:
	game = controller

func pages(order: Array) -> int:
	return ceili(order.size() / float(PAGE_SIZE))

func pagination(card: Panel, page: int, count: int, callback: Callable) -> void:
	game._button(card, "上一頁", Rect2(28, 278, 128, 44), callback.bind(posmod(page - 1, count)))
	var label: Label = game._label(card, "%d / %d" % [page + 1, count], Rect2(166, 287, 148, 26), 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game._button(card, "下一頁", Rect2(324, 278, 128, 44), callback.bind((page + 1) % count))

func bag(page: int = 0) -> void:
	var order: Array = game.State.CROP_ORDER
	page = posmod(page, pages(order))
	var card: Panel = game._open_modal("行囊與收成", "八種春季作物 · 原料先留好，再到出貨箱出售。", 410)
	for n in range(PAGE_SIZE):
		var i := page * PAGE_SIZE + n
		if i >= order.size(): break
		var crop: String = order[i]
		var data: Dictionary = game.State.CROPS[crop]
		game._label(card, data["name"], Rect2(28, 97 + n*44, 180, 26), 17)
		game._label(card, "種子 %d · 收成 %d · %d 銀" % [game.state.seeds.get(crop,0), game.state.produce.get(crop,0), data["price"]], Rect2(210, 100+n*44, 242, 24), 13)
	game._button(card, "採集素材", Rect2(28, 230, 100, 44), game._show_materials)
	game._button(card, "成品雞蛋", Rect2(136, 230, 100, 44), game._show_goods)
	game._button(card, "魚獲", Rect2(244, 230, 100, 44), game._show_fish_bag)
	game._button(card, "料理", Rect2(352, 230, 100, 44), game._show_meals)
	pagination(card, page, pages(order), bag)
	game._button(card, "收好行囊", Rect2(28, 344, 424, 46), game._close_modal, true)

func shop(page: int = 0) -> void:
	var order: Array = game.State.CROP_ORDER
	page = posmod(page, pages(order))
	var card: Panel = game._open_modal("行旅種子鋪", "現有 %d 銀 · 每份種子種一格，收成一份" % game.state.money, 410)
	for n in range(PAGE_SIZE):
		var i := page * PAGE_SIZE + n
		if i >= order.size(): break
		var crop: String = order[i]
		var data: Dictionary = game.State.CROPS[crop]
		game._label(card, data["name"], Rect2(28, 98+n*56, 260, 24), 17)
		game._label(card, "%d 日成熟 · 售 %d 銀 · 種子 %d" % [data["days"], data["price"], game.state.seeds.get(crop,0)], Rect2(28, 124+n*56, 260, 20), 12)
		var buy: Button = game._button(card, "3 包 / %d 銀" % (data["seed_cost"]*3), Rect2(306, 101+n*56, 146, 44), game._buy.bind(crop), true)
		buy.disabled = game.state.money < data["seed_cost"]*3
	pagination(card, page, pages(order), shop)
	game._button(card, "下次再來", Rect2(28, 344, 424, 46), game._close_modal)

func seeds(page: int = 0) -> void:
	var order: Array = game.State.CROP_ORDER
	page = posmod(page, pages(order))
	var card: Panel = game._open_modal("選擇播種作物", "點選後回到田間 · 種子不足不會消耗體力", 410)
	for n in range(PAGE_SIZE):
		var i := page * PAGE_SIZE + n
		if i >= order.size(): break
		var crop: String = order[i]
		game._button(card, "%s ×%d · %d 日" % [game.State.CROPS[crop]["name"], game.state.seeds.get(crop,0), game.State.CROPS[crop]["days"]], Rect2(28, 100+n*56, 424, 46), choose_seed.bind(crop), crop == game.selected_crop)
	pagination(card, page, pages(order), seeds)
	game._button(card, "回到田間", Rect2(28, 344, 424, 46), game._close_modal)

func choose_seed(crop: String) -> void:
	if not game.State.CROPS.has(crop): return
	game.selected_crop = crop
	game.selected_tool = 1
	game._close_modal()
	game._update_ui()
	game.toast("準備播種%s，持有 %d 包。" % [game.State.CROPS[crop]["name"], game.state.seeds.get(crop,0)])

func meals(page: int = 0) -> void:
	var order: Array = game.State.COOKING.ORDER
	page = posmod(page, pages(order))
	var card: Panel = game._open_modal("行囊料理", "體力 %d / 100 · 料理留作食用，出貨箱會保留。" % game.state.energy, 410)
	for n in range(PAGE_SIZE):
		var i := page * PAGE_SIZE + n
		if i >= order.size(): break
		var recipe: String = order[i]
		var data: Dictionary = game.State.COOKING.RECIPES[recipe]
		game._meal_icon(card, i % 3, Vector2(28, 102+n*56))
		game._label(card, "%s ×%d" % [data["name"], game.state.meals.get(recipe,0)], Rect2(70,100+n*56,252,27),17)
		game._label(card, "恢復最多 %d 體力" % data["energy"], Rect2(70,126+n*56,252,20),12)
		var eat: Button = game._button(card, "食用", Rect2(328,100+n*56,124,46), game._eat_meal.bind(recipe))
		eat.disabled = game.state.meals.get(recipe,0) < 1 or game.state.energy >= 100
	pagination(card, page, pages(order), meals)
	game._button(card, "回到行囊", Rect2(28,344,424,46),game._show_bag,true)

func goods(page: int = 0) -> void:
	var order: Array = game.State.PROCESSING.ORDER
	page = posmod(page, pages(order))
	var card: Panel = game._open_modal("加工成品與雞蛋", "行囊雞蛋 %d 顆 · 巢箱 %d 顆 · 每顆 56 銀" % [game.state.eggs,game.state.nest_eggs],410)
	for n in range(PAGE_SIZE):
		var i := page * PAGE_SIZE + n
		if i >= order.size(): break
		var recipe: String = order[i]
		var data: Dictionary = game.State.PROCESSING.RECIPES[recipe]
		game._label(card,"%s ×%d" % [data["name"],game.state.goods.get(recipe,0)],Rect2(28,102+n*52,424,26),18)
		game._label(card,"每份 %d 銀 · 原料：%s" % [data["price"],game.State.CROPS[data["crop"]]["name"]],Rect2(28,130+n*52,424,20),12)
	pagination(card,page,pages(order),goods)
	game._button(card,"回到行囊",Rect2(28,344,424,46),game._show_bag,true)

func processing(page: int = 0) -> void:
	var order: Array = game.State.PROCESSING.ORDER
	page = posmod(page,pages(order))
	var card: Panel = game._open_modal("烘乾架 · 選擇收成","每批隔日完成 · 每份原料一份成品 · 可放 1 或 3 份",410)
	for n in range(PAGE_SIZE):
		var i := page*PAGE_SIZE+n
		if i >= order.size(): break
		var recipe: String = order[i]
		var data: Dictionary = game.State.PROCESSING.RECIPES[recipe]
		game._label(card,data["name"],Rect2(28,99+n*56,235,24),17)
		game._label(card,"持有原料 %d · 成品 %d 銀" % [game.state.produce.get(data["crop"],0),data["price"]],Rect2(28,125+n*56,235,20),12)
		for j in range(2):
			var count := 1 if j == 0 else 3
			var button: Button = game._button(card,"放 %d 份" % count,Rect2(276+j*90,100+n*56,86,46),game._start_processing.bind(recipe,count),true)
			button.disabled = game.state.produce.get(data["crop"],0) < count
	pagination(card,page,pages(order),processing)
	game._button(card,"暫不加工",Rect2(28,344,424,46),game._close_modal)
