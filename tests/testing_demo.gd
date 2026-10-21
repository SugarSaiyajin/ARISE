extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/testing-0.23-"+label+".png")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio_system.shutdown()
	game.save_allowed=false
	game.testing_panels.archive.directory="user://demo_archives"
	game.testing_panels.hub()
	await shot("backup")
	game.testing_panels.guide()
	await shot("guide")
	game.testing_panels.import_code()
	await shot("import")
	game.free()
	quit()
