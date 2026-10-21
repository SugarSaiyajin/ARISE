extends SceneTree
const State = preload("res://scripts/farm_state.gd")
const Archive = preload("res://scripts/save_archive.gd")
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	var archive := Archive.new("user://archive_tests")
	var state := State.new()
	state.money=321
	var original := state.to_data()
	var code := archive.encode(state)
	check(archive.decode(code)==original,"portable save roundtrips all business state")
	check(archive.decode(" \n"+code+"\n")==original,"surrounding whitespace accepted")
	for invalid in ["",code.left(code.length()-4),code.replace("ARISE1","ARISE2"),code+"bad","x".repeat(Archive.MAX_BYTES+1)]:
		check(archive.decode(invalid).is_empty(),"damaged, unsupported and oversized codes rejected")
	var bad := JSON.stringify({"version":1,"money":-2})
	check(archive.decode("ARISE1:"+bad.sha256_text()+":"+Marshalls.utf8_to_base64(bad)).is_empty(),"checksum alone cannot bypass schema validation")
	check(archive.write_slot(1,state)==OK,"independent checkpoint saved")
	state.money=456
	state.save_game("user://archive_primary.json")
	check(archive.read_slot(1)["data"]==original,"autosave leaves manual checkpoint intact")
	check(archive.restore(original,state,"user://archive_primary.json")==OK and state.money==321,"restore commits validated checkpoint")
	check(archive.read_slot(0)["data"]["money"]==456,"restore retains prior session for rollback")
	var loaded := State.new()
	check(loaded.load_game("user://archive_primary.json") and loaded.to_data()==state.to_data(),"restore survives restart")
	var rollback: Dictionary=archive.read_slot(0)["data"]
	check(archive.restore(rollback,state,"user://archive_primary.json")==OK and state.money==456,"rollback restores previous session")
	var before := state.to_data()
	check(archive.restore({},state,"user://archive_primary.json")!=OK and state.to_data()==before,"invalid restore never mutates live state")
	check(archive.restore(original,state,"user://missing_parent/archive.json")!=OK and state.to_data()==before,"unwritable destination preserves live state")
	var blocked := Archive.new("user://archive_primary.json/impossible")
	check(blocked.restore(original,state,"user://archive_primary.json")!=OK and state.to_data()==before,"failed rollback copy blocks destructive restore")
	var file := FileAccess.open(archive.slot_path(2),FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(archive.read_slot(2).is_empty(),"corrupt manual slot rejected without fallback to different slot")
	for slot in [-1,4]: check(archive.write_slot(slot,state)!=OK and archive.read_slot(slot).is_empty(),"out of range slots rejected")
	# Repeated in-game days exercise processing, feed caps and persistence without a wall-clock benchmark claim.
	for day in range(120):
		state.sleep()
		check(state.save_game("user://archive_soak.json")==OK,"long-session daily checkpoint")
		loaded=State.new()
		check(loaded.load_game("user://archive_soak.json") and loaded.to_data()==state.to_data(),"long-session restart fidelity")
	print("ARCHIVES: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
