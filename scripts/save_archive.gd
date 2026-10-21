extends RefCounted

const State = preload("res://scripts/farm_state.gd")
const MAX_BYTES := 262144
var directory := "user://archives"

func _init(folder: String = "user://archives") -> void:
	directory = folder

func slot_path(slot: int) -> String:
	return directory.path_join("checkpoint_%d.json" % slot)

func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot > 3: return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path).size() > MAX_BYTES: return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	var value: Variant = parser.data
	if not value is Dictionary or not State.new()._valid_data(value.get("data")): return {}
	var normalized := State.new()
	normalized._apply_data(value["data"])
	value["data"]=normalized.to_data()
	return value

func write_slot(slot: int, state: RefCounted) -> Error:
	if slot < 0 or slot > 3 or not state._valid_data(state.to_data()): return ERR_INVALID_DATA
	var ancestor := directory
	while ancestor != ancestor.get_base_dir():
		if FileAccess.file_exists(ancestor): return ERR_CANT_CREATE
		ancestor=ancestor.get_base_dir()
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return error
	var path := slot_path(slot)
	var file := FileAccess.open(path+".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"created":Time.get_datetime_string_from_system(),"data":state.to_data()}))
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK: return result
	return DirAccess.rename_absolute(path+".tmp",path)

func encode(state: RefCounted) -> String:
	var data: String = JSON.stringify(state.to_data())
	return "ARISE1:"+data.sha256_text()+":"+Marshalls.utf8_to_base64(data)

func decode(code: String) -> Dictionary:
	code=code.strip_edges()
	if code.length()>MAX_BYTES: return {}
	var parts := code.split(":",true,2)
	if parts.size()!=3 or parts[0]!="ARISE1" or parts[1].length()!=64: return {}
	var base64 := RegEx.new()
	base64.compile("^[A-Za-z0-9+/]*={0,2}$")
	if parts[2].length()%4!=0 or base64.search(parts[2])==null: return {}
	var raw := Marshalls.base64_to_utf8(parts[2])
	if raw.sha256_text()!=parts[1]: return {}
	var parser := JSON.new()
	if parser.parse(raw)!=OK or not State.new()._valid_data(parser.data): return {}
	var normalized := State.new()
	normalized._apply_data(parser.data)
	return normalized.to_data()

func restore(data: Dictionary, state: RefCounted, primary: String) -> Error:
	if not state._valid_data(data): return ERR_INVALID_DATA
	# Never replace the current session unless its independent rollback copy exists.
	var error := write_slot(0,state)
	if error != OK: return error
	var candidate := State.new()
	candidate._apply_data(data)
	error=candidate.save_game(primary)
	if error==OK: state._apply_data(candidate.to_data())
	return error
