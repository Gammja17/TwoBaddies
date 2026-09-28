extends Node
## 한 판을 굴린다: 저택, 두 인물, 화면, 이야기(content.gd)를 잇고 시간 이벤트와 엔딩을 챙긴다.

signal finished(ending_id: String)

const PlayerScript := preload("res://scripts/player.gd")
const CrookScript := preload("res://scripts/crook.gd")
const ContentScript := preload("res://scripts/content.gd")

var world: World
var player: Actor
var crook: Actor
var content: RefCounted
var camera: Camera2D
var ui: CanvasLayer
var hud: Control
var dlg: Control
var pocket: Control
var memo: Control
var picker: Control
var keypad: Control
var touch: Node
var _running := false
var _room := -99
var _floor := ""
var _events: Dictionary = {}
var _ended := false
var _chasing := false


func setup(skip_prologue: bool) -> void:
	world = World.new()
	add_child(world)
	player = PlayerScript.new()
	player.play = self
	player.setup(world, "thief", world.world_cell("1F", 4, 20), Vector2i.UP)
	camera = Camera2D.new()
	player.add_child(camera)
	camera.position = Vector2(0, -16)
	crook = CrookScript.new()
	crook.play = self
	crook.setup(world, "crook", world.world_cell("2F", 3, 15), Vector2i.DOWN)
	crook.caught_player.connect(_on_caught)
	crook.active = false
	crook.visible = false
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = preload("res://scripts/hud.gd").new()
	ui.add_child(hud)
	dlg = preload("res://scripts/dialogue.gd").new()
	ui.add_child(dlg)
	pocket = preload("res://scripts/pocket.gd").new()
	ui.add_child(pocket)
	memo = preload("res://scripts/memo.gd").new()
	ui.add_child(memo)
	hud.memo_pressed.connect(open_memo)
	picker = preload("res://scripts/lockpick.gd").new()
	ui.add_child(picker)
	picker.slipped.connect(func(): noise_at(player.cell, 6.0))
	keypad = preload("res://scripts/keypad.gd").new()
	ui.add_child(keypad)
	touch = preload("res://scripts/touch.gd").new()
	ui.add_child(touch)
	content = ContentScript.new(self)
	Game.new_run()
	_update_room()
	if skip_prologue:
		run(content.skip_to_alarm)
	else:
		Game.phase = "prologue"
		run(content.prologue_intro)


# ---------------------------------------------------------------- 대본 돌리기 ----

## 대화나 사건 하나를 돌린다. 도는 동안 시간과 두 인물이 멈춘다.
func run(script: Callable) -> void:
	if _running or _ended:
		return
	_running = true
	Game.busy += 1
	player.control = false
	await script.call()
	if is_instance_valid(dlg):
		dlg.close()
	if not _ended:
		# 닫을 때 누른 Z가 곧바로 새 조사로 이어지지 않게 두 프레임 쉰다
		await get_tree().physics_frame
		await get_tree().physics_frame
	Game.busy = max(0, Game.busy - 1)
	player.control = true
	_running = false


func say(who: String, text: String, expr := "normal") -> void:
	if who == "crook" and not Game.flag("crook_named"):
		who = "crook_unknown"
	await dlg.say(who, text, expr)


func narr(text: String) -> void:
	await dlg.say("narr", text)


func choose(options: Array, disabled: Array = []) -> int:
	return await dlg.choose(options, disabled)


func toast(text: String, color := UI.TEXT) -> void:
	hud.toast(text, color)


## 시간이 흐르는 일 (그동안 곽두철도 움직인다). 진행 막대를 보여 준다.
func work(secs: float, label: String) -> bool:
	dlg.close()
	Game.flags.erase("_interrupt")
	hud.work_begin(label)
	Game.busy = max(0, Game.busy - 1)
	var t := 0.0
	var ok := true
	while t < secs:
		await get_tree().process_frame
		if _ended:
			ok = false
			break
		if Game.busy == 0:
			t += get_process_delta_time()
		hud.work_progress(t / secs)
		if Game.flag("_interrupt"):
			Game.flags.erase("_interrupt")
			ok = false
			break
	hud.work_end()
	Game.busy += 1
	return ok


func lockpick(title: String, difficulty: int, tutorial := false) -> bool:
	dlg.close()
	Game.busy = max(0, Game.busy - 1)
	var ok: bool = await picker.open(title, difficulty, tutorial)
	Game.busy += 1
	return ok


func enter_code(title: String, digits: int) -> String:
	dlg.close()
	return await keypad.open(title, digits)


func open_pocket() -> void:
	if _running:
		return
	run(func():
		Sfx.play("ui_open", -6.0)
		var r: Dictionary = await pocket.open()
		if not r.is_empty():
			await content.use_item(r["item"], r["action"])
		else:
			content.pocket_closed())


## 주운 메모장을 펼친다 (적는 동안 시간이 멈춘다)
func open_memo() -> void:
	if _running or not Game.has("notepad"):
		return
	run(func():
		Sfx.play("page")
		await memo.open())


func fade(a: float, secs := 0.4) -> void:
	await hud.fade_to(a, secs)


# ---------------------------------------------------------------- 조작 ----

func interact() -> void:
	if _running:
		return
	if player.hidden_in != "":
		run(content.leave_hiding)
		return
	var target := player.front()
	if crook.active and crook.cell == target and crook.mode != "gone":
		run(content.talk_crook)
		return
	var best: World.Prop = null
	var best_rank := -1
	for p in world.objects_at(target):
		var rank: int = content.rank(p)
		if rank > best_rank:
			best = p
			best_rank = rank
	if best != null and best_rank > 0:
		run(content.interact.bind(best))


func bumped(_c: Vector2i) -> void:
	pass


func player_stepped(c: Vector2i, running: bool) -> void:
	if running and Game.phase == "play":
		noise_at(c, 7.0)
	var st: Array = world.stairs_at(c)
	if st.size() > 0:
		run(content.use_stairs.bind(c, st))
		return
	_update_room()
	content.on_step(c)


func noise_at(c: Vector2i, loud: float) -> void:
	if crook.active:
		crook.hear(c, loud)


func _update_room() -> void:
	world.update_fog(player.cell)
	var f := world.floor_of(player.cell)
	if f != _floor:
		_floor = f
		var r: Rect2 = world.floor_rect_px(f)
		camera.limit_left = int(r.position.x)
		camera.limit_top = int(r.position.y)
		camera.limit_right = int(r.end.x)
		camera.limit_bottom = int(r.end.y) + 80
	var rooms := world.rooms_touching(player.cell)
	if rooms.size() == 1 and rooms[0] != _room:
		_room = rooms[0]
		hud.show_room(world.name_of_room(_room))
		content.on_enter_room(world.name_of_room(_room))


func teleport_player(c: Vector2i, face: Vector2i) -> void:
	player.place(c, face)
	_update_room()
	world.update_fog(player.cell, true)


# ---------------------------------------------------------------- 곽두철 쪽 신호 ----

func crook_reaches_player() -> void:
	run(content.crook_approaches)


func crook_changed_floor() -> void:
	pass


func crook_woke(was: String) -> void:
	run(content.crook_woke.bind(was))


func crook_escapes_alone() -> void:
	run(content.crook_escapes_alone)


func chase_started() -> void:
	if not _chasing:
		_chasing = true
		Sfx.music("chase", 0.4)


func chase_ended() -> void:
	if _chasing:
		_chasing = false
		Sfx.music(_calm_music(), 1.2)


## 평소 음악: 사이렌이 들리기 시작하면 더 급한 곡으로
func _calm_music() -> String:
	return "tension" if Game.t >= 15 * 60 else "sneak"


func found_hiding(spot: String) -> void:
	run(content.found_hiding.bind(spot))


func _on_caught() -> void:
	if _running:
		# 뭔가 하는 중이었다면 그 일을 끊는다 (끝나면 곧바로 붙잡힌다)
		Game.flags["_interrupt"] = true
		return
	run(content.caught)


# ---------------------------------------------------------------- 시간 ----

func _process(_delta: float) -> void:
	if Game.phase != "play" or _ended:
		return
	var t := Game.t
	_at(15 * 60, "siren_far", func():
		Sfx.loop("siren", true, -30.0)
		if not _chasing:
			Sfx.music(_calm_music(), 2.0))
	_at(17 * 60, "siren_mid", func():
		Sfx.loop("siren", true, -20.0)
		if Game.busy == 0 and not _running:
			run(content.siren_near))
	_at(19 * 60, "siren_close", func(): Sfx.loop("siren", true, -10.0))
	if t >= Game.POLICE_SECONDS and not _ended and not _running:
		run(content.police_arrive)


func _at(secs: float, key: String, f: Callable) -> void:
	if Game.t >= secs and not _events.has(key):
		_events[key] = true
		f.call()


# ---------------------------------------------------------------- 끝 ----

func end_game() -> void:
	if _ended:
		return
	_ended = true
	Game.phase = "ended"
	Game.clock_on = false
	Sfx.stop_all_loops()
	var id: String = Game.resolve_ending()
	finished.emit(id)
