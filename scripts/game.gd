extends Node2D

const JourneyPanels = preload("res://scripts/journey_panels.gd")
var journey_panels: RefCounted
var mobile_preferences := preload("res://scripts/mobile_preferences.gd").new()
var application_paused := false
var application_unfocused := false

const TestingPanels = preload("res://scripts/testing_panels.gd")
var testing_panels: RefCounted

const State = preload("res://scripts/farm_state.gd")
const World = preload("res://scripts/farm_world.gd")
const AreaWorld = preload("res://scripts/area_world.gd")
const ForestWorld = preload("res://scripts/forest_world.gd")
const RuinsWorld = preload("res://scripts/ruins_world.gd")
const CultureWorld = preload("res://scripts/culture_world.gd")
const LifePanels = preload("res://scripts/life_panels.gd")
var life_panels: RefCounted
const RanchWorld = preload("res://scripts/ranch_world.gd")
const RanchPanels = preload("res://scripts/ranch_panels.gd")
var ranch_panels: RefCounted
const Stick = preload("res://scripts/joystick.gd")
const TouchButton = preload("res://scripts/touch_button.gd")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const AudioDirector = preload("res://scripts/audio_director.gd")
const EGG_ICON = preload("res://assets/pixel/egg.png")
const TEA_MEMORY = preload("res://assets/pixel/tea_memory.png")
const GOODS_SPRITES = preload("res://assets/pixel/dried_goods.png")
const FishingRound = preload("res://scripts/fishing_round.gd")
const FishingView = preload("res://scripts/fishing_view.gd")
const FISH_ICONS = preload("res://assets/pixel/fish.png")
const MEAL_ICONS = preload("res://assets/pixel/meals.png")
const SpringPanels = preload("res://scripts/spring_panels.gd")
const ResidentPanels = preload("res://scripts/resident_panels.gd")
var spring_panels: RefCounted
var resident_panels: RefCounted
var tool_palette: Panel
var current_tool_button: Button
const InventoryPanels = preload("res://scripts/inventory_panels.gd")
var inventory_panels: RefCounted
const CharacterPreview = preload("res://scripts/character_preview.gd")
const DIRECTION_NAMES := ["前方", "左方", "右方", "後方", "左前", "右前", "左後", "右後"]
const FONT = preload("res://assets/fonts/CloudbridgeTC.otf")
const TOOLS := ["hoe", "seed", "water", "harvest"]
const TOOL_NAMES := ["開墾", "播種", "澆水", "採收"]
const SPEED := 66.0
const ToolAction = preload("res://scripts/tool_action.gd")
var tool_action := ToolAction.new()
var queued_click: Variant = null
var state = State.new()
var world: Node2D
var ui: Control
var hud_layer: CanvasLayer
var stick: Control
var tool_buttons: Array[Button] = []
var selected_tool := 2
var last_drawn_tool := -1
var selected_crop := "turnip"
var facing := Vector2.DOWN
var path := PackedVector2Array()
var pending: Dictionary = {}
var navigation := AStarGrid2D.new()
var clock_label: Label
var weather_label: Label
var money_label: Label
var energy_bar: ProgressBar
var energy_label: Label
var seed_button: Button
var stop_button: Button
var action_button: Button
var quest_label: Label
var toast_label: Label
var toast_panel: Panel
var modal: Control
var toast_time := 0.0
var save_timer := 0.0
var work_cooldown := 0.0
var save_allowed := true
var simulation := false
var touch_mode := OS.has_feature("android") or OS.has_feature("ios")
var audio_system: Node
var step_distance := 0.0
var travel_lock := 0.0
var fishing_round: RefCounted
var fishing_view: Control
var fishing_status: Label
var fishing_hint: Label
var fishing_reel: Button
var hero_preview: Control
var preview_direction: Label
var preview_mode_button: Button
var preview_buttons: Array[Button] = []

func _ready() -> void:
	mobile_preferences.load_settings()
	journey_panels = JourneyPanels.new(self)
	testing_panels = TestingPanels.new(self)
	var display_config := ConfigFile.new()
	if display_config.load("user://display_preferences.cfg") == OK:
		var fps: Variant = display_config.get_value("display", "fps", 60)
		Engine.max_fps = fps if fps in [30, 60] else 60
	else:
		Engine.max_fps = 60
	inventory_panels = InventoryPanels.new(self)
	ranch_panels = RanchPanels.new(self)
	life_panels = LifePanels.new(self)
	spring_panels = SpringPanels.new(self)
	resident_panels = ResidentPanels.new(self)
	touch_mode = touch_mode or "--mobile-ui" in OS.get_cmdline_user_args()
	simulation = "--smoke" in OS.get_cmdline_user_args()
	var loaded: bool = state.load_game("user://smoke_session.json" if simulation else "user://farm_save.json")
	if not loaded and state.load_notice != "":
		save_allowed = false
	_mount_area()
	audio_system = AudioDirector.new()
	audio_system.rainy = state.is_raining()
	if simulation:
		audio_system.preferences_path = "user://smoke_audio_preferences.cfg"
		# The scene smoke advances hundreds of virtual frames inside one real frame.
		# Actual playback is covered by the paced Movie Maker presentation demo.
		audio_system.effects_enabled = false
		audio_system.playback_enabled = false
	add_child(audio_system)
	audio_system.set_weather(state.is_raining())
	audio_system.set_interior(state.area_id == "house")
	_build_ui()
	_apply_mobile_layout()
	get_viewport().size_changed.connect(_apply_mobile_layout)
	world.actor = state.player_position
	_update_ui()
	get_tree().auto_accept_quit = false
	if not loaded:
		_show_intro()
	else:
		toast("歡迎回到" + world.display_name() + "。" if state.load_notice == "" else state.load_notice)
	if simulation:
		_run_smoke.call_deferred()

func _mount_area(from_area: String = "", restore_position: bool = true) -> void:
	_hide_tool_palette()
	_cancel_tool_action()
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	match state.area_id:
		"farm": world = World.new()
		"forest": world = ForestWorld.new()
		"ruins": world = RuinsWorld.new()
		"ranch_poultry", "ranch_meadow", "ranch_silk", "ranch_spring": world = RanchWorld.new()
		"culture_grove", "culture_ember", "culture_sanctuary", "culture_market": world = CultureWorld.new()
		_: world = AreaWorld.new()
	world.area_id = state.area_id
	world.action_managed = state.area_id == "farm"
	world.state = state
	world.font = FONT
	world.scale = Vector2(2, 2)
	add_child(world)
	if not restore_position or world.blocked(state.player_position):
		state.player_position = world.entry_spawn(from_area)
	world.actor = state.player_position
	world.update_facing(facing, true)
	_setup_navigation()
	path.clear()
	pending = {}
	step_distance = 0
	if is_instance_valid(stick):
		stick.release_pointer()
		action_button.cancel_touch()
		_apply_mobile_layout()
	if is_instance_valid(audio_system):
		audio_system.set_interior(state.area_id == "house")

func _change_area(destination: String) -> void:
	if destination not in ["farm", "house", "town", "forest", "ruins", "ranch_poultry", "ranch_meadow", "ranch_silk", "ranch_spring", "culture_grove", "culture_ember", "culture_sanctuary", "culture_market"]:
		return
	if destination == "ruins" and not state.route_restored:
		_show_route()
		return
	if destination == state.area_id or travel_lock > 0:
		return
	var origin: String = state.area_id
	state.area_id = destination
	_mount_area(origin, false)
	travel_lock = 0.35
	work_cooldown = 0.4
	_save(false)
	_update_ui()
	toast("抵達" + world.display_name() + "。")

func _setup_navigation() -> void:
	navigation.region = Rect2i(0, 0, 60, 28)
	navigation.cell_size = Vector2(8, 8)
	navigation.offset = Vector2(4, 4)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(28):
		for x in range(60):
			navigation.set_point_solid(Vector2i(x, y), world.blocked(Vector2(x * 8 + 4, y * 8 + 4)))

func _style(bg: String, border: String = "657b66", radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _panel(parent: Node, rect: Rect2, bg: String = "203b33ed", border: String = "63785e") -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(bg, border))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(parent: Node, text: String, rect: Rect2, font_size: int = 16, color: String = "f0e7c9") -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color(color))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.set_script(TouchButton)
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _style("d9c991" if accent else "304b3e", "f1dda4" if accent else "778369"))
	button.add_theme_stylebox_override("hover", _style("ecda9d" if accent else "49634b", "dacb95"))
	button.add_theme_stylebox_override("pressed", _style("b2bd88", "f5e3ae"))
	button.add_theme_color_override("font_color", Color("293d32" if accent else "ede6c9"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	hud_layer = canvas
	add_child(canvas)
	ui = Control.new()
	ui.size = MobileLayout.DESIGN_SIZE
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	ui.theme = theme
	_panel(ui, Rect2(14, 12, 932, 62), "1e372fef", "8e9e77")
	_label(ui, "異鄉田園", Rect2(30, 19, 220, 31), 25)
	_label(ui, "CLOUDBRIDGE  /  雲橋初晴", Rect2(31, 50, 235, 17), 10, "aebe9b")
	clock_label = _label(ui, "", Rect2(302, 22, 190, 26), 20)
	weather_label = _label(ui, "", Rect2(303, 49, 210, 17), 11, "b6c9a5")
	energy_label = _label(ui, "", Rect2(545, 22, 200, 22), 14)
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(545, 50)
	energy_bar.size = Vector2(160, 7)
	energy_bar.show_percentage = false
	energy_bar.add_theme_font_size_override("font_size", 1)
	energy_bar.add_theme_stylebox_override("background", _style("122a24", "122a24", 3))
	energy_bar.add_theme_stylebox_override("fill", _style("b9c88b", "b9c88b", 3))
	ui.add_child(energy_bar)
	energy_bar.set_deferred("size", Vector2(160, 7))
	money_label = _label(ui, "", Rect2(751, 28, 130, 32), 21, "efcf82")
	_button(ui, "選單", Rect2(881, 21, 55, 44), _show_menu)
	_panel(ui, Rect2(292, 82, 376, 28), "264435d9", "68835f")
	quest_label = _label(ui, "", Rect2(305, 85, 354, 23), 12, "f3e1b2")
	_button(ui,"手札",Rect2(680,80,70,44),journey_panels.hub)
	_button(ui,"牧場",Rect2(764,80,70,44),ranch_panels.hub)
	_button(ui,"行旅",Rect2(848,80,78,44),life_panels.hub)
	if touch_mode:
		var bar := _panel(ui,Rect2(160,448,342,82),"203a30eb","8e9a75")
		bar.mouse_filter = Control.MOUSE_FILTER_STOP
		current_tool_button = _button(ui,"工具",Rect2(172,460,130,62),_toggle_tool_palette)
		seed_button = _button(ui,"",Rect2(314,460,176,62),_show_seed_list)
		tool_palette = _panel(ui,Rect2(156,370,402,74),"203a30f5","a7b783")
		tool_palette.mouse_filter = Control.MOUSE_FILTER_STOP
		for i in range(4):
			tool_buttons.append(_button(tool_palette,TOOL_NAMES[i],Rect2(8+i*98,6,92,62),_select_tool.bind(i)))
		tool_palette.hide()
	else:
		var shelf_y := 436 if touch_mode else 444
		var row_y := 462 if touch_mode else 474
		var row_height := 62 if touch_mode else 44
		_panel(ui, Rect2(164, shelf_y, 632, 530 - shelf_y), "203a30f5", "8e9a75")
		_label(ui, "莊園工具", Rect2(181, shelf_y + 5, 100, 18), 11, "aabd9c")
		_label(ui, "點田地走近操作 · 按住右側按鈕連續作業" if touch_mode else "點田地走近操作 · WASD 移動 / E 使用", Rect2(351, shelf_y + 5, 430, 18), 11, "aabd9c")
		for i in range(4):
			var button := _button(ui, TOOL_NAMES[i] if touch_mode else "%d  %s" % [i + 1, TOOL_NAMES[i]], Rect2(179 + i * 105, row_y, 98, row_height), _select_tool.bind(i))
			tool_buttons.append(button)
		seed_button = _button(ui, "", Rect2(604, row_y, 177, row_height), _cycle_crop)
	stick = Stick.new()
	stick.position = Vector2(8, 382)
	stick.size = Vector2.ONE*mobile_preferences.stick_size
	stick.position = Vector2(4 if mobile_preferences.stick_size==160 else 8,530-mobile_preferences.stick_size)
	stick.deadzone = mobile_preferences.deadzone
	stick.engaged.connect(_manual_control_started)
	stick.released.connect(_manual_control_started)
	ui.add_child(stick)
	stop_button = _button(ui,"停止移動",Rect2(14,326,140,44),_stop_moving)
	stop_button.hide()
	action_button = _button(ui, "使用\nE", Rect2(826, 430, 104, 91), _act, true)
	action_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	if not touch_mode: _label(ui,"方向",Rect2(60,360,60,20),11,"f0e3bc")
	toast_panel = _panel(ui, Rect2(208, 389, 544, 44), "1e372ff2", "9eac7d")
	toast_label = _label(toast_panel, "", Rect2(12, 4, 520, 36), 12)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.hide()

func _apply_mobile_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("android") or OS.has_feature("ios"):
		var display_safe := Rect2(DisplayServer.get_display_safe_area())
		if display_safe.has_area():
			safe = get_viewport().get_screen_transform().affine_inverse() * display_safe
	if is_instance_valid(stick):
		_stop_moving()
	_apply_safe_frame(MobileLayout.fit_safe_frame(viewport_size, safe))

func _apply_safe_frame(frame: Rect2) -> void:
	var factor := frame.size.x / MobileLayout.DESIGN_SIZE.x
	world.position = frame.position
	world.scale = Vector2.ONE * 2.0 * factor
	hud_layer.transform = Transform2D(Vector2(factor, 0), Vector2(0, factor), frame.position)

func _viewport_to_world(point: Vector2) -> Vector2:
	return world.get_global_transform().affine_inverse() * point

func _update_ui() -> void:
	if is_instance_valid(stop_button): stop_button.visible = touch_mode and (not path.is_empty() or stick.finger>=0 or stick.mouse_down or stick.direction.length_squared()>0.01)
	var hour := int(state.minute) / 60
	var mins := int(state.minute) % 60
	clock_label.text = "%s %02d /28  %02d:%02d" % [state.JOURNEY.season(state.day),state.SPRING.season_day(state.day), hour, mins]
	weather_label.text = "第%d年 · " % state.JOURNEY.year(state.day) + world.display_name() + (" · 室內" if state.area_id == "house" else " · "+state.JOURNEY.weather(state.day))
	money_label.text = "%d  銀" % state.money
	energy_label.text = "體力   %d / 100" % state.energy
	energy_bar.value = state.energy
	seed_button.text = "%s ×%d" % [State.CROPS[selected_crop]["name"], state.seeds.get(selected_crop,0)]
	if is_instance_valid(current_tool_button):
		current_tool_button.text = TOOL_NAMES[selected_tool]+" ▴"
		current_tool_button.disabled = state.area_id != "farm"
	if last_drawn_tool != selected_tool:
		for i in range(4):
			tool_buttons[i].add_theme_stylebox_override("normal", _style("cfbf88" if i == selected_tool else "304b3e", "efe0ad" if i == selected_tool else "778369"))
			tool_buttons[i].add_theme_color_override("font_color", Color("293d32" if i == selected_tool else "ede6c9"))
		last_drawn_tool = selected_tool
	quest_label.text = state.SPRING.next_objective(state) if state.reward_claimed else "初耕委託  %d / 5 收穫 · 到鎮上找青禾領取 80 銀" % mini(state.harvested, 5)
	if state.area_id == "forest":
		quest_label.text = "霧杉林 · 今日剩餘 %d 處採集點 · 睡醒後更新" % (State.FORAGE.NODES.size() - state.gathered.size())
	if state.area_id != "forest" and state.processing_ready():
		quest_label.text = "烘乾架成品已完成 · 回莊園領取並出貨"
	if state.nest_eggs > 0 and state.area_id != "forest":
		quest_label.text = "雞舍巢箱有 %d 顆蛋 · 記得回莊園領取" % state.nest_eggs
	if state.active_request != "" and state.area_id != "forest":
		var request: Dictionary = State.REQUESTS.REQUESTS[state.active_request]
		quest_label.text = "委託：%s · 找%s交付" % [request["title"], request["resident"]]
	if state.area_id == "ruins":
		quest_label.text = "星紋殘片已記入手札 · 可探索碑文或返回莊園" if state.relic_recovered else "舊驛的星紋石台 · 查看殘片，記下星潮的線索"
	var first_task: String = state.JOURNEY.next_task(state)
	if first_task!="" and state.area_id in ["farm","house"]:
		quest_label.text = "入門 · "+state.JOURNEY.TASK_TEXT[state.JOURNEY.TASKS.find(first_task)]+" · 手札查看"
	var object := _near_object()
	var action: String = {"fish": "釣魚", "route": "驛路", "relic": "查看", "inscription": "碑文", "coop": "雞舍", "dryer": "加工", "forest": "入林", "repair": "圍欄", "tea": "爐灶", "house": "進屋", "town": "進鎮", "farm": "返回", "bed": "休息", "journal": "手札", "notice": "公告", "smith": "交談", "box": "出貨", "shop": "商店", "npc": "交談"}.get(object, TOOL_NAMES[selected_tool] if state.area_id == "farm" else "探索")
	for button in tool_buttons:
		button.disabled = state.area_id != "farm"
	seed_button.disabled = state.area_id != "farm"
	if object.begins_with("gather:"):
		action = "明日再來" if state.gathered.has(object.trim_prefix("gather:")) else "採集"
	action_button.text = action + (("\n互動" if object != "" else "\n按住") if touch_mode else "\nE")
	if tool_action.active:
		action_button.text = "作業中\n" + TOOL_NAMES[tool_action.tool]

func _toggle_tool_palette() -> void:
	if is_instance_valid(tool_palette): tool_palette.visible = not tool_palette.visible

func _hide_tool_palette() -> void:
	if is_instance_valid(tool_palette): tool_palette.hide()

func _show_seed_list() -> void:
	inventory_panels.seeds(maxi(0,State.CROP_ORDER.find(selected_crop))/3)

func _select_tool(index: int) -> void:
	if index < 0 or index >= TOOLS.size():
		return
	selected_tool = index
	_hide_tool_palette()
	audio_system.play_effect("ui")
	_update_ui()

func _cycle_crop() -> void:
	var index := State.CROP_ORDER.find(selected_crop)
	selected_crop = State.CROP_ORDER[(index + 1) % State.CROP_ORDER.size()]
	selected_tool = 1
	_update_ui()
	toast("已選擇%s種子 · 成長需 %d 個澆水日" % [State.CROPS[selected_crop]["name"], State.CROPS[selected_crop]["days"]])

func _process(delta: float) -> void:
	if application_paused or application_unfocused:
		return
	if world == null:
		return
	travel_lock = maxf(0, travel_lock - delta)
	toast_time -= delta
	toast_panel.visible = toast_time > 0 and not is_instance_valid(modal)
	if fishing_round != null:
		_process_fishing(delta)
	if is_instance_valid(modal):
		world.walking = false
		return
	work_cooldown = maxf(0, work_cooldown - delta)
	if state.area_id == "town" and pending.get("object", "") in State.RESIDENTS.ORDER and not path.is_empty():
		var goal: Vector2 = world.interactions()[pending["object"]]
		if goal.distance_to(pending.get("goal",goal)) > 8:
			_walk_to(goal,pending.duplicate())
	if pending.get("object","").begins_with("visitor:") and not path.is_empty():
		var target: String = pending["object"]
		var current: Dictionary = world.interactions()
		if not current.has(target):
			_manual_control_started()
			toast("居民已前往下一個地方，可在行旅手冊查看時段。")
		elif (current[target] as Vector2).distance_to(pending.get("goal",current[target]))>5:
			_walk_to(current[target],pending.duplicate())
	var position_before: Vector2 = state.player_position
	var was_working: bool = tool_action.active
	tool_action.advance(delta)
	if world.action_managed:
		world.action_age = tool_action.elapsed
	if not was_working:
		var direction := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			direction.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			direction.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			direction.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			direction.y += 1
		if stick.direction.length() > 0:
			direction = stick.direction
		if direction.length() > 0:
			path.clear()
			pending = {}
			direction = direction.limit_length()
		elif not path.is_empty() and stick.finger < 0 and not stick.mouse_down:
			var diff: Vector2 = path[0] - state.player_position
			if diff.length() <= SPEED * minf(delta,0.1) + 0.8:
				state.player_position = path[0]
				path.remove_at(0)
				if path.is_empty() and not pending.is_empty():
					_complete_pending()
			else:
				direction = diff.normalized()
		if direction.length() > 0:
			facing = direction.normalized()
			var step := direction * SPEED * minf(delta,0.1)
			var next: Vector2 = state.player_position + Vector2(step.x, 0)
			if not world.blocked(next):
				state.player_position = next
			next = state.player_position + Vector2(0, step.y)
			if not world.blocked(next):
				state.player_position = next
		var destination: String = world.edge_destination(state.player_position)
		if destination != "" and travel_lock <= 0:
			_change_area(destination)
			return
	world.actor = state.player_position
	world.update_facing(facing, tool_action.active)
	var travelled: float = position_before.distance_to(state.player_position)
	world.walking = travelled > 0.01
	step_distance += travelled
	if step_distance >= 10:
		step_distance = 0
		audio_system.play_effect("step", randf_range(0.93, 1.07))
	world.selected_plot = _target_plot()
	if not was_working and not tool_action.active and (Input.is_physical_key_pressed(KEY_E) or action_button.is_held()) and work_cooldown <= 0:
		_act()
	state.minute += delta
	if state.minute >= 1320:
		_sleep()
		toast("夜深了，你回到農舍休息。醒來又是新的一天。")
	save_timer += delta
	if save_timer >= 30:
		_save(false)
	_update_ui()
	if was_working and not tool_action.active and queued_click != null:
		var next_click: Vector2 = queued_click
		queued_click = null
		_click_world(next_click)

func _stop_moving() -> void:
	_manual_control_started()
	stick.release_pointer()
	action_button.cancel_touch()
	world.walking = false
	_update_ui()

func _manual_control_started() -> void:
	path.clear()
	pending = {}
	queued_click = null

func _unhandled_input(event: InputEvent) -> void:
	if application_paused or application_unfocused: return
	if fishing_round != null and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_E]:
		_reel_fishing()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if is_instance_valid(modal):
				_close_modal()
			else:
				_show_menu()
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(modal):
			return
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			_select_tool(event.physical_keycode - KEY_1)
		elif event.physical_keycode == KEY_TAB:
			_cycle_crop()
		elif event.physical_keycode == KEY_B:
			_show_bag()
		elif event.physical_keycode == KEY_F5:
			_save(true)
	if is_instance_valid(modal):
		return
	var click := false
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click = true
		point = _viewport_to_world(event.position)
	elif event is InputEventScreenTouch and event.pressed and not event.canceled:
		click = true
		point = _viewport_to_world(event.position)
	if click:
		_click_world(point)
		get_viewport().set_input_as_handled()

func _click_world(point: Vector2) -> void:
	if application_paused or application_unfocused: return
	if touch_mode and (stick.finger >= 0 or stick.mouse_down):
		return
	_hide_tool_palette()
	if travel_lock > 0:
		return
	if tool_action.active:
		queued_click = point
		return
	var objects: Dictionary = world.interactions()
	if state.area_id == "town":
		var resident := ""
		var nearest := INF
		for id in State.RESIDENTS.ORDER:
			if world.interaction_hitbox(id).has_point(point):
				var distance: float = world.resident_position(id).distance_to(point)
				if distance < nearest:
					nearest = distance
					resident = id
		if resident != "":
			_walk_to(objects[resident], {"object":resident})
			return
	for key in objects:
		if world.interaction_hitbox(key).has_point(point):
			_walk_to(objects[key], {"object": key})
			return
	var index: int = world.plot_at(point)
	if index >= 0:
		_walk_to(world.plot_center(index), {"plot": index})
	elif not touch_mode and not world.blocked(point):
		_walk_to(point, {})

func _walk_to(target: Vector2, task: Dictionary) -> void:
	if touch_mode and not mobile_preferences.tap_navigation:
		path.clear()
		pending={}
		if state.player_position.distance_to(target)>26:
			toast("目前是手動移動；請先用方向盤走近目標。")
		else:
			pending=task
			_complete_pending()
		return
	var start := Vector2i(state.player_position / 8)
	var end := Vector2i(target / 8)
	if not navigation.is_in_boundsv(end) or navigation.is_point_solid(end):
		return
	path = navigation.get_point_path(start, end)
	if path.is_empty():
		toast("這裡暫時走不到，換個方向試試。")
		return
	path.append(target)
	task["goal"] = target
	pending = task

func _complete_pending() -> void:
	var task := pending.duplicate()
	pending = {}
	if task.has("plot"):
		_work(task["plot"])
	elif task.has("object"):
		_interact(task["object"])

func _target_plot() -> int:
	if state.area_id != "farm":
		return -1
	var best := -1
	var distance := 20.0
	var target: Vector2 = state.player_position + facing * 9
	for i in range(state.plots.size()):
		var d: float = world.plot_center(i).distance_to(target)
		if d < distance and world.plot_center(i).distance_to(state.player_position) < 25:
			best = i
			distance = d
	return best

func _near_object() -> String:
	var objects: Dictionary = world.interactions()
	var nearest := ""
	var distance := 21.0
	for key in objects:
		var d: float = state.player_position.distance_to(objects[key])
		if d < distance:
			distance = d
			nearest = key
	return nearest

func _act() -> void:
	if tool_action.active or is_instance_valid(modal) or work_cooldown > 0 or travel_lock > 0:
		return
	path.clear()
	pending = {}
	var object := _near_object()
	if object != "":
		work_cooldown = 0.3
		_interact(object)
	else:
		_work(_target_plot())

func _work(index: int) -> void:
	if tool_action.active or is_instance_valid(modal) or state.area_id != "farm":
		return
	if index >= state.plots.size():
		return
	if index >= 0 and state.player_position.distance_to(world.plot_center(index)) > 26:
		return
	var affected_crop: String = state.plots[index]["crop"] if index >= 0 else selected_crop
	var result: Dictionary = state.work(index, TOOLS[selected_tool], selected_crop)
	work_cooldown = 0.3
	toast(result["text"])
	if result["ok"]:
		path.clear()
		pending = {}
		world.actor = state.player_position
		if state.player_position.distance_to(world.plot_center(index)) > 1:
			facing = state.player_position.direction_to(world.plot_center(index))
		world.update_facing(facing, true)
		tool_action.begin(selected_tool, world.plot_center(index), facing)
		world.walking = false
		world.play_action(selected_tool, world.plot_center(index), affected_crop)
		audio_system.play_effect(TOOLS[selected_tool])
		var colors := [Color("c9a573"), Color("d5d38d"), Color("a2d4d1"), Color("f5db84")]
		world.emit_spark(world.plot_center(index), colors[selected_tool])
		_save(false)
	_update_ui()

func _cancel_tool_action() -> void:
	tool_action.finish()
	queued_click = null
	if is_instance_valid(world):
		world.action_age = World.ACTION_DURATION
		world.walking = false

func _find_resident(id: String) -> void:
	if state.area_id != "town" or id not in State.RESIDENTS.ORDER: return
	_close_modal()
	_walk_to(world.interactions()[id],{"object":id})

func _interact(object: String) -> void:
	if object.begins_with("journey_clue:"):
		journey_panels.clue(int(object.trim_prefix("journey_clue:")))
		return
	if object=="culture_craft":
		life_panels.workshop()
		return
	if object=="culture_gather":
		var result: Dictionary = state.LIFE.gather(state)
		if result["ok"]: _save(false)
		_update_ui()
		toast(result["text"])
		return
	if object.begins_with("animal:"):
		ranch_panels.animal(object.trim_prefix("animal:"))
		return
	if object.begins_with("visitor:"):
		ranch_panels.visitor(object.trim_prefix("visitor:"))
		return
	if object == "ranch_board":
		ranch_panels.home(State.RANCH_DATA.AREAS.find(state.area_id))
		return
	if state.area_id == "town" and object in State.RESIDENTS.ORDER and state.player_position.distance_to(world.interactions()[object]) > 26:
		_walk_to(world.interactions()[object],{"object":object})
		return
	if object.begins_with("gather:"):
		_gather(object.trim_prefix("gather:"))
		return
	if object in ["npc", "smith", "shop"] and state.area_id == "town" and state.active_request != "" and State.REQUESTS.REQUESTS[state.active_request]["recipient"] == object:
		_show_delivery(object)
		return
	match object:
		"house", "town", "farm", "forest", "ruins":
			_change_area(object)
		"fish":
			_show_fishing()
		"route":
			if state.route_restored:
				_change_area("ruins")
			else:
				_show_route()
		"relic":
			_show_relic()
		"inscription":
			_show_reading("舊驛雙語碑文", "東洲與西陸共用的驛站", State.EXPLORATION.INSCRIPTION)
		"coop":
			_show_coop()
		"dryer":
			_show_dryer()
		"repair":
			_show_repair()
		"tea":
			_show_hearth()
		"bed":
			_show_sleep()
		"journal":
			_show_journal()
		"notice":
			spring_panels.board()
		"smith":
			_show_smith()
		"box":
			var result: Dictionary = state.ship_with_reserve()
			toast(result["text"])
			if result["ok"]:
				audio_system.play_effect("coin")
				_save(false)
		"shop":
			if state.area_id == "town": resident_panels.show("shop")
			else: _show_shop()
		"npc":
			_show_qinghe()
	_update_ui()

func _show_qinghe() -> void:
	resident_panels.show("npc")

func _show_smith() -> void:
	resident_panels.show("smith")

func _show_town_guide() -> void:
	_show_reading("雲橋鎮指引", "市集與林地",
		"西邊道路回莊園，東邊道路往霧杉林。\n\n茶館找青禾，橋東找種子商人洛安，南側是鐵匠雷恩。\n\n公告牌可接居民委託，每天最多完成一件；已接委託沒有期限。\n\n初耕委託：採收五份作物，另找青禾領取 80 銀。")

func _request_summary(request_id: String) -> String:
	var request: Dictionary = State.REQUESTS.REQUESTS[request_id]
	var lines := PackedStringArray(["委託人：" + request["resident"]])
	var stocks := {"produce": state.produce, "materials": state.materials, "goods": state.goods}
	for category in stocks:
		for item in request[category]:
			var item_name: String
			match category:
				"produce": item_name = State.CROPS[item]["name"]
				"materials": item_name = State.FORAGE.MATERIALS[item]["name"]
				"goods": item_name = State.PROCESSING.RECIPES[item]["name"]
			lines.append("%s ×%d（持有 %d）" % [item_name, request[category][item], stocks[category][item]])
	lines.append("報酬：%d 銀%s" % [request["reward"], "，青禾好感 +1" if request["friendship"] > 0 else ""])
	lines.append("")
	lines.append("接單不會預扣物品；找本人確認交付後才扣除。")
	return "\n".join(lines)

func _request_body(card: Panel, text: String) -> void:
	var body := _paragraph(card, text, Rect2(28, 98, 424, 171))
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_constant_override("line_spacing", 4)
	body.size = Vector2(424, 171)

func _show_requests() -> void:
	var active: bool = state.active_request != ""
	var request_id: String = state.active_request if active else state.daily_request_id()
	var request: Dictionary = State.REQUESTS.REQUESTS[request_id]
	var done: bool = state.request_completed_day == state.day
	var card := _open_modal(request["title"], "已接委託 · 不限期限" if active else ("今天已完成一件，明天再來吧。" if done else "今日委託 · 接下後可跨日完成"))
	_request_body(card, _request_summary(request_id))
	_button(card, "返回街道" if active else "小鎮指引", Rect2(28, 282, 204, 46), _close_modal if active else _show_town_guide)
	var button := _button(card, "放棄委託" if active else ("今日已完成" if done else "接下委託"), Rect2(248, 282, 204, 46), _confirm_cancel_request if active else _accept_request, not active)
	button.disabled = done

func _accept_request() -> void:
	var result: Dictionary = state.accept_request()
	if result["ok"]:
		_save(false)
	_show_requests()
	_update_ui()
	toast(result["text"])

func _confirm_cancel_request() -> void:
	var card := _open_modal("放棄這件委託？", "不扣物品與銀幣，也不扣好感。")
	_request_body(card, "放棄後可查看今天的委託。\n\n行囊物品保持原樣，已完成的每日次數不會重置。")
	_button(card, "繼續保留", Rect2(28, 282, 204, 46), _show_requests, true)
	_button(card, "確認放棄", Rect2(248, 282, 204, 46), _cancel_request)

func _cancel_request() -> void:
	var result: Dictionary = state.cancel_request()
	if result["ok"]:
		_save(false)
	_show_requests()
	_update_ui()
	toast(result["text"])

func _show_delivery(recipient: String) -> void:
	var request_id: String = state.active_request
	var request: Dictionary = State.REQUESTS.REQUESTS[request_id]
	var card := _open_modal(request["resident"] + " · 委託交付", request["title"])
	_request_body(card, _request_summary(request_id))
	_button(card, "先逛商店" if recipient == "shop" else "先聊聊天", Rect2(28, 282, 204, 46), _resident_normal.bind(recipient))
	var deliver := _button(card, "確認交付", Rect2(248, 282, 204, 46), _deliver_request.bind(recipient), true)
	deliver.disabled = not state.can_deliver_request(recipient)

func _resident_normal(recipient: String) -> void:
	match recipient:
		"npc": _show_qinghe()
		"smith": _show_smith()
		"shop": resident_panels.show("shop")

func _deliver_request(recipient: String) -> void:
	var result: Dictionary = state.deliver_request(recipient)
	if result["ok"]:
		audio_system.play_effect("coin")
		_save(false)
	_show_reading("委託完成" if result["ok"] else "暫時無法交付", "累計完成 %d 件居民委託" % state.requests_completed, result["text"])
	_update_ui()

func _show_journal() -> void:
	var card := _open_modal("莊園手札", "莊園第 %d 日 · 在雲橋留下的足跡" % state.day)
	var text := "收成 %d 份 · 出貨 %d 銀\n委託 %d 件 · 青禾好感 %d\n母雞 %d 隻 · 行囊雞蛋 %d 顆\n舊驛路：%s\n星紋殘片：%s" % [state.harvested, state.total_earned, state.requests_completed, state.friendship, state.chickens, state.eggs, "已修復" if state.route_restored else "尚待修復", "已收藏" if state.relic_recovered else "尚未發現"]
	var body := _paragraph(card, text, Rect2(28, 98, 424, 124))
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_constant_override("line_spacing", 4)
	body.size = Vector2(424, 124)
	_button(card, "第一章手札", Rect2(28, 230, 204, 44), spring_panels.chapter, true)
	var replay := _button(card, "重讀窗邊茶會" if state.tea_event_seen else "茶會尚未解鎖", Rect2(248, 230, 204, 44), _show_tea_event.bind(0, true))
	replay.disabled = not state.tea_event_seen
	_button(card, "收好手札", Rect2(28, 282, 424, 46), _close_modal)

func _show_route() -> void:
	if state.route_restored:
		var card := _open_modal("舊驛路 · 已通行", "主線：重開驛路")
		_request_body(card, State.EXPLORATION.MEMORY if state.relic_recovered else "居民們一起補好路基，東邊的舊驛站重新可達。\n\n沿霧杉林東側道路前往星潮舊驛，查看雙語碑文與中央石台。\n\n星紋殘片：尚未發現")
		_button(card, "收好手札", Rect2(28, 282, 204, 46), _close_modal)
		var enter := _button(card, "踏入舊驛", Rect2(248, 282, 204, 46), _enter_ruins, true)
		enter.disabled = state.area_id != "forest"
		return
	var card := _open_modal("主線 · 重開驛路", "施工地點：霧杉林東側")
	_request_body(card, "居民委託 2 件（已完成 %d）\n木材 6（持有 %d） · 石料 4（持有 %d）\n工費 160 銀（持有 %d）\n\n修復後可前往星潮舊驛，尋找星潮留下的線索。\n請到林地東側施工，確認前不扣材料。" % [state.requests_completed, state.materials["wood"], state.materials["stone"], state.money])
	_button(card, "再準備一下", Rect2(28, 282, 204, 46), _close_modal)
	var restore := _button(card, "修復驛路", Rect2(248, 282, 204, 46), _restore_route, true)
	restore.disabled = not state.can_restore_route()

func _restore_route() -> void:
	var result: Dictionary = state.restore_route()
	if result["ok"]:
		audio_system.play_effect("coin")
		_setup_navigation()
		_save(false)
	_show_route()
	_update_ui()
	toast(result["text"])

func _enter_ruins() -> void:
	_close_modal()
	_change_area("ruins")

func _show_relic(page: int = 0) -> void:
	if state.relic_recovered:
		_show_reading("手札 · 星紋殘片", "發現獎勵已領取，殘片保留於手札。", State.EXPLORATION.MEMORY)
		return
	if state.area_id != "ruins" or not state.route_restored or page < 0 or page >= State.EXPLORATION.PAGES.size():
		return
	var card := _open_modal("舊驛的星紋", "發現獎勵：八種春季種子各 3 包、120 銀 · 第 %d / 2 幕" % (page + 1))
	_request_body(card, State.EXPLORATION.PAGES[page])
	if page == 0:
		_button(card, "繼續查看", Rect2(28, 282, 424, 46), _show_relic.bind(1), true)
	else:
		_button(card, "收好星紋殘片", Rect2(28, 282, 424, 46), _recover_relic, true)

func _recover_relic() -> void:
	var result: Dictionary = state.recover_relic()
	_close_modal()
	if result["ok"]:
		audio_system.play_effect("coin")
		_save(false)
	_update_ui()
	toast(result["text"])

func _show_tea_event(page: int = 0, replay: bool = false) -> void:
	if page < 0 or page >= State.REQUESTS.TEA_PAGES.size():
		return
	if (replay and not state.tea_event_seen) or (not replay and (state.area_id != "town" or not state.tea_event_available())):
		return
	var card := _open_modal("青禾 · 風把茶香帶來", "%s · 第 %d / 3 幕" % ["手札回顧" if replay else "窗邊茶會", page + 1])
	var picture := TextureRect.new()
	picture.texture = TEA_MEMORY
	picture.position = Vector2(28, 94)
	picture.size = Vector2(424, 72)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(picture)
	var body := _paragraph(card, State.REQUESTS.TEA_PAGES[page], Rect2(28, 173, 424, 105))
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_constant_override("line_spacing", 4)
	body.size = Vector2(424, 105)
	if page < 2:
		_button(card, "繼續聽", Rect2(28, 282, 424, 46), _show_tea_event.bind(page + 1, replay), true)
	else:
		_button(card, "收好回憶" if replay else "記下這段相識", Rect2(28, 282, 424, 46), _close_modal if replay else _finish_tea_event, true)

func _finish_tea_event() -> void:
	var result: Dictionary = state.finish_tea_event()
	_close_modal()
	if result["ok"]:
		audio_system.play_effect("talk")
		_save(false)
	_update_ui()
	toast(result["text"])

func _gather(node_id: String) -> void:
	if state.area_id != "forest" or not State.FORAGE.NODES.has(node_id):
		return
	var target: Vector2 = world.interactions()["gather:" + node_id]
	if state.player_position.distance_to(target) > 26:
		return
	var result: Dictionary = state.gather(node_id)
	work_cooldown = 0.5
	toast(result["text"])
	if result["ok"]:
		var kind: String = State.FORAGE.NODES[node_id]["kind"]
		var point: Vector2 = State.FORAGE.NODES[node_id]["position"]
		world.update_facing(state.player_position.direction_to(point), true)
		facing = world.facing
		world.play_action(3 if kind == "herb" else 0, point)
		world.emit_spark(point, Color("d7d4a0"))
		audio_system.play_effect("harvest" if kind == "herb" else "hoe")
		_save(false)
	_update_ui()

func _show_repair() -> void:
	var card := _open_modal("莊園的第一道圍欄", "修復狀態：" + ("已完成" if state.fence_repaired else "等待材料"))
	_paragraph(card, "用撿回的木料與石塊，修好莊園南側的邊界。\n\n需要：木材 6、石料 4\n持有：木材 %d、石料 %d\n\n前往雲橋鎮東邊的霧杉林，採集點每天更新。" % [state.materials["wood"], state.materials["stone"]], Rect2(28, 98, 424, 170))
	_button(card, "稍後再來", Rect2(28, 282, 204, 46), _close_modal)
	var build := _button(card, "修復圍欄", Rect2(248, 282, 204, 46), _repair_fence, true)
	build.disabled = state.fence_repaired or state.materials["wood"] < 6 or state.materials["stone"] < 4

func _repair_fence() -> void:
	var result: Dictionary = state.repair_fence()
	_close_modal()
	toast(result["text"])
	if result["ok"]:
		audio_system.play_effect("coin")
		world.emit_spark(World.FENCE, Color("ead59b"))
		_save(false)

func _show_hearth() -> void:
	var card := _open_modal("農舍爐灶", "把今日收穫煮成旅途中的一餐。")
	_button(card, "爐邊草茶 · 香草回復體力", Rect2(28, 100, 424, 48), _show_tea)
	_button(card, "料理食譜 · 製作餐點", Rect2(28, 158, 424, 48), _show_cookbook.bind(0), true)
	_button(card, "料理背包 · 查看與食用", Rect2(28, 216, 424, 48), _show_meals)
	_button(card, "離開爐灶", Rect2(28, 282, 424, 46), _close_modal)

func _meal_icon(card: Panel, index: int, at: Vector2) -> void:
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = MEAL_ICONS
	atlas.region = Rect2(index * 24, 0, 24, 24)
	icon.texture = atlas
	icon.position = at
	icon.size = Vector2(32, 32)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(icon)

func _show_cookbook(index: int = 0) -> void:
	index = posmod(index, State.COOKING.ORDER.size())
	var recipe: String = State.COOKING.ORDER[index]
	var data: Dictionary = State.COOKING.RECIPES[recipe]
	var card := _open_modal("爐灶食譜 %d / %d" % [index + 1, State.COOKING.ORDER.size()], "每次製作一份 · 不耗體力 · 成品放入料理背包")
	_meal_icon(card, index % 3, Vector2(28, 101))
	_label(card, "%s · 恢復 %d 體力" % [data["name"], data["energy"]], Rect2(76, 100, 376, 30), 19)
	var text := ""
	for ingredient in data["ingredients"]:
		text += "%s ×%d（持有 %d）\n" % [ingredient["name"], ingredient["amount"], state.ingredient_count(ingredient)]
	text += "已做好 %d 份；需在農舍爐灶製作。" % state.meals[recipe]
	var body := _paragraph(card, text, Rect2(28, 140, 424, 84))
	body.add_theme_font_size_override("font_size", 14)
	_button(card, "上一頁", Rect2(28, 230, 98, 44), _show_cookbook.bind(index - 1))
	_button(card, "下一頁", Rect2(136, 230, 98, 44), _show_cookbook.bind(index + 1))
	var make := _button(card, "製作一份", Rect2(248, 230, 204, 44), _cook_meal.bind(recipe, index), true)
	make.disabled = not state.can_cook(recipe)
	_button(card, "回到爐灶", Rect2(28, 282, 424, 46), _show_hearth)

func _cook_meal(recipe: String, index: int) -> void:
	var result: Dictionary = state.cook(recipe)
	if result["ok"]:
		_save(false)
		audio_system.play_effect("harvest")
	_show_cookbook(index)
	_update_ui()
	toast(result["text"])

func _show_meals(page: int = 0) -> void:
	inventory_panels.meals(page)

func _eat_meal(recipe: String) -> void:
	var result: Dictionary = state.eat_meal(recipe)
	if result["ok"]:
		_save(false)
		audio_system.play_effect("rest")
	_show_meals(maxi(0, State.COOKING.ORDER.find(recipe)) / 3)
	_update_ui()
	toast(result["text"])

func _show_tea() -> void:
	var card := _open_modal("爐邊草茶", "霧香草 %d 份 · 體力 %d / 100" % [state.materials["herb"], state.energy])
	_paragraph(card, "把林地採來的霧香草放進熱水，歇一口氣。\n\n一份香草可煮一杯茶，恢復 20 體力。\n體力已滿時不會消耗香草。", Rect2(28, 98, 424, 165))
	_button(card, "留著稍後喝", Rect2(28, 282, 204, 46), _close_modal)
	var brew := _button(card, "煮一杯茶", Rect2(248, 282, 204, 46), _brew_tea, true)
	brew.disabled = state.materials["herb"] < 1 or state.energy >= State.MAX_ENERGY

func _brew_tea() -> void:
	var result: Dictionary = state.brew_tea()
	_close_modal()
	toast(result["text"])
	if result["ok"]:
		audio_system.play_effect("rest")
		_save(false)
	_update_ui()

func _show_fishing() -> void:
	if not state.fishing_rod:
		var card := _open_modal("製作魚竿", "木材 4 · 石料 2 · 80 銀")
		_request_body(card, "在池邊歇一口氣，也許能帶回晚餐。\n\n魚竿只需製作一次，可用於莊園、霧泉與舊驛釣點。\n每次投竿消耗 2 體力；等浮標下沉，再按收線。\n\n持有：木材 %d、石料 %d、%d 銀" % [state.materials["wood"], state.materials["stone"], state.money])
		_button(card, "稍後再來", Rect2(28, 282, 204, 46), _close_modal)
		var craft := _button(card, "製作魚竿", Rect2(248, 282, 204, 46), _craft_fishing_rod, true)
		craft.disabled = state.materials["wood"] < 4 or state.materials["stone"] < 2 or state.money < 80
		return
	var species: String = State.FISHING.GROUNDS[state.area_id]["fish"]
	var card := _open_modal("池邊垂釣", "此處魚種：%s · 每尾 %d 銀" % [State.FISHING.FISH[species]["name"], State.FISHING.FISH[species]["price"]])
	_request_body(card, "等待浮標下沉與提示出現，立即按「收線」。\n\n每次投竿消耗 2 體力；失手、中止也不退還。\n每天最多釣到三尾，失手不扣魚獲名額。\n\n體力 %d / 100 · 今日魚獲 %d / 3" % [state.energy, state.fish_caught_today])
	_button(card, "再等等", Rect2(28, 282, 204, 46), _close_modal)
	var cast := _button(card, "投竿 · 體力 -2", Rect2(248, 282, 204, 46), _begin_fishing, true)
	cast.disabled = not state.can_begin_fishing()

func _craft_fishing_rod() -> void:
	var result: Dictionary = state.craft_fishing_rod()
	if result["ok"]:
		audio_system.play_effect("coin")
		_save(false)
	_show_fishing()
	_update_ui()
	toast(result["text"])

func _begin_fishing() -> void:
	var card := _open_modal("垂釣中", "已消耗 2 體力 · 關閉／返回會中止本次投竿")
	var result: Dictionary = state.begin_fishing()
	if not result["ok"]:
		_close_modal()
		toast(result["text"])
		return
	_save(false)
	fishing_round = FishingRound.new()
	fishing_round.bite_window = State.FISHING.GROUNDS[state.area_id]["window"]
	fishing_view = FishingView.new()
	fishing_view.position = Vector2(28, 96)
	fishing_view.size = Vector2(424, 84)
	card.add_child(fishing_view)
	fishing_status = _label(card, "等待魚兒咬鉤……", Rect2(28, 190, 424, 32), 21, "ead79e")
	fishing_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fishing_hint = _label(card, "浮標平穩時先別收線。", Rect2(28, 227, 424, 21), 13)
	fishing_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fishing_reel = _button(card, "收線", Rect2(28, 258, 424, 64), _reel_fishing, true)
	fishing_reel.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	audio_system.play_effect("water")
	_update_ui()

func _process_fishing(delta: float) -> void:
	var was_biting: bool = fishing_round.is_biting()
	fishing_round.advance(delta)
	if fishing_round.result != "":
		_resolve_fishing(fishing_round.result)
		return
	var biting: bool = fishing_round.is_biting()
	fishing_view.biting = biting
	fishing_status.text = "浮標下沉了！現在收線！" if biting else "等待魚兒咬鉤……"
	fishing_hint.text = "按下收線 · 鍵盤 Space / E 也可以" if biting else "浮標平穩時先別收線。"
	if biting and not was_biting:
		audio_system.play_effect("ui")

func _reel_fishing() -> void:
	if fishing_round == null:
		return
	_resolve_fishing(fishing_round.reel())

func _resolve_fishing(outcome: String) -> void:
	var result: Dictionary = state.finish_fishing(outcome == "caught")
	fishing_round = null
	_save(false)
	audio_system.play_effect("harvest" if result["ok"] else "ui")
	var text: String = result["text"]
	if outcome == "early":
		text = "還沒咬鉤就收線，這次沒有收穫。體力已消耗，今日魚獲名額保留。"
	elif outcome == "late":
		text = "魚兒游走了，下次在浮標下沉時及時收線。體力已消耗，今日魚獲名額保留。"
	_show_reading("釣魚成果", "今日魚獲 %d / 3 · 體力 %d / 100" % [state.fish_caught_today, state.energy], text)
	_update_ui()

func _show_fish_bag() -> void:
	var card := _open_modal("行囊魚獲", "出貨箱會與作物、成品、雞蛋一起出售魚獲。")
	for i in range(State.FISHING.ORDER.size()):
		var species: String = State.FISHING.ORDER[i]
		var data: Dictionary = State.FISHING.FISH[species]
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = FISH_ICONS
		atlas.region = Rect2(i * 24, 0, 24, 24)
		icon.texture = atlas
		icon.position = Vector2(28, 102 + i * 44)
		icon.size = Vector2(30, 30)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.add_child(icon)
		_label(card, "%s ×%d · 每尾 %d 銀" % [data["name"], state.fish[species], data["price"]], Rect2(70, 103 + i * 44, 380, 30), 16)
	_label(card, "今日魚獲 %d / 3 · %s" % [state.fish_caught_today, "已有魚竿" if state.fishing_rod else "尚未製作魚竿"], Rect2(28, 240, 424, 28), 14)
	_button(card, "回到行囊", Rect2(28, 282, 424, 46), _show_bag, true)

func _show_coop() -> void:
	if not state.coop_built:
		var card := _open_modal("建造莊園雞舍", "木材 8 · 石料 6 · 100 銀")
		_request_body(card, "讓莊園多一點咕咕聲。\n\n雞舍可養三隻母雞，每隻需另付 80 銀。\n每隻每天吃一份小麥收成，餵食後隔日產一顆蛋。未餵食只暫停產蛋，不會死亡。\n\n持有：木材 %d、石料 %d、%d 銀" % [state.materials["wood"], state.materials["stone"], state.money])
		_button(card, "稍後再來", Rect2(28, 282, 204, 46), _close_modal)
		var build := _button(card, "建造雞舍", Rect2(248, 282, 204, 46), _build_coop, true)
		build.disabled = state.materials["wood"] < 8 or state.materials["stone"] < 6 or state.money < 100
		return
	var card := _open_modal("雞舍 · %d 隻母雞" % state.chickens, "母雞 80 銀 / 隻 · 上限 3 隻 · 雞蛋售價 56 銀")
	_label(card, "今日已餵 %d / %d 隻 · 待餵 %d 隻" % [state.fed_chickens, state.chickens, state.chickens - state.fed_chickens], Rect2(28, 100, 424, 28), 17)
	_label(card, "小麥收成 %d 份；種子不能當飼料。" % state.produce["wheat"], Rect2(28, 136, 424, 25), 14)
	_label(card, "巢箱 %d / 24 顆 · 行囊雞蛋 %d 顆" % [state.nest_eggs, state.eggs], Rect2(28, 168, 424, 25), 15)
	_label(card, "餵食後睡一晚產蛋，巢箱快滿時請先領蛋。", Rect2(28, 201, 424, 22), 12, "b7c69f")
	var buy := _button(card, "買母雞", Rect2(28, 234, 132, 44), _buy_chicken, true)
	buy.disabled = state.money < State.LIVESTOCK.CHICKEN_PRICE or state.chickens >= State.LIVESTOCK.MAX_CHICKENS
	var feed := _button(card, "餵食", Rect2(174, 234, 132, 44), _feed_chickens, true)
	feed.disabled = not state.can_feed_chickens()
	var collect := _button(card, "領蛋", Rect2(320, 234, 132, 44), _collect_eggs, true)
	collect.disabled = state.nest_eggs <= 0 or state.eggs > State.LIVESTOCK.MAX_EGGS - state.nest_eggs
	_button(card, "回莊園走走", Rect2(28, 288, 424, 44), _close_modal)

func _build_coop() -> void:
	var result: Dictionary = state.build_coop()
	_coop_result(result, "coin")

func _buy_chicken() -> void:
	var result: Dictionary = state.buy_chicken()
	_coop_result(result, "coin")

func _feed_chickens() -> void:
	var result: Dictionary = state.feed_chickens()
	_coop_result(result, "seed")

func _collect_eggs() -> void:
	var result: Dictionary = state.collect_eggs()
	_coop_result(result, "harvest")

func _coop_result(result: Dictionary, sound: String) -> void:
	if result["ok"]:
		audio_system.play_effect(sound)
		_save(false)
	_show_coop()
	_update_ui()
	toast(result["text"])

func _show_dryer(page: int = 0) -> void:
	if not state.rack_built:
		var card := _open_modal("建造烘乾架", "木材 4 · 石料 2 · 60 銀")
		_paragraph(card, "把收成留一份給明天。\n\n烘乾架每批可放入 1 或 3 份相同作物，睡一晚後回來領取，成品可出貨。\n\n持有：木材 %d、石料 %d、%d 銀" % [state.materials["wood"], state.materials["stone"], state.money], Rect2(28, 98, 424, 168))
		_button(card, "稍後再來", Rect2(28, 282, 204, 46), _close_modal)
		var build := _button(card, "建造", Rect2(248, 282, 204, 46), _build_dryer, true)
		build.disabled = state.materials["wood"] < 4 or state.materials["stone"] < 2 or state.money < 60
		return
	if not state.processing_job.is_empty():
		var job: Dictionary = state.processing_job
		var ready: bool = state.processing_ready()
		var card := _open_modal("烘乾架 · " + ("可以領取" if ready else "暖風加工中"), "成品留在架上，不會自動出售。")
		var recipe: Dictionary = State.PROCESSING.RECIPES[job["recipe"]]
		_paragraph(card, "%s × %d\n\n%s\n\n領取後可到出貨箱出售，每份 %d 銀。\n先領取這一批，才能再放入新的作物。" % [recipe["name"], job["amount"], "加工完成，隨時可領取。" if ready else "睡到明天後即可領取；選單與重開遊戲不會加速。", recipe["price"]], Rect2(28, 98, 424, 168))
		_button(card, "回莊園走走", Rect2(28, 282, 204, 46), _close_modal)
		var collect := _button(card, "領取成品" if ready else "明早完成", Rect2(248, 282, 204, 46), _collect_processing, true)
		collect.disabled = not ready
		return
	inventory_panels.processing(page)

func _build_dryer() -> void:
	var result: Dictionary = state.build_dryer()
	if result["ok"]:
		audio_system.play_effect("coin")
		_save(false)
	_show_dryer()
	_update_ui()
	toast(result["text"])

func _start_processing(recipe: String, amount: int) -> void:
	var result: Dictionary = state.start_processing(recipe, amount)
	if result["ok"]:
		audio_system.play_effect("seed")
		_save(false)
	_show_dryer()
	_update_ui()
	toast(result["text"])

func _collect_processing() -> void:
	var result: Dictionary = state.collect_processing()
	if result["ok"]:
		audio_system.play_effect("harvest")
		_save(false)
	_show_dryer()
	_update_ui()
	toast(result["text"])

func _show_goods(page: int = 0) -> void:
	inventory_panels.goods(page)

func _show_materials() -> void:
	var card := _open_modal("採集素材", "素材保留供修復與煮茶，出貨箱不會出售素材。")
	for i in range(State.FORAGE.ORDER.size()):
		var kind: String = State.FORAGE.ORDER[i]
		_label(card, "%s    × %d" % [State.FORAGE.MATERIALS[kind]["name"], state.materials[kind]], Rect2(28, 101 + i * 44, 424, 30), 19)
	_label(card, "圍欄：" + ("已修復" if state.fence_repaired else "需要木材 6、石料 4"), Rect2(28, 238, 424, 28), 15)
	_button(card, "回到行囊", Rect2(28, 282, 424, 46), _show_bag, true)

func _show_reading(title: String, subtitle: String, text: String) -> void:
	var card := _open_modal(title, subtitle)
	var body := _paragraph(card, text, Rect2(28, 98, 424, 179))
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_constant_override("line_spacing", 4)
	body.size = Vector2(424, 179)
	_button(card, "收好手札", Rect2(28, 282, 424, 46), _close_modal, true)

func toast(message: String) -> void:
	toast_label.text = message
	toast_time = 4.5

func _open_modal(title: String, subtitle: String = "", height: float = 348) -> Panel:
	_hide_tool_palette()
	_cancel_tool_action()
	_close_modal()
	path.clear()
	pending = {}
	stick.release_pointer()
	action_button.cancel_touch()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color("101e23b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var card := _panel(modal, Rect2(240, (540-height)/2.0, 480, height), "213c33", "bdc397")
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(card, title, Rect2(28, 22, 388, 34), 24)
	var subtitle_label := _label(card, subtitle, Rect2(29, 62, 420, 30), 12, "b5c59e")
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.size = Vector2(420,30)
	_button(card, "×", Rect2(423, 15, 44, 44), _close_modal)
	return card

func _close_modal() -> void:
	if fishing_round != null:
		state.cancel_fishing()
	fishing_round = null
	fishing_view = null
	fishing_status = null
	fishing_hint = null
	fishing_reel = null
	hero_preview = null
	preview_direction = null
	preview_mode_button = null
	preview_buttons.clear()
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null

func _paragraph(parent: Node, text: String, rect: Rect2) -> Label:
	var label := _label(parent, text, rect, 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 8)
	# Setting text before wrap can expand Label to its unwrapped minimum width.
	label.size = rect.size
	return label

func _show_intro() -> void:
	var card := _open_modal("風把你帶到了雲橋", "異鄉田園  /  春夏相知 0.24")
	_paragraph(card, "一座舊莊園，一片等待照料的田地。\n\n① 澆水：照料左上角四株蕪菁。\n② 休息：進農舍，點床鋪睡到明天。\n③ 採收：成熟後採收，送往出貨箱。\n④ 探索：採集木石，建烘乾架加工收成。", Rect2(28, 98, 424, 175))
	_button(card, "跟著入門任務", Rect2(28, 282, 204, 46), journey_panels.tutorial)
	_button(card, "開始田園生活", Rect2(248, 282, 204, 46), _start_play, true)

func _start_play() -> void:
	_close_modal()
	toast(state.load_notice if state.load_notice != "" else "先選澆水工具，再點左上角的四株蕪菁。")

func _show_menu() -> void:
	var card := _open_modal("莊園手札", "遊戲已暫停 · 關閉視窗或切到背景時會存檔")
	_button(card, "背包與收成", Rect2(28, 99, 204, 48), _show_bag)
	_button(card, "莊園生活手札", Rect2(248, 99, 204, 48), journey_panels.hub)
	_button(card, "存檔與試玩設定", Rect2(28, 161, 204, 48), testing_panels.hub)
	_button(card, "繼續遊玩", Rect2(248, 161, 204, 48), _close_modal, true)
	_button(card, "音樂與音效", Rect2(28, 220, 204, 46), _show_audio_settings)
	_button(card, "角色外觀", Rect2(248, 220, 204, 46), _show_character)
	_button(card,"旅人造型",Rect2(28,282,204,46),_show_style)
	_button(card,"手機手感",Rect2(248,282,204,46),journey_panels.controls)

func _show_style() -> void:
	var art = preload("res://scripts/approved_art.gd")
	var card := _open_modal("選擇旅人造型","兩款造型共用同一份莊園進度，可隨時更換。",410)
	for i in range(2):
		var style: String = ["male","female"][i]
		art.icon(card,art.hero_texture(style,0),art.hero_frame(style,0,0),Rect2(50+i*220,99,160,170))
		_button(card,"男旅人" if i==0 else "女旅人",Rect2(28+i*220,283,204,48),_set_style.bind(style),true)
	_button(card,"回到選單",Rect2(28,354,424,44),_show_menu)

func _set_style(style: String) -> void:
	if style not in ["male","female"]: return
	state.hero_style = style
	_save(false)
	_show_character()

func _show_character() -> void:
	var card := _open_modal("旅人身影", "新旅人造型 · 八方向移動與作業預覽。")
	hero_preview = CharacterPreview.new()
	hero_preview.style = state.hero_style
	hero_preview.position = Vector2(28, 98)
	hero_preview.size = Vector2(168, 166)
	card.add_child(hero_preview)
	var places := [Vector2(298, 212), Vector2(220, 156), Vector2(376, 156), Vector2(298, 100),
		Vector2(220, 212), Vector2(376, 212), Vector2(220, 100), Vector2(376, 100)]
	for row in range(8):
		preview_buttons.append(_button(card, DIRECTION_NAMES[row], Rect2(places[row], Vector2(76, 44)), _choose_character_direction.bind(row)))
	preview_direction = _label(card, "", Rect2(298, 157, 76, 44), 15, "e3d7a3")
	preview_direction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_mode_button = _button(card, "動作：站立", Rect2(28, 282, 204, 46), _cycle_character_motion, true)
	_button(card, "回到選單", Rect2(248, 282, 204, 46), _show_menu)
	_choose_character_direction(world.facing_filter.row)

func _choose_character_direction(row: int) -> void:
	if not is_instance_valid(hero_preview) or row < 0 or row >= 8:
		return
	hero_preview.row = row
	hero_preview.elapsed = 0
	hero_preview.queue_redraw()
	preview_direction.text = "面向\n" + DIRECTION_NAMES[row]
	for i in range(preview_buttons.size()):
		preview_buttons[i].add_theme_stylebox_override("normal", _style("58775a" if i == row else "304e41", "d9c98e" if i == row else "7b926d"))

func _cycle_character_motion() -> void:
	if not is_instance_valid(hero_preview):
		return
	hero_preview.motion = (hero_preview.motion + 1) % 3
	hero_preview.elapsed = 0
	hero_preview.queue_redraw()
	preview_mode_button.text = "動作：" + ["站立", "步行", "作業"][hero_preview.motion]

func _show_audio_settings() -> void:
	var card := _open_modal("聽見雲橋", "點擊調整音量：0 → 25 → 50 → 75 → 100%；0 為關閉。")
	var channels := ["music", "effects", "ambience"]
	var names := ["背景音樂", "操作音效", "田園環境聲"]
	for i in range(channels.size()):
		var channel: String = channels[i]
		_button(card, "%s    %d%%" % [names[i], roundi(audio_system.volumes[channel] * 100)],
			Rect2(28, 101 + i * 56, 424, 46), _cycle_volume.bind(channel))
	_button(card, "回到莊園", Rect2(28, 282, 424, 46), _close_modal, true)

func _cycle_volume(channel: String) -> void:
	var value := fmod(floorf(audio_system.volumes[channel] * 4 + 0.01) + 1, 5) / 4.0
	audio_system.set_volume(channel, value)
	var error: Error = audio_system.save_preferences()
	_show_audio_settings()
	audio_system.play_effect("ui")
	if error != OK:
		toast("音量已調整，但偏好設定儲存失敗。")

func _show_bag(page: int = 0) -> void:
	inventory_panels.bag(page)

func _show_shop(page: int = 0) -> void:
	inventory_panels.shop(page)

func _buy(crop: String) -> void:
	var result: Dictionary = state.buy(crop, 3)
	_show_shop(maxi(0, State.CROP_ORDER.find(crop)) / 3)
	toast(result["text"])
	_update_ui()
	if result["ok"]:
		audio_system.play_effect("coin")
		_save(false)

func _show_sleep() -> void:
	var card := _open_modal("今晚早點休息？", "睡眠會恢復體力，澆過水的作物會成長一天。")
	var wet := 0
	var planted := 0
	for plot in state.plots:
		if plot["crop"] != "":
			planted += 1
			if plot["watered"]:
				wet += 1
	_paragraph(card, "今天已照料 %d / %d 格作物。\n\n沒有澆水的作物會暫停生長，不會枯死。\n明天的天氣：%s\n\n休息後會自動儲存進度。" % [wet, planted, state.JOURNEY.weather(state.day+1)], Rect2(28, 100, 424, 170))
	_button(card, "再忙一會", Rect2(28, 282, 204, 46), _close_modal)
	_button(card, "睡到明天", Rect2(248, 282, 204, 46), _sleep, true)

func _sleep() -> void:
	var finished_spring: bool = state.SPRING.season_day(state.day) == 28
	_close_modal()
	path.clear()
	pending = {}
	state.sleep()
	_mount_area()
	travel_lock = 0.35
	audio_system.set_weather(state.is_raining())
	audio_system.set_interior(state.area_id == "house")
	audio_system.play_effect("rest")
	world.actor = state.player_position
	_save(false)
	_update_ui()
	toast("%s %d 日的早晨。%s" % [state.JOURNEY.season(state.day),state.SPRING.season_day(state.day), "雨水已替田地澆好水。" if state.is_raining() else "體力恢復了，去看看田地吧。"])
	if finished_spring:
		_show_reading("換季小結","新季節已到來，莊園進度繼續保留。", "累計收成 %d 份，出貨收入 %d 銀。\n完成居民委託 %d 件，青禾好感 %d。\n\n第一章：%s\n\n新的季節從今天開始，作物、物品與相識都會留下。" % [state.harvested,state.total_earned,state.requests_completed,state.friendship,"已完成" if state.spring_progress["chapter_done"] else "仍在旅途中"])

func _save(feedback: bool = false) -> void:
	save_timer = 0
	if not save_allowed:
		if feedback:
			toast("存檔已保護，請先備份損壞的原檔。詳見 README。")
		return
	var error: Error = state.save_game("user://smoke_session.json" if simulation else "user://farm_save.json")
	if error != OK:
		toast("儲存失敗：%s。請確認可用空間與權限。" % error_string(error))
	elif feedback:
		toast("進度已儲存。下次會從這裡繼續。")

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save(false)
		_quit_cleanly()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(modal):
			_close_modal()
		else:
			_show_menu()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		application_paused = false
		audio_system.set_suspended("application", false)
		_apply_mobile_layout.call_deferred()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		application_unfocused = false
		audio_system.set_suspended("focus", false)
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if what == NOTIFICATION_APPLICATION_PAUSED: application_paused = true
		else: application_unfocused = true
		_cancel_tool_action()
		audio_system.set_suspended("application" if what == NOTIFICATION_APPLICATION_PAUSED else "focus", true)
		if fishing_round != null:
			_close_modal()
		_save(false)
		stick.release_pointer()
		action_button.cancel_touch()
		path.clear()
		pending = {}
		if not is_instance_valid(modal):
			_show_menu()

func _quit_cleanly() -> void:
	audio_system.shutdown()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _run_smoke() -> void:
	# Exercise real scene callbacks, navigation and UI without touching player saves.
	_close_modal()
	if touch_mode:
		assert(tool_buttons[0].size.y >= 62, "Mobile tools need larger touch targets")
		assert(not action_button.text.contains("\nE"), "Mobile UI should show touch instructions")
	state = State.new()
	_mount_area()
	state.player_position = Vector2(232, 200)
	_click_world(world.plot_center(0))
	assert(not path.is_empty(), "Click navigation should find a route to the plot")
	var frames := 0
	while not path.is_empty() and frames < 900:
		_process(1.0 / 30.0)
		frames += 1
	assert(path.is_empty(), "Navigation must reach its destination")
	assert(state.plots[0]["watered"], "Click-to-walk must execute the selected tool on arrival")
	_select_tool(0)
	state.player_position = world.plot_center(10)
	_smoke_work(10)
	assert(state.plots[10]["tilled"])
	_select_tool(1)
	_smoke_work(10)
	assert(state.plots[10]["crop"] == "turnip")
	_select_tool(2)
	_smoke_work(10)
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	assert(state.area_id == "house", "Farmhouse door enters interior")
	travel_lock = 0
	_smoke_walk(AreaWorld.JOURNAL)
	assert(is_instance_valid(modal), "Journal opens saved progress")
	_close_modal()
	_smoke_walk(AreaWorld.BED)
	assert(is_instance_valid(modal), "Bed opens sleep confirmation")
	var before_pause: float = state.minute
	_process(5)
	assert(state.minute == before_pause, "Time must pause in menus")
	_sleep()
	assert(state.day == 2 and state.area_id == "house")
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	assert(state.area_id == "farm", "Interior exit returns to farm")
	travel_lock = 0
	state.player_position = world.plot_center(0)
	_select_tool(3)
	_smoke_work(0)
	assert(state.produce["turnip"] == 1)
	_smoke_walk(World.BOX)
	assert(state.money == 138)
	_smoke_walk(World.SHOP)
	assert(is_instance_valid(modal), "Clicking shop must open seed store")
	_buy("wheat")
	assert(state.seeds["wheat"] == 8 and state.money == 108)
	_close_modal()
	_smoke_walk(World.TOWN_GATE)
	assert(state.area_id == "town", "East road enters town")
	travel_lock = 0
	_smoke_walk(AreaWorld.NOTICE)
	assert(is_instance_valid(modal))
	_close_modal()
	_smoke_walk(AreaWorld.MERCHANT_POS)
	assert(is_instance_valid(modal), "Town merchant opens seed store across bridge")
	_close_modal()
	_smoke_walk(AreaWorld.SMITH_POS)
	assert(is_instance_valid(modal), "Smith shares town lore")
	_close_modal()
	_smoke_walk(AreaWorld.QINGHE_POS)
	assert(state.friendship == 1)
	_close_modal()
	_show_bag()
	_close_modal()
	_smoke_walk(AreaWorld.FOREST_GATE)
	assert(state.area_id == "forest", "Town east road enters forest")
	travel_lock = 0
	var farm_before: Array = state.plots.duplicate(true)
	_smoke_work(0)
	assert(state.plots == farm_before, "Forest cannot modify farm plots")
	for node_id in State.FORAGE.NODES:
		_smoke_walk(State.FORAGE.NODES[node_id]["position"])
	assert(state.materials == {"wood": 6, "stone": 4, "herb": 3})
	_save(false)
	var forest_saved = State.new()
	assert(forest_saved.load_game("user://smoke_session.json"))
	assert(_smoke_saved_matches(forest_saved), "Forest stock and depletion survive save")
	_smoke_walk(ForestWorld.EXIT)
	assert(state.area_id == "town")
	travel_lock = 0
	_smoke_walk(AreaWorld.FOREST_GATE)
	assert(state.area_id == "forest")
	travel_lock = 0
	var wood_before: int = state.materials["wood"]
	_smoke_walk(State.FORAGE.NODES["wood_1"]["position"])
	assert(state.materials["wood"] == wood_before, "Reentry cannot duplicate gathered rewards")
	_smoke_walk(ForestWorld.EXIT)
	travel_lock = 0
	_smoke_walk(AreaWorld.FARM_EXIT)
	assert(state.area_id == "farm", "Town west road returns to farm")
	travel_lock = 0
	_smoke_walk(World.FENCE)
	assert(is_instance_valid(modal))
	_repair_fence()
	assert(state.fence_repaired and state.materials["wood"] == 0 and state.materials["stone"] == 0)
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.HEARTH)
	assert(is_instance_valid(modal))
	var before_tea: int = state.energy
	_brew_tea()
	assert(state.energy == mini(100, before_tea + 20) and state.materials["herb"] == 2)
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	# A notch-safe frame changes both drawing and world hit coordinates together.
	var safe_frame := MobileLayout.fit_safe_frame(Vector2(960, 540), Rect2(28, 0, 904, 516))
	_apply_safe_frame(safe_frame)
	var test_point: Vector2 = world.plot_center(12)
	var viewport_point: Vector2 = world.get_global_transform() * test_point
	assert(_viewport_to_world(viewport_point).is_equal_approx(test_point))
	_apply_mobile_layout()
	stick.update_pointer(Vector2(100, 56))
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.position = Vector2(40, 40)
	press.pressed = true
	action_button._gui_input(press)
	_notification(NOTIFICATION_APPLICATION_PAUSED)
	assert(stick.direction == Vector2.ZERO and not action_button.is_held())
	assert(is_instance_valid(modal), "Backgrounding must pause the session")
	var paused_at: float = state.minute
	_process(10)
	assert(state.minute == paused_at, "No time should pass while backgrounded")
	assert(audio_system.pause_reasons.has("application"), "Audio must suspend in the background")
	_notification(NOTIFICATION_APPLICATION_RESUMED)
	assert(audio_system.pause_reasons.is_empty(), "Audio suspension must clear on resume")
	_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(not is_instance_valid(modal), "Android back closes current menu")
	_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(is_instance_valid(modal), "Android back opens pause menu during play")
	_close_modal()
	_show_audio_settings()
	var old_volume: float = audio_system.volumes["music"]
	_cycle_volume("music")
	assert(audio_system.volumes["music"] != old_volume, "Audio settings must change volume")
	_close_modal()
	state.player_position = Vector2(232, 200)
	_save(false)
	var restored = State.new()
	assert(restored.load_game("user://smoke_session.json"))
	assert(restored.money == state.money and restored.day == 2)
	_select_tool(2)
	for plot in [1, 7, 8]:
		_smoke_walk(world.plot_center(plot))
	state.area_id = "forest"
	_mount_area("town", false)
	state.minute = 1319.99
	_process(0.1)
	assert(state.area_id == "house" and state.day == 3 and state.energy == 100, "Nightfall in forest returns player home")
	assert(state.gathered.is_empty() and state.fence_repaired, "New day renews forest and preserves repaired manor")
	_smoke_processing()
	_smoke_requests()
	_smoke_livestock()
	_smoke_exploration()
	_smoke_fishing()
	_smoke_cooking()
	state = State.new()
	_mount_area()
	world.actor = state.player_position
	world.action_age = World.ACTION_DURATION
	world.particles.clear()
	_select_tool(2)
	_update_ui()
	toast("春風正好，從一小片田地開始。")
	if "--capture" in OS.get_cmdline_user_args():
		if "--intro" in OS.get_cmdline_user_args():
			_show_intro()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png("/tmp/arise-prototype.png")
		assert(error == OK)
	print("SCENE SMOKE PASS: farm loops, main story, three fishing grounds, cooking, portable touch eating, full stamina guard, background, shipping, persistence")
	await _quit_cleanly()

func _smoke_saved_matches(loaded: RefCounted) -> bool:
	var expected: Dictionary = state.to_data()
	var actual: Dictionary = loaded.to_data()
	# JSON decimal conversion may alter sub-frame clock precision.
	var time_matches := is_equal_approx(float(actual["minute"]), float(expected["minute"]))
	actual.erase("minute")
	expected.erase("minute")
	return time_matches and actual == expected

func _smoke_processing() -> void:
	# Use actual inherited crops and a second day's forest resources.
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	_select_tool(3)
	for plot in [1, 7, 8]:
		_smoke_walk(world.plot_center(plot))
	assert(state.produce["turnip"] == 3)
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.FOREST_GATE)
	travel_lock = 0
	for node_id in ["wood_1", "wood_2", "stone_1"]:
		_smoke_walk(State.FORAGE.NODES[node_id]["position"])
	# Clicking the previously missed left half of the exit label now works.
	_smoke_walk(Vector2(31, 108))
	assert(state.area_id == "town")
	travel_lock = 0
	_smoke_walk(AreaWorld.FARM_EXIT)
	travel_lock = 0
	_smoke_walk(World.DRYER)
	assert(is_instance_valid(modal))
	var before_build: int = state.money
	_build_dryer()
	assert(state.rack_built and state.money == before_build - 60)
	_start_processing("dried_turnip", 3)
	assert(state.produce["turnip"] == 0 and not state.processing_ready())
	var at_menu: float = state.minute
	_process(15)
	assert(state.minute == at_menu and not state.processing_ready(), "Processing menu pauses without accelerating batch")
	_close_modal()
	_save(false)
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.BED)
	_sleep()
	assert(state.processing_ready() and state.area_id == "house")
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	_smoke_walk(World.DRYER)
	_collect_processing()
	assert(state.goods["dried_turnip"] == 3 and state.processing_job.is_empty())
	_close_modal()
	_show_bag()
	var card: Panel = modal.get_child(1)
	for child in card.get_children():
		if child is Button and child.text in ["採集素材", "成品雞蛋", "魚獲", "料理"]:
			assert(child.size.y >= 44, "Bag submenus need usable touch height")
	_show_goods()
	assert(is_instance_valid(modal))
	_close_modal()
	var before_sale: int = state.money
	_smoke_walk(World.BOX)
	assert(state.money == before_sale + 84 and state.goods["dried_turnip"] == 0)
	_save(false)
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded), "Sold goods and completed build persist")

func _smoke_request_layout() -> void:
	var card: Panel = modal.get_child(1)
	for child in card.get_children():
		if child is Label and child.autowrap_mode != TextServer.AUTOWRAP_OFF:
			assert(child.position.x + child.size.x <= 454 and child.position.y + child.size.y <= card.size.y-68, "Narrative text must fit above buttons: " + str(child.position) + " / " + str(child.size))

func _smoke_requests() -> void:
	# Fresh session covers an accepted commission held across a real farming day.
	state = State.new()
	_mount_area()
	travel_lock = 0
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.NOTICE)
	_smoke_request_layout()
	_accept_request()
	assert(state.active_request == "tea_vegetables")
	_close_modal()
	_smoke_walk(AreaWorld.QINGHE_POS)
	assert(is_instance_valid(modal) and not state.can_deliver_request("npc"))
	_smoke_request_layout()
	_close_modal()
	_smoke_walk(AreaWorld.FARM_EXIT)
	travel_lock = 0
	_select_tool(2)
	for plot in [0, 1]:
		_smoke_walk(world.plot_center(plot))
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.BED)
	_sleep()
	assert(state.active_request == "tea_vegetables" and state.day == 2)
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	_select_tool(3)
	for plot in [0, 1]:
		_smoke_walk(world.plot_center(plot))
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.QINGHE_POS)
	_resident_normal("npc")
	assert(state.friendship == 1)
	_close_modal()
	_smoke_walk(AreaWorld.QINGHE_POS)
	var before_delivery: int = state.money
	_deliver_request("npc")
	assert(state.money == before_delivery + 50 and state.produce["turnip"] == 0 and state.friendship == 2)
	assert(state.requests_completed == 1 and state.active_request == "")
	_close_modal()
	_smoke_walk(AreaWorld.NOTICE)
	_accept_request()
	assert(state.active_request == "", "Daily completion prevents another acceptance")
	_close_modal()
	state.minute = 1319.99
	_process(0.1)
	assert(state.day == 3)
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.QINGHE_POS)
	assert(state.friendship == 3 and state.tea_event_available())
	_show_tea_event(0, false)
	_smoke_request_layout()
	_close_modal()
	assert(not state.tea_event_seen and state.materials["herb"] == 0, "Closing unfinished story gives no reward")
	for page in range(3):
		_show_tea_event(page, false)
		_smoke_request_layout()
	_finish_tea_event()
	assert(state.tea_event_seen and state.materials["herb"] == 2 and state.friendship == 4)
	_save(false)
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))
	_smoke_walk(AreaWorld.FARM_EXIT)
	travel_lock = 0
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.JOURNAL)
	_smoke_request_layout()
	var before_replay: Dictionary = state.to_data()
	for page in range(3):
		_show_tea_event(page, true)
		_smoke_request_layout()
	_close_modal()
	assert(state.to_data() == before_replay, "Journal story replay changes no rewards or progress")

func _smoke_livestock() -> void:
	# Stage construction stock; grow the hen's feed through the actual crop cycle.
	state = State.new()
	state.money = 300
	state.materials = {"wood": 8, "stone": 6, "herb": 0}
	_mount_area()
	travel_lock = 0
	_smoke_walk(World.COOP)
	_smoke_request_layout()
	_build_coop()
	_buy_chicken()
	assert(state.coop_built and state.chickens == 1 and state.money == 120)
	_feed_chickens()
	assert(state.fed_chickens == 0 and state.seeds["wheat"] == 5, "Wheat seeds are not feed")
	_close_modal()
	selected_crop = "wheat"
	_select_tool(0)
	_smoke_walk(world.plot_center(3))
	_select_tool(1)
	_smoke_walk(world.plot_center(3))
	for day_index in range(3):
		_select_tool(2)
		_smoke_walk(world.plot_center(3))
		_smoke_walk(World.HOUSE - Vector2(0, 12))
		travel_lock = 0
		_smoke_walk(AreaWorld.BED)
		_sleep()
		travel_lock = 0
		_smoke_walk(AreaWorld.HOUSE_EXIT)
		travel_lock = 0
	assert(state.day == 4 and state.chickens == 1 and state.nest_eggs == 0, "Unfed hen survives while feed grows")
	_select_tool(3)
	_smoke_walk(world.plot_center(3))
	assert(state.produce["wheat"] == 1)
	_smoke_walk(World.COOP)
	_feed_chickens()
	assert(state.fed_chickens == 1 and state.produce["wheat"] == 0)
	_feed_chickens()
	assert(state.fed_chickens == 1 and state.produce["wheat"] == 0)
	_close_modal()
	_save(false)
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.BED)
	_sleep()
	assert(state.nest_eggs == 1 and state.fed_chickens == 0)
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	_smoke_walk(World.COOP)
	_collect_eggs()
	assert(state.eggs == 1 and state.nest_eggs == 0)
	_close_modal()
	_show_goods()
	_smoke_request_layout()
	_close_modal()
	var cash: int = state.money
	_smoke_walk(World.BOX)
	assert(state.money == cash + 56 and state.eggs == 0 and state.chickens == 1)
	_save(false)
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))

func _smoke_exploration() -> void:
	# Stage prior commission history and building supplies; exercise all gate actions.
	state = State.new()
	state.day = 3
	state.money = 200
	state.materials = {"wood": 6, "stone": 4, "herb": 0}
	state.requests_completed = 1
	state.request_completed_day = 2
	_mount_area()
	travel_lock = 0
	_change_area("ruins")
	assert(state.area_id == "farm" and not state.route_restored, "Direct travel cannot bypass locked road")
	_smoke_request_layout()
	_close_modal()
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.FOREST_GATE)
	travel_lock = 0
	_smoke_walk(ForestWorld.ROUTE)
	_smoke_request_layout()
	var locked: Dictionary = state.to_data()
	_restore_route()
	assert(state.to_data() == locked, "Unqualified construction changes no resources")
	state.requests_completed = 2
	_restore_route()
	assert(state.route_restored and state.money == 40 and state.materials["wood"] == 0 and state.materials["stone"] == 0)
	_smoke_request_layout()
	_enter_ruins()
	assert(state.area_id == "ruins")
	travel_lock = 0
	_save(false)
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded), "Ruins position survives reload")
	var before_plots: Array = state.plots.duplicate(true)
	_smoke_work(0)
	assert(state.plots == before_plots and _target_plot() == -1)
	_smoke_walk(RuinsWorld.INSCRIPTION)
	_smoke_request_layout()
	_close_modal()
	_smoke_walk(RuinsWorld.RELIC)
	_smoke_request_layout()
	_close_modal()
	assert(not state.relic_recovered, "Interrupted discovery gives no reward")
	var seeds_before: Dictionary = state.seeds.duplicate()
	for page in range(2):
		_show_relic(page)
		_smoke_request_layout()
	_recover_relic()
	assert(state.relic_recovered and state.money == 160)
	for crop in State.CROP_ORDER:
		assert(state.seeds[crop] == seeds_before[crop] + 3)
	var reward_money: int = state.money
	_smoke_walk(RuinsWorld.RELIC)
	_smoke_request_layout()
	assert(state.money == reward_money)
	_close_modal()
	_smoke_walk(RuinsWorld.EXIT)
	assert(state.area_id == "forest" and state.player_position.distance_to(ForestWorld.ROUTE) > 21)
	travel_lock = 0
	_smoke_walk(ForestWorld.ROUTE)
	assert(state.area_id == "ruins")
	travel_lock = 0
	state.minute = 1319.99
	_process(0.1)
	assert(state.area_id == "house" and state.day == 4 and state.route_restored and state.relic_recovered)
	travel_lock = 0
	_show_journal()
	_smoke_request_layout()
	_show_route()
	_smoke_request_layout()
	_close_modal()
	_save(false)
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))

func _smoke_fishing() -> void:
	# Supplies and an open ruin road are fixtures; all casting uses real callbacks.
	state = State.new()
	state.materials = {"wood": 4, "stone": 2, "herb": 0}
	state.route_restored = true
	_mount_area()
	travel_lock = 0
	_smoke_walk(World.FARM_FISHING)
	_smoke_request_layout()
	_craft_fishing_rod()
	assert(state.fishing_rod and state.money == 40)
	_smoke_request_layout()
	_begin_fishing()
	_reel_fishing()
	assert(state.energy == 98 and state.fish_caught_today == 0, "Early reel pays stamina but grants no fish")
	_close_modal()
	_show_fishing()
	_begin_fishing()
	_process(10)
	assert(fishing_round == null and state.energy == 96 and state.fish_caught_today == 0, "Missed bite times out")
	_close_modal()
	_show_fishing()
	_begin_fishing()
	_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(fishing_round == null and not state._fishing_pending and state.energy == 94, "Back cancels cast without refund")
	_show_fishing()
	_begin_fishing()
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and loaded.energy == 92 and not loaded._fishing_pending)
	assert(not loaded.finish_fishing(true)["ok"], "Saved pending cast never grants free fish")
	_notification(NOTIFICATION_APPLICATION_PAUSED)
	assert(fishing_round == null and not state._fishing_pending and is_instance_valid(modal), "Background cancels timed interaction and pauses")
	_process(20)
	assert(state.fish_caught_today == 0 and state.energy == 92)
	_notification(NOTIFICATION_APPLICATION_RESUMED)
	_close_modal()
	_show_fishing()
	_begin_fishing()
	var paused_minute: float = state.minute
	_process(State.FISHING.WAIT_SECONDS + 0.1)
	assert(fishing_round.is_biting() and state.minute == paused_minute)
	var reel: Button = fishing_reel
	assert(reel.size.y >= 64)
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.position = Vector2(40, 40)
	press.pressed = true
	reel._gui_input(press)
	press.pressed = false
	reel._gui_input(press)
	assert(state.fish["silver_carp"] == 1 and state.fish_caught_today == 1, "Touch-down reel catches exactly once")
	_close_modal()
	_smoke_walk(World.TOWN_GATE)
	travel_lock = 0
	_smoke_walk(AreaWorld.FOREST_GATE)
	travel_lock = 0
	_smoke_walk(ForestWorld.FOREST_FISHING)
	_begin_fishing()
	_process(State.FISHING.WAIT_SECONDS + 0.1)
	_reel_fishing()
	assert(state.fish["mist_trout"] == 1 and state.fish_caught_today == 2)
	_close_modal()
	_smoke_walk(ForestWorld.ROUTE)
	travel_lock = 0
	_smoke_walk(RuinsWorld.RUINS_FISHING)
	_begin_fishing()
	_process(State.FISHING.WAIT_SECONDS + 0.1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	_unhandled_input(key)
	assert(state.fish["star_perch"] == 1 and state.fish_caught_today == 3)
	_close_modal()
	var capped_energy: int = state.energy
	_show_fishing()
	_begin_fishing()
	assert(fishing_round == null and state.energy == capped_energy, "Daily cap blocks cost")
	_show_fish_bag()
	_smoke_request_layout()
	_close_modal()
	_save(false)
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))
	_sleep()
	assert(state.fish_caught_today == 0 and state.fish["star_perch"] == 1 and state.fishing_rod)
	travel_lock = 0
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	var money_before: int = state.money
	_smoke_walk(World.BOX)
	assert(state.money == money_before + 152 and state.fish.values().all(func(n): return n == 0))

func _smoke_cooking() -> void:
	# Harvests, one collected egg and one carp are fixtures, never finished meals.
	state = State.new()
	state.produce = {"turnip": 4, "wheat": 1, "berry": 1}
	state.materials["herb"] = 3
	state.eggs = 1
	state.fish["silver_carp"] = 1
	_mount_area()
	travel_lock = 0
	_smoke_walk(World.HOUSE - Vector2(0, 12))
	travel_lock = 0
	_smoke_walk(AreaWorld.HEARTH)
	_smoke_request_layout()
	var before: Dictionary = state.to_data()
	for i in range(State.COOKING.LEGACY.size()):
		_show_cookbook(i)
		_smoke_cooking_layout()
		assert(state.to_data() == before, "Reading a recipe never consumes ingredients")
	_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(not is_instance_valid(modal) and state.to_data() == before)
	_show_cookbook(0)
	_notification(NOTIFICATION_APPLICATION_PAUSED)
	_process(20)
	_notification(NOTIFICATION_APPLICATION_RESUMED)
	assert(state.to_data() == before, "Background cookbook does not cook or advance clock")
	for i in range(State.COOKING.LEGACY.size()):
		_cook_meal(State.COOKING.ORDER[i], i)
		assert(state.meals[State.COOKING.ORDER[i]] == 1)
		_smoke_cooking_layout()
	_cook_meal("turnip_soup", 0)
	assert(state.meals["turnip_soup"] == 2 and state.produce["turnip"] == 0 and state.eggs == 0 and state.fish["silver_carp"] == 0 and state.materials["herb"] == 0)
	var loaded = State.new()
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded), "Cooked meals persist before eating")
	before = state.to_data()
	_cook_meal("herb_fish", 2)
	assert(state.to_data() == before, "Failed second cook does not duplicate food")
	_close_modal()
	_smoke_walk(AreaWorld.HOUSE_EXIT)
	travel_lock = 0
	state.energy = 10
	_show_bag()
	var card: Panel = modal.get_child(1)
	var found := false
	for child in card.get_children():
		if child is Button and child.text == "料理":
			assert(child.size.x >= 100 and child.size.y >= 44)
			child.pressed.emit()
			found = true
	assert(found)
	_smoke_cooking_layout()
	card = modal.get_child(1)
	var eat: Button
	for child in card.get_children():
		if child is Button and child.text == "食用" and eat == null:
			eat = child
	assert(eat != null and not eat.disabled)
	var touch := InputEventScreenTouch.new()
	touch.index = 1
	touch.position = Vector2(20, 20)
	touch.pressed = true
	eat._gui_input(touch)
	touch.pressed = false
	eat._gui_input(touch)
	assert(state.energy == 45 and state.meals["turnip_soup"] == 1, "Touch eats exactly one portable serving")
	_eat_meal("egg_flatbread")
	assert(state.energy == 90 and state.meals["egg_flatbread"] == 0)
	_eat_meal("herb_fish")
	assert(state.energy == 100 and state.meals["herb_fish"] == 0)
	before = state.to_data()
	_eat_meal("turnip_soup")
	assert(state.to_data() == before, "Full stamina cannot waste a meal")
	_smoke_cooking_layout()
	_close_modal()
	var cash: int = state.money
	_smoke_walk(World.BOX)
	assert(state.money == cash + 48 and state.meals["turnip_soup"] == 1, "Shipping retains cooked food")
	_save(false)
	assert(loaded.load_game("user://smoke_session.json") and _smoke_saved_matches(loaded))
	_sleep()
	assert(state.meals["turnip_soup"] == 1)

func _smoke_cooking_layout() -> void:
	var card: Panel = modal.get_child(1)
	for child in card.get_children():
		if child is Button and child.text != "×":
			assert(child.position.x >= 28 and child.position.x + child.size.x <= 452 and child.size.y >= 44)
		if child is Label and child.position.y == 145:
			var h: float = child.get_theme_font("font").get_height(child.get_theme_font_size("font_size"))
			assert(child.position.y + child.get_line_count() * h <= 225, "Ingredients must fit above recipe buttons")

func _smoke_settle_work() -> void:
	while tool_action.active:
		_process(1.0 / 30.0)

func _smoke_work(index: int) -> void:
	_smoke_settle_work()
	_work(index)

func _smoke_walk(point: Vector2) -> void:
	_smoke_settle_work()
	_click_world(point)
	assert(not path.is_empty(), "Interactive objects must be reachable")
	var frames := 0
	while not path.is_empty() and frames < 900:
		_process(1.0 / 30.0)
		frames += 1
	assert(path.is_empty(), "Click-to-walk must finish")
