extends SceneTree

const RanchWorld = preload("res://scripts/ranch_world.gd")
const State = preload("res://scripts/farm_state.gd")
const Art = preload("res://scripts/approved_art.gd")
var passed := 0
var failed := 0
var game: Node

func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: ",message)

func _initialize() -> void:
	_run.call_deferred()

func layout(card: Control) -> bool:
	for child in card.get_children():
		if child is Button and (child.position.x<0 or child.position.y<0 or child.position.x+child.size.x>card.size.x+1 or child.position.y+child.size.y>card.size.y+1): return false
	return true

func card() -> Panel:
	return game.modal.get_child(1)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.audio_system.effects_enabled = false
	game.audio_system.playback_enabled = false
	game.simulation = true
	game.save_allowed = false
	game._close_modal()
	game.state = State.new()
	game._mount_area()
	check(game.stick.size==Vector2(148,148),"joystick control expanded to 148 square")
	game._click_world(Vector2(250,200))
	check(game.path.is_empty() if game.touch_mode else not game.path.is_empty(),"mobile blank-ground taps cannot cause unintended auto-walk")
	game._walk_to(Vector2(250,200),{})
	game.queued_click = Vector2(270,180)
	var press := InputEventScreenTouch.new()
	press.index = 4
	press.pressed = true
	press.position = game.stick.size/2
	game.stick._gui_input(press)
	check(game.path.is_empty() and game.pending.is_empty() and game.queued_click==null,"even center touch cancels old navigation and queued actions")
	if game.touch_mode:
		game._click_world(game.world.plot_center(0))
		check(game.path.is_empty() and game.queued_click==null,"right finger cannot steal movement while left thumb rests at stick center")
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = Vector2(500,-200)
	game.stick._gui_input(drag)
	check(game.stick.direction.length()>0.9,"active finger can drag outside joystick")
	var release := InputEventScreenTouch.new()
	release.index = 5
	release.pressed = false
	game.stick._input(release)
	check(game.stick.direction.length()>0,"second finger release does not interrupt active control")
	release.index = 4
	release.position = Vector2(1800,-500)
	game.stick._input(release)
	var start: Vector2 = game.state.player_position
	for n in range(30): game._process(1.0/60.0)
	check(game.stick.direction==Vector2.ZERO and game.stick.finger==-1 and game.state.player_position==start,"global release outside control stops movement permanently")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = Vector2(130,74)
	game.stick._gui_input(mouse)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = 0
	game.stick._input(motion)
	check(game.stick.direction==Vector2.ZERO and not game.stick.mouse_down,"lost mouse release cleared by button mask")
	game.stick._gui_input(press)
	game.stick._gui_input(drag)
	game.stick._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.stick.direction==Vector2.ZERO,"focus loss clears held touch")
	game.state.money = 5000
	game.state.materials = {"wood":50,"stone":50,"herb":10}
	for home in range(4):
		game.state.area_id = "farm"
		check(State.RANCH.build(game.state,home)["ok"],"build habitat via business rules")
		game._mount_area()
		game.travel_lock = 0
		game.ranch_panels.visit(home)
		check(game.state.area_id==State.RANCH_DATA.AREAS[home] and game.world is RanchWorld,"visit mounts the correct playable habitat")
		for key in game.world.interactions():
			game.path.clear()
			game._walk_to(game.world.interactions()[key],{})
			check(not game.path.is_empty(),"every animal resident board and exit is reachable")
		game.ranch_panels.home(home)
		check(layout(card()),"habitat menu buttons fit")
		for id in State.RANCH_DATA.ORDER:
			if State.RANCH_DATA.SPECIES[id]["home"]!=home: continue
			game.ranch_panels.animal(id)
			check(layout(card()),"unowned animal detail fits")
			game.ranch_panels.action(id,"buy")
			check(layout(card()),"owned animal detail fits")
			game.ranch_panels.rename(id)
			check(layout(card()),"name entry fits")
		for id in State.RANCH_DATA.VISITORS:
			if State.RANCH_DATA.RESIDENTS[id]["home"]==home:
				game.ranch_panels.visitor(id)
				check(layout(card()) and game.state.ranch["friends"][id]==1,"new residents have working dialogue and daily friendship")
	game.ranch_panels.hub()
	check(layout(card()),"ranch hub fits")
	game.ranch_panels.animal("carp")
	for child in card().get_children():
		if child is TextureRect:
			check(child.size.x<=100 and child.size.y<=100,"animal pictures retain intended size and cannot cover status text")
	for page in range(3):
		game.ranch_panels.products(page)
		check(layout(card()),"product inventory pagination fits")
	for style in ["male","female"]:
		for row in range(8):
			var image: Image = Art.hero_texture(style,row).get_image()
			for frame in range(8):
				var data := Art.hero_frame(style,row,frame)
				var rect := Art.region(data)
				check(rect.has_area() and Rect2(Vector2.ZERO,image.get_size()).encloses(rect),"all approved hero frames have valid distinct source bounds")
	game._set_style("female")
	check(game.state.hero_style=="female" and game.hero_preview.style=="female","female appearance selectable and previewed")
	game._close_modal()
	game.state.area_id = "farm"
	game._mount_area()
	game.world.set_process(false)
	game._process(0.05)
	check(game.state.hero_style=="female" and game.state._valid_data(game.state.to_data()),"female style and ranch survive normal world frame")
	game.free()
	print("RANCH SCENE TESTS: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
