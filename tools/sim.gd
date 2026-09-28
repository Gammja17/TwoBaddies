extends Node
## 자동 시험: 사람 대신 게임을 굴려 경로마다 끝까지 가는지 본다.
##   godot --headless --fixed-fps 60 --path . res://tools/sim.tscn -- <시나리오>
## 시나리오: agenda, coop, code, print, trap, hostile, betray, endings, all

var main: Node
var play: Node
var W: World
var failures: Array = []
var scen := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	scen = args[0] if args.size() > 0 else "all"
	Game.test_mode = true
	Engine.time_scale = 4.0
	var list := ["endings", "agenda", "coop", "code", "print", "trap", "hostile", "betray", "hide", "jack", "push"] if scen == "all" else [scen]
	for s in list:
		print("\n==== ", s, " ====")
		await call("s_" + s)
	print("\n==== 결과: ", "모두 통과" if failures.is_empty() else "실패 %d" % failures.size())
	for f in failures:
		print("  FAIL ", f)
	get_tree().quit(1 if failures.size() > 0 else 0)


func check(cond: bool, what: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		failures.append(scen + ": " + what)


# ---------------------------------------------------------------- 도우미 ----

func start_game() -> void:
	if main:
		main.queue_free()
		await get_tree().process_frame
	Game.test_choices = []
	Game.test_codes = []
	Game.test_log = []
	main = preload("res://scripts/main.gd").new()
	add_child(main)
	await get_tree().process_frame
	main.start_run(true)
	play = main.play
	W = play.world
	_ending = ""
	play.finished.connect(func(id): _ending = id)
	await until(func(): return Game.phase == "play" and not play._running, 30.0)


func until(cond: Callable, game_secs: float) -> bool:
	var t0 := Time.get_ticks_msec()
	var elapsed := 0.0
	while not cond.call():
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed > game_secs:
			return false
	return true


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func idle() -> void:
	await until(func(): return not play._running, 60.0)


func cell(f: String, x: int, y: int) -> Vector2i:
	return W.world_cell(f, x, y)


## 플레이어를 칸에 세우고 방향을 본 뒤 조사한다.
func use(f: String, x: int, y: int, face: Vector2i, choices: Array = []) -> void:
	await idle()
	play.teleport_player(cell(f, x, y), face)
	Game.test_choices = choices.duplicate()
	play.interact()
	await wait(0.1)
	await idle()


## 물건 앞에 서서 조사한다.
func use_obj(id: String, choices: Array = []) -> void:
	var spot := _stand_spot(W.obj(id))
	await idle()
	play.teleport_player(spot["cell"], spot["face"])
	Game.test_choices = choices.duplicate()
	play.interact()
	await wait(0.1)
	await idle()


func hide_player() -> void:
	play.player.set_hidden("test")


var _ending := ""


func ending() -> String:
	await until(func(): return _ending != "", 60.0)
	return _ending


func dump_log(n := 12) -> void:
	var l: Array = Game.test_log
	for i in range(max(0, l.size() - n), l.size()):
		print("    | ", l[i])


# ---------------------------------------------------------------- 시나리오 ----

func s_endings() -> void:
	var cases := [
		[{"escaped": true, "coop_ever": true, "affinity": 70}, false, "friend"],
		[{"escaped": true, "coop_ever": true, "affinity": 70}, true, "two_baddies"],
		[{"escaped": true, "coop_ever": true, "affinity": 40}, false, "tale"],
		[{"escaped": true, "coop_ever": true, "affinity": 40}, true, "rich"],
		[{"escaped": true}, false, "tale"],
		[{"escaped": true, "hostile": true}, false, "revenge_out"],
		[{"escaped": true, "crook_state": "dead", "kill_clean": true}, false, "perfect"],
		[{"escaped": true, "crook_state": "dead"}, false, "fugitive"],
		[{"coop_ever": true, "affinity": 70}, true, "loyal"],
		[{"coop_ever": true, "affinity": 70}, false, "broke"],
		[{"coop_ever": true, "affinity": 40}, true, "snitch"],
		[{"coop_ever": true, "affinity": 40}, false, "broke"],
		[{"hostile": true}, true, "snitch"],
		[{"crook_state": "dead"}, false, "murder"],
		[{"hostile": true}, false, "revenge_release"],
		[{"player_dead": true, "death_cause": "crook"}, false, "killed"],
		[{"betrayed_by_him": true}, false, "backstab"],
		[{"player_dead": true, "death_cause": "slip"}, false, "slip"],
		[{"escaped": true, "left_behind": true, "coop_ever": true, "affinity": 80}, false, "revenge_out"],
	]
	var seen := {}
	for c in cases:
		Game.new_run()
		for k in c[0]:
			Game.set(k, c[0][k])
		if c[1]:
			Game.steal("gold", 4000)
		var got := Game.resolve_ending()
		seen[got] = true
		check(got == c[2], "%s -> %s (기대 %s)" % [str(c[0]), got, c[2]])
		var ls := Endings.lines(got)
		check(ls.size() >= 3, "%s 엔딩 글 %d줄" % [got, ls.size()])
	check(seen.size() == Endings.ORDER.size(), "엔딩 %d / %d 가지 모두 나옴" % [seen.size(), Endings.ORDER.size()])


func s_agenda() -> void:
	await start_game()
	hide_player()
	var c: Actor = play.crook
	var last := ""
	var t_knife := -1.0
	var t_crowbar := -1.0
	var t_jack := -1.0
	while Game.t < 1150.0 and c.mode != "gone":
		await wait(1.0)
		var s := "%s %s goal=%d room=%s" % [Game.clock_text(), c.mode, c.goal_index, W.name_of_room(W.room_at(c.cell))]
		if s.substr(6) != last:
			last = s.substr(6)
			print("   ", s)
		if t_knife < 0 and c.carrying.has("knife"):
			t_knife = Game.t
		if t_crowbar < 0 and c.carrying.has("crowbar"):
			t_crowbar = Game.t
		if t_jack < 0 and c.carrying.has("jack"):
			t_jack = Game.t
	check(t_knife > 0, "식칼을 챙김 (%.0f초)" % t_knife)
	check(t_crowbar > 0, "쇠지렛대를 챙김 (%.0f초)" % t_crowbar)
	check(t_jack > 0, "공구함을 뜯어 잭을 챙김 (%.0f초)" % t_jack)
	check(c.mode == "gone", "석탄 구멍으로 혼자 빠져나감 (%s)" % Game.clock_text())
	check(Game.t > 300.0 and Game.t < 1100.0, "혼자 빠져나간 시각이 적당함 (%.0f초)" % Game.t)


func s_coop() -> void:
	await start_game()
	var c: Actor = play.crook
	# 곽두철이 내려오기 전에 손님방 문 앞에서 만난다
	await use("2F", 3, 16, Vector2i.UP, [0, 0])
	dump_log(6)
	check(Game.coop and Game.met, "처음 만나 같이 가기로 함")
	check(Game.affinity == 50, "솔직하게 말해 호감 50 (%d)" % Game.affinity)
	check(c.mode == "follow", "따라온다 (%s)" % c.mode)
	# 꽤 믿는 사이(호감 60)가 되면, 어떻게 나갈지 물을 때 석탄 구멍을 알려 준다
	Game.affinity = 60
	Game.test_choices = [0]
	play.teleport_player(c.cell + Vector2i.DOWN, Vector2i.UP)
	await wait(0.2)
	play.player.face(c.cell - play.player.cell)
	play.interact()
	await wait(0.1)
	await idle()
	check(Game.flag("chute_told"), "석탄 구멍 이야기를 들음")
	# 지하 석탄 구멍 앞으로 간다 (곽두철이 따라온다)
	play.teleport_player(cell("B1", 11, 3), Vector2i.UP)
	await wait(4.0)
	check(Vector2(c.cell - play.player.cell).length() <= 2.0, "지하까지 따라옴 (%s)" % str(c.cell - play.player.cell))
	Game.test_choices = [0, 0]
	play.player.face(Vector2i.UP)
	play.interact()
	await wait(0.1)
	await idle()
	dump_log(8)
	var id: String = await ending()
	check(Game.escaped and Game.escaped_with_crook, "둘이 석탄 구멍으로 빠져나감")
	check(id == "friend", "엔딩: %s (호감 %d, 기대 friend)" % [id, Game.affinity])


func s_code() -> void:
	await start_game()
	hide_player()
	play.crook.active = false
	play.player.set_hidden("")
	# 메모장은 주워야 쓸 수 있다
	check(not Game.has("notepad"), "처음에는 메모장이 없음")
	play.open_memo()
	await idle()
	check(not Game.test_log.has("[메모장] 0자"), "줍기 전에는 메모장이 안 열림")
	await use_obj("notepad")
	check(Game.has("notepad") and W.obj("notepad") == null, "세탁기 위 메모장을 주움")
	Game.memo = "760515?"
	Game.test_log = []
	play.open_memo()
	await idle()
	check(Game.test_log.has("[메모장] 7자"), "주운 메모장을 펼침")
	Game.test_codes = ["123456", "760515"]
	await use("1F", 30, 18, Vector2i.DOWN, [0])
	check(not Game.flag("front_open") and Game.wrong_codes == 1, "틀린 번호는 안 열림")
	await use("1F", 30, 18, Vector2i.DOWN, [0])
	check(Game.flag("front_open"), "결혼한 날 760515 로 현관이 열림")
	Game.test_choices = [0]
	play.teleport_player(cell("1F", 27, 19), Vector2i.DOWN)
	play.player.try_step(Vector2i.DOWN)
	var id: String = await ending()
	check(Game.escaped, "현관으로 나감")
	check(id == "tale", "엔딩: %s (기대 tale)" % id)


func s_print() -> void:
	await start_game()
	check(Game.memo == "" and not Game.has("notepad"), "새 판이면 메모장이 비어 있고 다시 주워야 함")
	play.crook.active = false
	# 분첩, 테이프를 챙겨 위스키 잔에서 지문을 뜬다
	Game.give("compact")
	Game.give("tape")
	await use("1F", 27, 6, Vector2i.RIGHT, [0])
	await wait(8.0)
	await idle()
	check(Game.has("fingerprint"), "지문 테이프를 만듦")
	await use("1F", 30, 18, Vector2i.DOWN, [1])
	await wait(3.0)
	await idle()
	check(Game.flag("front_open"), "지문으로 현관이 열림")
	# 금고도 턴다
	await use("2F", 31, 4, Vector2i.UP, [0, 0])
	Game.test_codes = ["0823"]
	await use("2F", 31, 4, Vector2i.UP, [0, 0])
	check(Game.loot.has("gold"), "손자 생일 0823 으로 금고를 열고 금괴를 챙김")
	Game.test_choices = [0]
	play.teleport_player(cell("1F", 27, 19), Vector2i.DOWN)
	play.player.try_step(Vector2i.DOWN)
	var id: String = await ending()
	check(id == "rich", "엔딩: %s (기대 rich)" % id)


func s_trap() -> void:
	await start_game()
	hide_player()
	play.player.set_hidden("")
	var c: Actor = play.crook
	c.active = false
	await use("1F", 23, 12, Vector2i.UP, [0])
	check(Game.flag("stair_dark"), "지하 계단 전구를 뺌")
	await use("1F", 20, 4, Vector2i.UP)
	check(Game.has("oil"), "식용유를 챙김")
	await use("1F", 21, 14, Vector2i.UP, [0])
	check(Game.flag("stair_oiled"), "계단에 식용유를 부음")
	# 곽두철이 지하로 가려는 순간을 기다린다
	c.active = true
	c.start()
	c._wait = 0.0
	c._search_rooms = []
	c.goal_index = c.STEPS.find("crowbar")
	hide_player()
	await until(func(): return Game.crook_state == "dead", 200.0)
	await idle()
	check(Game.crook_state == "dead" and Game.kill_clean, "어두운 기름 계단에서 떨어짐")
	play.player.set_hidden("")
	Game.test_codes = ["760515"]
	await use("1F", 30, 18, Vector2i.DOWN, [0])
	Game.test_choices = [0]
	play.teleport_player(cell("1F", 27, 19), Vector2i.DOWN)
	play.player.try_step(Vector2i.DOWN)
	var id: String = await ending()
	check(id == "perfect", "엔딩: %s (기대 perfect)" % id)


func s_hostile() -> void:
	await start_game()
	Game.give("pan")
	var c: Actor = play.crook
	await use("2F", 3, 16, Vector2i.UP, [3])
	check(Game.hostile and Game.crook_state == "stunned", "처음 만나자마자 프라이팬으로 침")
	await until(func(): return c.mode in ["hunt", "chase", "search"], 40.0)
	check(c.mode in ["hunt", "chase", "search"], "깨어나서 쫓아옴 (%s)" % c.mode)
	# 가만히 서 있으면 잡힌다 (시험에서는 연타를 안 하니 뿌리치지 못한다)
	var spot: Vector2i = c.cell + Vector2i.RIGHT if W.passable(c.cell + Vector2i.RIGHT) else c.cell + Vector2i.LEFT
	play.teleport_player(spot, Vector2i.LEFT)
	for i in 12:
		await wait(0.5)
		print("    crook %s at %s, player %s, running=%s, busy=%d" % [c.mode, str(c.cell), str(play.player.cell), play._running, Game.busy])
		if _ending != "":
			break
	var id: String = await ending()
	check(id == "killed", "엔딩: %s (기대 killed)" % id)


## 숨었다가 실제 키 입력(Z)으로 나온다 (예전에 숨으면 못 나오던 버그)
func s_hide() -> void:
	await start_game()
	play.crook.active = false
	await use("2F", 7, 4, Vector2i.UP, [0])
	check(play.player.hidden_in == "wardrobe", "옷장에 숨음")
	await wait(0.5)
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = "act"
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await wait(0.1)
	await idle()
	check(play.player.hidden_in == "" and play.player.visible, "Z 를 눌러 옷장에서 나옴")
	# 숨어 있는 동안 곽두철이 그 자리에 와 섰으면 옆 칸으로 나온다
	await use("2F", 7, 4, Vector2i.UP, [0])
	var c: Actor = play.crook
	c.active = true
	c.place(play.player.cell, Vector2i.UP)
	Game.test_choices = []
	play.interact()
	await wait(0.2)
	await idle()
	check(play.player.hidden_in == "" and play.player.cell != c.cell, "곽두철과 겹치지 않는 칸으로 나옴")


## 혼자 잭으로 석탄 구멍을 연다: 구멍이 높아서 발판 없이는 못 올라가고, 발판을 주워 오면 나간다
func s_jack() -> void:
	await start_game()
	play.crook.active = false
	Game.give("jack")
	await use("B1", 11, 3, Vector2i.UP, [0])
	check(Game.flag("chute_open") and not Game.escaped, "잭으로 쇠창살을 열었지만 발판이 없어 못 올라감")
	await use_obj("stool")
	check(Game.has("stool"), "식료품 창고에서 발판을 주움")
	await use("B1", 11, 3, Vector2i.UP, [0])
	var id: String = await ending()
	check(Game.escaped and id == "tale", "발판을 딛고 석탄 구멍으로 나감 (엔딩 %s)" % id)


## 곽두철 쪽으로 방향키를 꾹 누르면 투덜대며 자리를 바꿔 비켜 준다
func s_push() -> void:
	await start_game()
	var c: Actor = play.crook
	Game.met = true
	Game.coop = true
	Game.coop_ever = true
	c.greeted = true
	c.active = true
	c.stay()
	play.teleport_player(cell("1F", 26, 15), Vector2i.RIGHT)
	c.place(cell("1F", 27, 15), Vector2i.LEFT)
	var a0 := Game.affinity
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = "right"
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await wait(0.6)
	await wait(0.4)
	check(c.cell == cell("1F", 26, 15) and play.player.cell.x >= cell("1F", 27, 15).x, "곽두철을 밀고 지나감 (곽두철 %s, 도둑 %s)" % [str(c.cell), str(play.player.cell)])
	check(Game.affinity == a0 - 2, "호감이 조금 내려감 (%d -> %d)" % [a0, Game.affinity])
	# 쓰러져 있으면 그냥 넘어간다
	c.knock_down("stunned", 999.0)
	play.teleport_player(cell("1F", 25, 15), Vector2i.RIGHT)
	play.player.try_step(Vector2i.RIGHT)
	await wait(0.4)
	check(play.player.cell == c.cell, "쓰러진 곽두철은 넘어갈 수 있음")


## 모든 물건을 차례로 조사한다 (선택지는 무작위). 실행 오류가 나면 Godot 이 SCRIPT ERROR 를 찍는다.
func s_fuzz() -> void:
	for pass_i in 3:
		seed(1234 + pass_i)
		await start_game()
		var c: Actor = play.crook
		match pass_i:
			0:
				c.active = false
			1:
				for it in ["pan", "knife", "rope", "compact", "tape", "oil", "pills", "sandwich", "whiskey", "gloves", "crowbar", "jack"]:
					Game.give(it)
				play.run(func(): await play.content.first_encounter())
				Game.test_choices = [0, 0]
				await idle()
			2:
				Game.give("rope")
				Game.give("knife")
				c.knock_down("stunned", 999.0)
		var ids: Array = W.objects.keys()
		var count := 0
		for id in ids:
			var p = W.obj(id)
			if p == null or play.content.rank(p) <= 0:
				continue
			var spot := _stand_spot(p)
			if spot.is_empty():
				continue
			if Game.phase != "play" or play._ended:
				break
			play.player.set_hidden("")
			play.teleport_player(spot["cell"], spot["face"])
			Game.test_choices = []
			for k in 6:
				Game.test_choices.append(randi() % 3)
			play.interact()
			await wait(0.05)
			var ok := await until(func(): return not play._running, 25.0)
			if not ok:
				print("    멈춤: ", id)
				failures.append("fuzz: %s 에서 대본이 끝나지 않음" % id)
				break
			count += 1
		check(count > 40, "패스 %d: 물건 %d개 조사" % [pass_i, count])
		# 곽두철에게도 말을 걸어 본다
		if c.active and not play._ended:
			play.teleport_player(c.cell + Vector2i.DOWN if W.passable(c.cell + Vector2i.DOWN) else c.cell + Vector2i.UP, Vector2i.UP)
			play.player.face(c.cell - play.player.cell)
			Game.test_choices = [randi() % 3, 0, 0]
			play.interact()
			await wait(0.05)
			await until(func(): return not play._running, 25.0)


func _stand_spot(p) -> Dictionary:
	var dirs := [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
	for c in p.cells():
		for d in dirs:
			var s: Vector2i = c + d
			if p.cells().has(s):
				continue
			if W.terrain_walkable(s) and not W.blocked_by_object(s) and W.stairs_at(s).is_empty():
				return {"cell": s, "face": -d}
			# 벽에 붙은 물건: 두 칸 아래에서 올려다본다
		if p.layer == "wall":
			for k in range(1, 3):
				var s2: Vector2i = c + Vector2i(0, k)
				if W.terrain_walkable(s2) and not W.blocked_by_object(s2) and W.stairs_at(s2).is_empty():
					return {"cell": s2, "face": Vector2i.UP}
	return {}


func s_betray() -> void:
	await start_game()
	var c: Actor = play.crook
	await use("2F", 3, 16, Vector2i.UP, [2, 0])
	check(Game.coop and Game.affinity == 25, "겁을 주고도 같이 가기로 함 (호감 %d)" % Game.affinity)
	# 석탄 구멍은 스스로 찾아낸다
	play.teleport_player(cell("B1", 12, 4), Vector2i.UP)
	c.place(cell("B1", 13, 4), Vector2i.UP)
	await wait(0.5)
	await use("B1", 11, 3, Vector2i.UP, [0])
	dump_log(8)
	check(Game.betrayed_by_him, "먼저 올라간 곽두철이 쇠창살을 닫아 버림")
	Game.test_codes = ["760515"]
	await use("1F", 30, 18, Vector2i.DOWN, [0])
	Game.test_choices = [0]
	play.teleport_player(cell("1F", 27, 19), Vector2i.DOWN)
	play.player.try_step(Vector2i.DOWN)
	var id: String = await ending()
	check(id == "backstab", "엔딩: %s (기대 backstab)" % id)
