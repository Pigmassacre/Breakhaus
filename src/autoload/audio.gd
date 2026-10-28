extends Node
## Sounds, from a small pool of players, and the music.
##
## A sound `name` is assets/audio/name.ogg, or name_1.ogg, name_2.ogg ... to
## pick from at random (tools/import_audio.py makes them). All of them are
## loaded as the game starts, so nothing is read off the disk mid-game.
##
## The music is a track in three layers (music_<track>_1 to _3: sparse to
## full, the same piece), played together and in step, crossfading from one
## to the next with `heat`, 0 to 1, which the game sets from how close the
## wall is and how big the combo is: calm, busier, everything.

const DIR := "res://assets/audio/"
const POOL := 20
const LAYERS := 3

const SOUNDS := "Sounds"
const MUSIC := "Music"

## How hot the music is, 0 to 1; it follows this smoothly.
var heat := 0.0
var _heat_now := 0.0
## The music's whole level, 0 to 1 (fades in and out on top of the Music bus's volume).
var _music_level := 0.0
var _music_target := 1.0
var _music_fade_speed := 1.0

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _layers: Array[AudioStreamPlayer] = []
var _old_layers: Array[AudioStreamPlayer] = []
var _track := ""
var _lowpass: AudioEffectLowPassFilter
var _muffle_tween: Tween
## Sounds already played this frame, to keep a burst of breaks from stacking up into a roar.
var _this_frame := {}
var _frame := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: String in [SOUNDS, MUSIC]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	# The music goes muffled under the pause menu and the game over.
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(MUSIC), _lowpass)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = SOUNDS
		add_child(p)
		_pool.append(p)
	for i in LAYERS * 2:
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC
		add_child(p)
		(_layers if i < LAYERS else _old_layers).append(p)
	_load_all()


func _load_all() -> void:
	var names := {}
	for file in ResourceLoader.list_directory(DIR):
		if file.get_extension() == "ogg" and not file.begins_with("music_"):
			var base := file.get_basename()
			var parts := base.rsplit("_", true, 1)
			if parts.size() == 2 and parts[1].is_valid_int():
				base = parts[0]
			names[base] = true
	for sound: String in names:
		var takes := []
		if ResourceLoader.exists(DIR + sound + ".ogg"):
			takes.append(load(DIR + sound + ".ogg"))
		for i in range(1, 16):
			if ResourceLoader.exists(DIR + "%s_%d.ogg" % [sound, i]):
				takes.append(load(DIR + "%s_%d.ogg" % [sound, i]))
		_streams[sound] = takes


## Plays a take of `sound`, `volume_db` up or down, at `pitch`.
func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var takes: Array = _streams.get(sound, [])
	if takes.is_empty():
		push_warning("No sound " + sound)
		return
	_play(takes[randi() % takes.size()], sound, volume_db, pitch)


## Plays take `index` (from 0) of `sound`, held at its last.
func play_take(sound: String, index: int, volume_db := 0.0, pitch := 1.0) -> void:
	var takes: Array = _streams.get(sound, [])
	if takes.is_empty():
		return
	_play(takes[clampi(index, 0, takes.size() - 1)], sound, volume_db, pitch)


func _play(stream: AudioStream, sound: String, volume_db: float, pitch: float) -> void:
	if Engine.get_process_frames() != _frame:
		_frame = Engine.get_process_frames()
		_this_frame.clear()
	var count: int = _this_frame.get(sound, 0)
	if count >= 2:
		return
	_this_frame[sound] = count + 1
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db - count * 4.0
	p.pitch_scale = pitch
	p.play()


func takes(sound: String) -> int:
	return (_streams.get(sound, []) as Array).size()


## Turns a bus ("Master", SOUNDS or MUSIC) to `amount` of full volume.
func set_volume(bus: String, amount: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.0001)))
	AudioServer.set_bus_mute(index, amount <= 0.001)


## Starts `track` (its layers together), fading over from whatever was on. The same track carries on.
func play_music(track: String, fade := 1.0) -> void:
	_music_target = 1.0
	_music_fade_speed = 1.0 / maxf(fade, 0.01)
	if track == _track and _layers[0].playing:
		return
	_track = track
	# The old track fades out on the spare players while the new one comes in.
	var spare := _old_layers
	_old_layers = _layers
	_layers = spare
	for p in _old_layers:
		var t := create_tween()
		t.tween_property(p, "volume_db", -60.0, fade)
		t.tween_callback(p.stop)
	for i in LAYERS:
		var stream := load(DIR + "music_%s_%d.ogg" % [track, i + 1]) as AudioStreamOggVorbis
		if stream == null:
			continue
		stream.loop = true
		_layers[i].stream = stream
		_layers[i].volume_db = -60.0
		_layers[i].play()
	_music_level = 0.0


func stop_music(fade := 1.0) -> void:
	_music_target = 0.0
	_music_fade_speed = 1.0 / maxf(fade, 0.01)


## Muffles the music (the pause menu, the game over), 0 clear to 1 under water.
func muffle(amount: float, seconds := 0.4) -> void:
	if _muffle_tween:
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.tween_property(_lowpass, "cutoff_hz", lerpf(20000.0, 500.0, amount), seconds) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_heat_now = move_toward(_heat_now, heat, delta * (0.6 if heat > _heat_now else 0.25))
	_music_level = move_toward(_music_level, _music_target, delta * _music_fade_speed)
	if _layers[0].stream == null:
		return
	# Each layer is the whole piece, so they crossfade (equal power) rather than pile up.
	var pos := _heat_now * (LAYERS - 1)
	for i in LAYERS:
		var level: float = cos(clampf(absf(pos - i), 0.0, 1.0) * PI * 0.5) * _music_level
		_layers[i].volume_db = linear_to_db(maxf(level, 0.0001))
	if _music_level <= 0.0 and _music_target <= 0.0:
		for p in _layers:
			p.stop()
		_track = ""
