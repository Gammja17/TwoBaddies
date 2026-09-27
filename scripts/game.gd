extends Node
## 한 판의 상태(시간, 주머니, 호감도, 관계, 플래그)와 저장되는 기록(본 엔딩, 설정).

signal changed
signal toast(text: String)

const SAVE_PATH := "user://save.cfg"
const ALARM_MIN := 2 * 60 + 10      # 02:10 경보
const POLICE_SECONDS := 20 * 60     # 02:30 경찰 도착
const TIME_SCALE := 1.5             # 게임 속 20분이 실제로는 약 13분
const FRIEND_LINE := 60             # 이 이상이면 '친밀'
const BETRAY_LINE := 30             # 이 밑이면 그가 배신할 수 있다

# --- 저장되는 것 ---
var endings: Dictionary = {}
var prologue_done := false
var volumes := {"Master": 0.9, "Music": 0.7, "SFX": 0.9}
var plays := 0

# --- 한 판 ---
var phase := "title"            # title, prologue, play, ended
var t := 0.0                    # 경보가 울린 뒤 흐른 초
var clock_on := false
var busy := 0                   # 대화, 메뉴가 열려 있으면 0보다 크다 (시간이 멈춘다)
var inventory: Array[String] = []
var loot: Dictionary = {}       # 훔친 것 -> 값 (만원)
var loot_split: Dictionary = {} # 곽두철과 반씩 나눈 것
var flags: Dictionary = {}
var notes: Array = []           # 수첩에 적은 단서 (적은 차례대로)
var affinity := 40
var met := false
var coop := false
var coop_ever := false
var hostile := false            # 플레이어가 그를 해쳤거나 속였다 (관계: 나쁨)
var crook_state := "free"       # free, stunned, asleep, tied, locked, dead, escaped
var kill_clean := false
var player_dead := false
var death_cause := ""
var escaped := false
var escaped_with_crook := false
var betrayed_by_him := false
var left_behind := false
var wrong_codes := 0
var keypad_locked_until := -1.0
var affinity_log: Array = []

# --- 자동 시험 (tools/sim.gd) ---
var test_mode := false
var test_choices: Array = []    # 선택지가 뜨면 앞에서부터 하나씩 고른다 (비면 0번)
var test_codes: Array = []      # 번호판에 넣을 번호
var test_lockpick := true       # 자물쇠 따기 성공 여부
var test_log: Array = []        # 대사 기록


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	load_save()


func _process(delta: float) -> void:
	if clock_on and busy == 0 and phase == "play" and not get_tree().paused:
		t += delta * TIME_SCALE


# ---------------------------------------------------------------- 한 판 ----

func new_run() -> void:
	t = 0.0
	clock_on = false
	busy = 0
	inventory = ["lockpick", "notebook"]
	loot = {}
	loot_split = {}
	flags = {}
	notes = []
	affinity = 40
	met = false
	coop = false
	coop_ever = false
	hostile = false
	crook_state = "free"
	kill_clean = false
	player_dead = false
	death_cause = ""
	escaped = false
	escaped_with_crook = false
	betrayed_by_him = false
	left_behind = false
	wrong_codes = 0
	keypad_locked_until = -1.0
	affinity_log = []
	plays += 1
	changed.emit()


func time_left() -> float:
	return max(0.0, POLICE_SECONDS - t)


func clock_text() -> String:
	var total := ALARM_MIN * 60 + int(t)
	return "%02d:%02d" % [total / 3600, (total / 60) % 60]


func minutes_left() -> int:
	return int(ceil(time_left() / 60.0))


func has(item: String) -> bool:
	return inventory.has(item)


func give(item: String) -> void:
	if not inventory.has(item):
		inventory.append(item)
	changed.emit()


func take(item: String) -> void:
	inventory.erase(item)
	changed.emit()


func flag(k: String) -> bool:
	return bool(flags.get(k, false))


func setf(k: String, v: Variant = true) -> void:
	flags[k] = v
	changed.emit()


func count(k: String) -> int:
	return int(flags.get(k, 0))


func bump(k: String, n := 1) -> int:
	flags[k] = int(flags.get(k, 0)) + n
	return flags[k]


func add_affinity(n: int, why := "") -> void:
	affinity = clampi(affinity + n, 0, 100)
	affinity_log.append([n, why])
	changed.emit()


func steal(id: String, value: int) -> void:
	loot[id] = value
	changed.emit()


func loot_total() -> int:
	var s := 0
	for k in loot:
		s += loot[k] / 2 if loot_split.has(k) else loot[k]
	return s


func stole() -> bool:
	return not loot.is_empty()


## 관계: friend, lukewarm, neutral, hostile
func relation() -> String:
	if hostile or left_behind:
		return "hostile"
	if coop_ever:
		return "friend" if affinity >= FRIEND_LINE else "lukewarm"
	return "neutral"


func relation_text() -> String:
	if not met:
		return "아직 모르는 사이"
	match relation():
		"friend":
			return "꽤 믿는 사이"
		"lukewarm":
			return "같이는 가지만 서먹한 사이" if affinity >= BETRAY_LINE else "언제 등 돌릴지 모르는 사이"
		"hostile":
			return "원수"
	return "남남"


# ---------------------------------------------------------------- 엔딩 ----

## 기획서의 엔딩 표를 그대로 옮기고, 표에 없던 칸(끝까지 남남, 그의 배신)을 채웠다.
func resolve_ending() -> String:
	if player_dead:
		return "slip" if death_cause == "slip" else "killed"
	if crook_state == "dead":
		if escaped:
			return "perfect" if kill_clean else "fugitive"
		return "murder"
	if betrayed_by_him:
		return "backstab"
	var rel := relation()
	if escaped:
		match rel:
			"friend":
				return "two_baddies" if stole() else "friend"
			"hostile":
				return "revenge_out"
			_:
				return "rich" if stole() else "tale"
	match rel:
		"friend":
			return "loyal" if stole() else "broke"
		"hostile":
			return "snitch" if stole() else "revenge_release"
		_:
			return "snitch" if stole() else "broke"


func record_ending(id: String) -> bool:
	var fresh := not endings.has(id)
	endings[id] = true
	save()
	return fresh


# ---------------------------------------------------------------- 저장 ----

func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for id in cfg.get_value("progress", "endings", []):
		endings[id] = true
	prologue_done = cfg.get_value("progress", "prologue_done", false)
	plays = cfg.get_value("progress", "plays", 0)
	for bus in volumes:
		volumes[bus] = cfg.get_value("volume", bus, volumes[bus])


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "endings", endings.keys())
	cfg.set_value("progress", "prologue_done", prologue_done)
	cfg.set_value("progress", "plays", plays)
	for bus in volumes:
		cfg.set_value("volume", bus, volumes[bus])
	cfg.save(SAVE_PATH)


# ---------------------------------------------------------------- 입력 ----

func _register_inputs() -> void:
	_add("up", [KEY_UP, KEY_W])
	_add("down", [KEY_DOWN, KEY_S])
	_add("left", [KEY_LEFT, KEY_A])
	_add("right", [KEY_RIGHT, KEY_D])
	_add("act", [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])
	_add("cancel", [KEY_X, KEY_BACKSPACE])
	_add("run", [KEY_SHIFT])
	_add("menu", [KEY_C, KEY_TAB, KEY_I])
	_add("pause", [KEY_ESCAPE, KEY_P])


func _add(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
