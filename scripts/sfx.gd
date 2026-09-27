extends Node
## 효과음과 배경 음악. 파일은 assets/sfx, assets/music 에 있다 (출처는 CREDITS.md).

const SFX_DIR := "res://assets/sfx/"
const MUSIC_DIR := "res://assets/music/"
const VARIANTS := {
	"step_wood": ["step_wood1", "step_wood2", "step_wood3"],
	"step_grass": ["step_grass1", "step_grass2"],
	"step_stone": ["step_stone1", "step_stone2"],
	"step_heavy": ["step_heavy1", "step_heavy2"],
	"shutter": ["shutter1", "shutter2"],
	"creak": ["creak1", "creak2"],
}

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""
var _loops: Dictionary = {}     # name -> AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for bus in Game.volumes:
		set_volume(bus, Game.volumes[bus])


func set_volume(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, v <= 0.01)
	AudioServer.set_bus_volume_db(i, linear_to_db(max(v, 0.001)))


func _stream(name: String, dir := SFX_DIR) -> AudioStream:
	var key := dir + name
	if not _streams.has(key):
		var path := key + ".ogg"
		_streams[key] = load(path) if ResourceLoader.exists(path) else null
	return _streams[key]


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if VARIANTS.has(name):
		name = VARIANTS[name].pick_random()
	var s := _stream(name)
	if s == null:
		return
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _pool[0]
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.play()


## 거리(칸)에 따라 작아지는 소리. max_cells 밖이면 들리지 않는다.
func play_at(name: String, dist: float, max_cells := 12.0, volume_db := 0.0) -> void:
	if dist > max_cells:
		return
	play(name, volume_db - 26.0 * (dist / max_cells))


func music(name: String, fade := 0.8) -> void:
	if name == _music_name:
		return
	_music_name = name
	var tw := create_tween()
	if _music.playing:
		tw.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tw.tween_callback(func():
		if name == "":
			_music.stop()
			return
		var s := _stream(name, MUSIC_DIR)
		if s is AudioStreamOggVorbis:
			s.loop = true
		_music.stream = s
		_music.volume_db = -40.0
		_music.play())
	if name != "":
		tw.tween_property(_music, "volume_db", 0.0, fade * 0.5)


func loop(name: String, on: bool, volume_db := 0.0) -> void:
	if on:
		var p: AudioStreamPlayer = _loops.get(name)
		if p == null:
			p = AudioStreamPlayer.new()
			p.bus = "SFX"
			var s := _stream(name)
			if s is AudioStreamOggVorbis:
				s = s.duplicate()
				s.loop = true
			p.stream = s
			add_child(p)
			_loops[name] = p
		p.volume_db = volume_db
		if not p.playing:
			p.play()
	elif _loops.has(name):
		_loops[name].stop()


func stop_all_loops() -> void:
	for k in _loops:
		_loops[k].stop()
