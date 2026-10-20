extends Node

const MUSIC = preload("res://assets/audio/cloudbridge_waltz.wav")
const GARDEN = preload("res://assets/audio/garden_ambience.wav")
const RAIN = preload("res://assets/audio/rain_ambience.wav")
const EFFECTS := {
	"hoe": preload("res://assets/audio/hoe.wav"),
	"seed": preload("res://assets/audio/seed.wav"),
	"water": preload("res://assets/audio/water.wav"),
	"harvest": preload("res://assets/audio/harvest.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"talk": preload("res://assets/audio/talk.wav"),
	"step": preload("res://assets/audio/step.wav"),
	"ui": preload("res://assets/audio/ui.wav"),
	"rest": preload("res://assets/audio/rest.wav"),
}
var preferences_path := "user://audio_preferences.cfg"
var volumes := {"music": 0.5, "effects": 0.75, "ambience": 0.5}
var pause_reasons: Dictionary = {}
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var rainy := false
var interior := false
var effects_enabled := true
var playback_enabled := true

func _ready() -> void:
	load_preferences()
	music = AudioStreamPlayer.new()
	music.stream = _loop_copy(MUSIC)
	add_child(music)
	ambience = AudioStreamPlayer.new()
	ambience.stream = _loop_copy(RAIN if rainy else GARDEN)
	add_child(ambience)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	if playback_enabled:
		music.play()
		ambience.play()
	_sync_players()

func _loop_copy(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	return stream

func set_weather(is_rainy: bool) -> void:
	if rainy == is_rainy:
		return
	rainy = is_rainy
	ambience.stop()
	ambience.stream = _loop_copy(RAIN if rainy else GARDEN)
	if playback_enabled:
		ambience.play()
	_sync_players()

func set_interior(value: bool) -> void:
	interior = value
	_sync_players()

func set_suspended(reason: String, suspended: bool) -> void:
	if suspended:
		pause_reasons[reason] = true
	else:
		pause_reasons.erase(reason)
	_sync_players()

func _sync_players() -> void:
	if not is_instance_valid(music):
		return
	music.volume_linear = volumes["music"] * 0.55
	ambience.volume_linear = volumes["ambience"] * (0.09 if interior else 0.5)
	music.stream_paused = not pause_reasons.is_empty() or volumes["music"] <= 0
	ambience.stream_paused = not pause_reasons.is_empty() or volumes["ambience"] <= 0
	for voice in voices:
		voice.volume_linear = volumes["effects"] * 0.6
		voice.stream_paused = not pause_reasons.is_empty()

func play_effect(effect: String, pitch: float = 1.0) -> void:
	if not playback_enabled or not effects_enabled or not pause_reasons.is_empty() or volumes["effects"] <= 0 or not EFFECTS.has(effect):
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = EFFECTS[effect]
	voice.pitch_scale = clampf(pitch, 0.85, 1.15)
	voice.play()

func set_volume(channel: String, value: float) -> void:
	if not volumes.has(channel) or not is_finite(value):
		return
	volumes[channel] = clampf(value, 0, 1)
	_sync_players()

func load_preferences() -> void:
	var file := ConfigFile.new()
	if file.load(preferences_path) != OK:
		return
	for channel in volumes:
		var value: Variant = file.get_value("audio", channel, volumes[channel])
		if (value is float or value is int) and is_finite(float(value)) and value >= 0 and value <= 1:
			volumes[channel] = float(value)

func save_preferences() -> Error:
	var file := ConfigFile.new()
	for channel in volumes:
		file.set_value("audio", channel, volumes[channel])
	var error := file.save(preferences_path + ".tmp")
	if error != OK:
		return error
	return DirAccess.rename_absolute(preferences_path + ".tmp", preferences_path)

func shutdown() -> void:
	for player in [music, ambience] + voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
