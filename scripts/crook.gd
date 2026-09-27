extends Actor
## 곽두철. 혼자 탈출 계획을 밀고 나가다가, 도둑을 보면 다가와 말을 걸고,
## 같이 가기로 하면 따라다니고, 적이 되면 쫓아온다.
##
## 상태
##   agenda   : 자기 계획대로 움직인다 (침입자 찾기, 식칼, 쇠지렛대, 공구함 뜯기, 잭으로 석탄 구멍)
##   approach : 도둑을 봤다. 다가가서 말을 건다
##   follow   : 같이 간다. 도둑 뒤를 따른다
##   wait     : 같이 가는 중인데 기다려 달라고 했다
##   hunt     : 적. 도둑을 찾아 돌아다닌다
##   chase    : 적. 도둑을 보고 쫓는다
##   search   : 적. 놓친 자리 근처의 숨을 곳을 뒤진다
##   down     : 기절, 잠, 묶임, 갇힘, 죽음 (Game.crook_state 로 구분)
##   gone     : 혼자 빠져나갔다

signal caught_player

const WALK := 0.32
const HURRY := 0.22
const CHASE := 0.15
const SIGHT := 8
const NOWHERE := Vector2i(-999, -999)

## 침입자를 찾는 동안 들르는 곳 (층, x, y)
const SEARCH_ROUTE := [["2F", 12, 6], ["2F", 25, 8], ["2F", 20, 15], ["1F", 26, 15], ["1F", 30, 4],
		["1F", 18, 6], ["1F", 12, 16], ["1F", 40, 10], ["1F", 26, 17]]
## 혼자 나갈 계획의 단계
const STEPS := ["search", "track", "console", "massage", "knife", "crowbar", "cabinet", "bag", "chute", "roam"]
const TRACK_SECS := 70.0   # 수색이 끝나도 못 만났으면 발소리를 쫓아 도둑 쪽으로 가는 시간
const CODE_TRIES := ["010101", "123456", "000000"]

var play: Node
var mode := "agenda"
var goal_index := 0
var carrying: Array[String] = []   # 곽두철이 챙긴 것 (knife, crowbar, jack)
var greeted := false               # 처음 만남 대화를 했는지
var catches := 0
var target_cell := NOWHERE
var _path: Array[Vector2i] = []
var _wait := 0.0
var _work := 0.0
var _work_id := ""
var _clang := 0.0
var _last_seen := Vector2i.ZERO
var _lost := 0.0
var _search_left: Array = []
var _searching := false
var _repath := 0.0
var _down_left := 0.0
var _investigate := NOWHERE
var _stuck := 0.0
var _search_rooms: Array = []
var _roam_wait := 0.0
var _track_left := TRACK_SECS


func _ready() -> void:
	arrived.connect(_on_step)


func start() -> void:
	mode = "agenda"
	goal_index = 0
	_wait = 30.0  # 경보에 놀라 손님방에서 한동안 숨죽이고 있다가 나온다
	_search_rooms = SEARCH_ROUTE.duplicate()


func step_name() -> String:
	return STEPS[clampi(goal_index, 0, STEPS.size() - 1)]


func _physics_process(delta: float) -> void:
	if not active or Game.phase != "play" or Game.busy > 0:
		return
	match mode:
		"down":
			_tick_down(delta)
		"agenda":
			_tick_agenda(delta)
		"approach":
			_tick_approach()
		"follow":
			_tick_follow()
		"errand":
			if _go(target_cell, HURRY):
				mode = "wait"
				face(Vector2i.UP)
		"hunt":
			_tick_hunt(delta)
		"chase":
			_tick_chase(delta)
		"search":
			_tick_search(delta)
	_update_visibility()


func _update_visibility() -> void:
	visible = hidden_in == "" and active and mode != "gone" and world.cell_lit(cell)


# ---------------------------------------------------------------- 이동 ----

## 목표로 한 칸 걷는다. 이미 목표에 있으면 true.
## 목표 칸이 가구로 막혀 있으면 그 옆 빈칸을 목표로 삼는다.
func _go(to: Vector2i, speed: float) -> bool:
	if moving:
		return false
	if world.blocked_by_object(to) or not world.terrain_walkable(to):
		to = _adjacent_to(to)
	if cell == to:
		return true
	_repath -= get_physics_process_delta_time()
	if _path.is_empty() or _path.back() != to or _repath <= 0.0:
		_path = world.path(cell, to)
		_repath = 1.0
		if _path.size() > 0 and _path[0] == cell:
			_path.remove_at(0)
	if _path.is_empty():
		return false
	var nxt: Vector2i = _path[0]
	if abs(nxt.x - cell.x) + abs(nxt.y - cell.y) > 1:
		# 계단: 다른 층으로 순간 이동 (지하 계단에 덫이 있으면 여기서 끝난다)
		_path.remove_at(0)
		if play.content.crook_takes_stairs(cell):
			return false
		var st: Array = world.stairs_at(cell)
		place(st[1] if st.size() > 0 else nxt, st[2] if st.size() > 0 else facing)
		play.crook_changed_floor()
		return cell == to
	step_time = speed
	if world.passable(nxt, self):
		_stuck = 0.0
		_path.remove_at(0)
		walk_to(nxt)
		return false
	# 도둑이 길을 막고 있으면 잠깐 기다렸다가 길을 다시 찾는다
	_stuck += get_physics_process_delta_time()
	face(nxt - cell)
	if _stuck > 1.2:
		_path = []
		_stuck = 0.0
	return false


func _on_step(c: Vector2i) -> void:
	var loud := -6.0 if step_time <= CHASE else -13.0
	Sfx.play_at("step_heavy" if world.char_at(c) != "_" else "step_stone", _player_dist(), 12.0, loud)


func _player_dist() -> float:
	var p: Actor = play.player
	if world.floor_of(p.cell) != world.floor_of(cell):
		return 999.0
	return Vector2(p.cell - cell).length()


func _adjacent_to(c: Vector2i) -> Vector2i:
	var best := c
	var bd := 1e9
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var n: Vector2i = c + d
		if world.terrain_walkable(n) and not world.blocked_by_object(n):
			var dist := Vector2(n - cell).length()
			if dist < bd:
				bd = dist
				best = n
	return best


# ---------------------------------------------------------------- 보고 듣기 ----

func can_see_player() -> bool:
	var p: Actor = play.player
	if not p.active or p.hidden_in != "":
		return false
	if world.floor_of(p.cell) != world.floor_of(cell):
		return false
	var d := p.cell - cell
	var dist := Vector2(d).length()
	if dist <= 1.5:
		return true
	if dist > SIGHT:
		return false
	var shared := false
	var his := world.rooms_touching(p.cell)
	for r in world.rooms_touching(cell):
		if his.has(r):
			shared = true
	if not shared:
		return false
	# 등 뒤는 못 본다
	if Vector2(facing).dot(Vector2(d).normalized()) < -0.2:
		return false
	return world.line_clear(cell, p.cell)


## 도둑이 뛰거나 자물쇠를 헛따면 소리가 난다. loud: 들리는 거리(칸)
func hear(at: Vector2i, loud: float) -> void:
	if mode in ["down", "gone", "follow", "wait", "approach", "chase"]:
		return
	if world.floor_of(at) != world.floor_of(cell) or Vector2(at - cell).length() > loud:
		return
	if mode == "hunt" or mode == "search":
		_last_seen = at
		mode = "search"
		_searching = false
		bark("무슨 소리야?")
	elif mode == "agenda" and _work <= 0.0 and not greeted:
		_investigate = at
		bark("...누구야?")


# ---------------------------------------------------------------- 자기 계획 ----

func _tick_agenda(real_delta: float) -> void:
	var delta := real_delta * Game.TIME_SCALE   # 곽두철 계획도 시계 기준으로 흐른다
	if can_see_player():
		if not greeted or (step_name() == "roam" and play.content.wants_to_talk()):
			mode = "approach"
			if not greeted:
				Sfx.play("jingle_hit", -4.0)
				bark("야! 거기 너!")
			else:
				bark("야, 도둑! 이리 와 봐.")
			return
	if step_name() == "track":
		_track_left -= delta   # 기다리는 동안에도 줄어든다
	if _investigate != NOWHERE:
		if _go(_investigate, HURRY):
			_investigate = NOWHERE
			_wait = 2.5
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if _work > 0.0:
		_work -= delta
		_clang -= delta
		if _clang <= 0.0:
			_clang = 0.8
			if _work_id == "cabinet":
				Sfx.play_at("metal", _player_dist(), 14.0, -4.0)
			elif _work_id == "console" and fmod(_work, 12.0) < 0.8:
				Sfx.play_at("buzz", _player_dist(), 10.0, -6.0)
				bark(CODE_TRIES[int(_work / 12.0) % CODE_TRIES.size()] + "... 아니네.", 1.6)
		if _work <= 0.0:
			_finish_work()
		return
	var g := _current_goal()
	if g.is_empty():
		return
	if _go(g["cell"], WALK if g.get("slow", false) else HURRY):
		if g.has("face"):
			face(g["face"])
		_arrive_goal(g)


## 계획의 다음 단계. 이미 끝났거나 할 수 없는 단계는 건너뛴다.
func _current_goal() -> Dictionary:
	while goal_index < STEPS.size():
		match step_name():
			"search":
				if _search_rooms.is_empty() or greeted:
					goal_index += 1
					continue
				var r: Array = _search_rooms[0]
				return {"cell": world.world_cell(r[0], r[1], r[2]), "slow": true, "id": "search"}
			"track":
				# 이미 만났거나 70초가 지나면 자기 계획으로 돌아간다. 숨어 있으면 못 찾는다.
				if greeted or _track_left <= 0.0:
					goal_index += 1
					continue
				if _track_left >= TRACK_SECS:
					bark("발소리가 났는데... 이쪽인가?", 2.5)
				return {"cell": play.player.cell, "id": "track"}
			"console":
				if Game.flag("front_open") or Game.flag("crook_tried_code"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("1F", 30, 18), "face": Vector2i.DOWN, "id": "console"}
			"massage":
				if Game.flag("crook_rested"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("1F", 44, 14), "face": Vector2i.UP, "id": "massage"}
			"knife":
				if Game.flag("knife_taken"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("1F", 19, 4), "face": Vector2i.UP, "id": "knife"}
			"crowbar":
				if Game.flag("crowbar_taken"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("B1", 5, 8), "face": Vector2i.DOWN, "id": "crowbar"}
			"cabinet":
				if Game.flag("cabinet_open") or not carrying.has("crowbar"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("B1", 3, 4), "face": Vector2i.UP, "id": "cabinet"}
			"bag":
				# 잭을 구했으면 나가기 전에 딸 사진이 든 가방부터 챙긴다
				if not carrying.has("jack") or not play.world.objects.has("crook_bag"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("2F", 9, 14), "face": Vector2i.UP, "id": "bag"}
			"chute":
				if not carrying.has("jack"):
					goal_index += 1
					continue
				return {"cell": world.world_cell("B1", 11, 3), "face": Vector2i.UP, "id": "chute"}
			"roam":
				return {"cell": _roam_cell(), "id": "roam"}
	return {}


func _roam_cell() -> Vector2i:
	if target_cell == NOWHERE or cell == target_cell or _roam_wait <= 0.0:
		var rooms := []
		for r in world.room_cells:
			if world.name_of_room(r) not in ["뒷마당", ""]:
				rooms.append(r)
		var cells: Array = world.room_cells[rooms.pick_random()]
		target_cell = cells.pick_random()
		for _i in 10:
			if not world.blocked_by_object(target_cell):
				break
			target_cell = cells.pick_random()
		_roam_wait = 25.0
	_roam_wait -= get_physics_process_delta_time() * Game.TIME_SCALE
	return target_cell


func _arrive_goal(g: Dictionary) -> void:
	match g["id"]:
		"search":
			_search_rooms.pop_front()
			_wait = 7.0
			bark(["어디 숨었어?", "나와라, 좋은 말로 할 때.", "누가 들어온 거야...", "옷장 속인가?"].pick_random())
		"track":
			# 소리 난 자리까지 왔는데 아무도 없다 (숨어 있었다)
			_wait = 2.0
			bark("분명 이쪽에서 소리가 났는데...", 2.0)
		"console":
			_work = 40.0
			_work_id = "console"
			bark("비밀번호... 노인네들 생일인가?")
		"massage":
			# 안마의자에 앉아 머리를 식힌다
			place(world.world_cell("1F", 44, 13), Vector2i.DOWN)
			_work = 55.0
			_work_id = "massage"
			bark("머리가 안 돌아가. 안마 좀 받고 생각하자.", 3.0)
		"bag":
			play.world.remove_prop("crook_bag")
			Game.setf("crook_took_bag")
			goal_index += 1
			_wait = 2.0
			bark("이건 두고 못 가지.")
		"knife":
			if not Game.flag("knife_taken"):
				Game.setf("knife_taken")
				carrying.append("knife")
				play.content.knife_gone()
				Sfx.play_at("knife", _player_dist())
				bark("이거라도 있어야지.")
			goal_index += 1
			_wait = 1.0
		"crowbar":
			if not Game.flag("crowbar_taken"):
				Game.setf("crowbar_taken")
				carrying.append("crowbar")
				play.world.remove_prop("crowbar")
				bark("빠루 좋고.")
			goal_index += 1
		"cabinet":
			if not Game.flag("cabinet_open"):
				_work = 140.0
				_work_id = "cabinet"
				bark("이 공구함부터 뜯자.")
			else:
				goal_index += 1
		"chute":
			_work = 50.0
			_work_id = "chute"
			bark("잭만 받치면...")
		"roam":
			_wait = 3.0
			target_cell = NOWHERE


func _finish_work() -> void:
	var id := _work_id
	_work_id = ""
	match id:
		"console":
			# 세 번 틀려서 번호판이 1분 동안 잠긴다
			goal_index += 1
			Game.setf("crook_tried_code")
			Game.wrong_codes += 3
			Game.keypad_locked_until = Game.t + 60.0
			bark("젠장, 잠겨 버렸어.", 2.0)
		"massage":
			goal_index += 1
			Game.setf("crook_rested")
			place(world.world_cell("1F", 44, 14), Vector2i.DOWN)
			bark("좋아. 칼이랑 연장부터 챙기자.", 2.5)
		"cabinet":
			goal_index += 1
			if Game.flag("cabinet_open"):
				return
			Game.setf("cabinet_open")
			play.content.cabinet_broken()
			if not Game.flag("jack_taken"):
				Game.setf("jack_taken")
				carrying.append("jack")
				bark("잭이다. 이걸로 된다.")
			else:
				bark("잭이 없어? 그 도둑놈이...")
		"chute":
			play.crook_escapes_alone()


# ---------------------------------------------------------------- 만남 ----

func _tick_approach() -> void:
	var p: Actor = play.player
	if not p.active or p.hidden_in != "" or world.floor_of(p.cell) != world.floor_of(cell) or _player_dist() > SIGHT + 4:
		mode = "agenda"
		bark("어디 갔어...")
		return
	var d := p.cell - cell
	if abs(d.x) + abs(d.y) == 1 and not moving:
		face(d)
		mode = "agenda"
		play.crook_reaches_player()
		return
	_go(_adjacent_to(p.cell), HURRY)


# ---------------------------------------------------------------- 같이 가기 ----

func start_follow() -> void:
	mode = "follow"
	_path = []


func stay() -> void:
	mode = "wait"
	_path = []


## 부탁받은 자리로 가서 기다린다 (식료품 창고 뒤지기 같은 심부름)
func go_wait_at(c: Vector2i) -> void:
	mode = "errand"
	target_cell = c
	_path = []


func _tick_follow() -> void:
	var p: Actor = play.player
	if world.floor_of(p.cell) != world.floor_of(cell):
		# 도둑이 계단을 탔으면 곧바로 뒤따라 온다
		var spot := p.cell + Vector2i.DOWN
		if not world.passable(spot, self):
			spot = _adjacent_to(p.cell)
		place(spot, Vector2i.DOWN)
		return
	var dist := Vector2(p.cell - cell).length()
	if dist <= 1.5:
		if not moving:
			var d := p.cell - cell
			if abs(d.x) + abs(d.y) == 1:
				face(d)
		return
	_go(_adjacent_to(p.cell), CHASE if dist > 4 else HURRY)


# ---------------------------------------------------------------- 적 ----

func start_hunt() -> void:
	mode = "hunt"
	_path = []
	_last_seen = play.player.cell
	target_cell = NOWHERE


func _tick_hunt(delta: float) -> void:
	if can_see_player():
		mode = "chase"
		_lost = 0.0
		bark(["거기 있었냐!", "너 이리 와!", "이놈이!"].pick_random())
		play.chase_started()
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if target_cell == NOWHERE or _go(target_cell, HURRY) or (_path.is_empty() and not moving):
		# 다음 목적지: 도둑을 마지막으로 본 층의 아무 방
		var f: String = world.floor_of(_last_seen) if randf() < 0.7 else world.floor_of(play.player.cell)
		var rooms := []
		for r in world.room_cells:
			if world.room_floor[r] == f and world.name_of_room(r) not in ["뒷마당", ""]:
				rooms.append(r)
		if rooms.is_empty():
			return
		var cells: Array = world.room_cells[rooms.pick_random()]
		target_cell = cells.pick_random()
		for _i in 10:
			if not world.blocked_by_object(target_cell):
				break
			target_cell = cells.pick_random()
		_wait = 1.2


func _tick_chase(delta: float) -> void:
	var p: Actor = play.player
	if can_see_player():
		_last_seen = p.cell
		_lost = 0.0
	else:
		_lost += delta
		if _lost > 1.2:
			mode = "search"
			_searching = false
			play.chase_ended()
			return
	if p.hidden_in == "" and position.distance_to(p.position) <= 17.0:
		face(Vector2i(signi(p.cell.x - cell.x), 0) if p.cell.x != cell.x else Vector2i(0, signi(p.cell.y - cell.y)))
		caught_player.emit()
		return
	_go(_adjacent_to(p.cell) if can_see_player() else _last_seen, CHASE)


func _tick_search(delta: float) -> void:
	if can_see_player():
		mode = "chase"
		play.chase_started()
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if not _searching:
		if not _go(_last_seen, HURRY):
			return
		_search_left = play.content.hide_spots_near(_last_seen)
		_searching = true
	if moving:
		return
	if _search_left.is_empty():
		mode = "hunt"
		target_cell = NOWHERE
		_wait = 1.0
		return
	var spot: Dictionary = _search_left[0]
	if _go(spot["stand"], HURRY):
		face(spot["face"])
		_search_left.pop_front()
		_wait = 0.9
		if play.player.hidden_in == spot["id"]:
			if play.content.hide_seen:
				play.found_hiding(spot["id"])
				return
			bark("...여긴 없나.")


# ---------------------------------------------------------------- 쓰러짐 ----

func knock_down(state: String, secs := 0.0) -> void:
	mode = "down"
	Game.crook_state = state
	_down_left = secs
	_path = []
	_work = 0.0
	hide_bubble()
	if state == "locked":
		visible = false
		return
	sprite.rotation_degrees = 90
	sprite.offset = Vector2(-20, -10)
	sprite.modulate = Color(0.55, 0.5, 0.5) if state == "dead" else Color(0.8, 0.8, 0.85)


func _tick_down(delta: float) -> void:
	if Game.crook_state in ["stunned", "asleep"]:
		_down_left -= delta
		if _down_left <= 0.0:
			get_up()


func get_up() -> void:
	sprite.rotation_degrees = 0
	sprite.offset = Vector2(-8, -24)
	sprite.modulate = Color.WHITE
	var was := Game.crook_state
	Game.crook_state = "free"
	play.crook_woke(was)


func is_down() -> bool:
	return mode == "down"


func leave() -> void:
	mode = "gone"
	active = false
	visible = false
