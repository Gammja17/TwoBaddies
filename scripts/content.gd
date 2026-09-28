extends RefCounted
## 이야기: 물건마다 조사하면 일어나는 일, 퍼즐, 곽두철과의 대화, 사건.
## 물건 id 로 찾는 함수는 o_<id>, 종류로 찾는 함수는 k_<kind>.

const CODE_FRONT := "760515"   # 결혼한 날 1976년 5월 15일 (여섯 자리)
const CODE_SAFE := "0823"      # 손자 지훈이 생일 8월 23일

var play: Node
var hide_seen := false          # 숨는 모습을 곽두철이 봤는지
var _prologue_step := 0


func _init(p: Node) -> void:
	play = p


# ================================================================ 도우미 ====

func me(text: String, expr := "normal") -> void:
	await play.say("thief", text, expr)


func him(text: String, expr := "normal") -> void:
	await play.say("crook", text, expr)


func narr(text: String) -> void:
	await play.narr(text)


func pick(options: Array, disabled: Array = []) -> int:
	return await play.choose(options, disabled)


func W() -> World:
	return play.world


func crook() -> Actor:
	return play.crook


func got(item: String) -> void:
	Game.give(item)
	Sfx.play("pick")
	play.toast("%s 챙김" % Items.name_of(item), UI.GOLD)


func crook_near(dist := 3.0) -> bool:
	var c: Actor = crook()
	if not c.active or c.mode == "gone" or c.is_down():
		return false
	if W().floor_of(c.cell) != W().floor_of(play.player.cell):
		return false
	return Vector2(c.cell - play.player.cell).length() <= dist


func with_him() -> bool:
	return Game.coop and crook_near(4.0)


func affinity(n: int, why := "") -> void:
	Game.add_affinity(n, why)
	if crook().active and crook().visible:
		crook().bark("(호감 ▲)" if n > 0 else "(호감 ▼)", 1.4)


## 물건 위에 뜬 소품을 없앤다 (집어 갔을 때)
func take_prop(id: String) -> void:
	W().remove_prop(id)


func rank(p) -> int:
	if has_method("o_" + p.id):
		return 3 if p.layer == "top" else 2
	if p.kind != "" and has_method("k_" + p.kind):
		return 1
	return 0


func interact(p) -> void:
	if has_method("o_" + p.id):
		await call("o_" + p.id, p)
	else:
		await call("k_" + p.kind, p)


# ================================================================ 프롤로그 ====

func prologue_intro() -> void:
	Sfx.music("")
	await narr("새벽 두 시. 가평의 외딴 산자락.")
	await narr("남궁 씨 노부부의 별장은 오늘 밤 비어 있다. 결혼 50주년 기념으로 긴 여행을 떠났다고 했다.")
	await narr("좀도둑 오만복이 시장 바닥에서 주워들은 이야기는 거기까지였다.")
	play.dlg.close()
	await play.fade(0.0, 1.0)
	play.world.update_fog(play.player.cell, true)
	await me("좋아. 뒷문으로 조용히 들어가서, 조용히 들고 나오는 거야.")
	_prologue_step = 1
	play.hud.hint("방향키로 걸어요. 휴대폰은 왼쪽 패드. 뒷문(오른쪽 위)으로 가 봐요.")


func skip_to_alarm() -> void:
	Game.phase = "prologue"
	var door = W().obj("back_door")
	W().set_sprite(door, "door_side_open")
	door.solid = false
	take_prop("flashlight")
	Game.give("flashlight")
	play.teleport_player(W().world_cell("1F", 14, 13), Vector2i.UP)
	await narr("좀도둑 오만복은 빈 별장의 뒷문을 따고 들어왔다. 손전등 하나 챙겨 들고, 부엌 쪽 문을 연 순간이었다.")
	play.dlg.close()
	await play.fade(0.0, 0.6)
	await alarm()


func on_step(c: Vector2i) -> void:
	if Game.phase == "prologue":
		var l: Array = W().to_local_cell(c)
		if _prologue_step == 1 and l[0] == "1F" and Vector2(l[1] - Vector2i(8, 15)).length() <= 1.5:
			_prologue_step = 2
			play.hud.hint("문을 바라보고 [Z] 또는 A 버튼으로 조사해요.")
		elif _prologue_step >= 3 and l[0] == "1F" and l[1] == Vector2i(14, 11):
			play.run(alarm)
		return
	# 기름 부은 계단 옆을 지나갈 때 한 번 알려 준다
	if Game.flag("stair_oiled") and not Game.flag("warned_oil"):
		var l2: Array = W().to_local_cell(c)
		if l2[0] == "1F" and l2[1].y == 14 and (l2[1].x == 21 or l2[1].x == 22):
			Game.setf("warned_oil")
			play.toast("계단에 기름을 부어 두었다.", UI.DIM)
	# 열린 현관문 위로 걸어 나가기
	var ch: String = W().char_at(c)
	if ch == "O" and Game.flag("front_open"):
		play.run(exit_front)


func on_enter_room(name: String) -> void:
	if Game.phase == "prologue":
		if name == "다용도실" and _prologue_step == 2:
			_prologue_step = 3
			play.hud.hint("탁자 위 손전등을 [Z]로 챙겨요.")
		return
	if Game.coop and crook_near(6.0) and not Game.flag("bark_" + name):
		Game.setf("bark_" + name)
		var lines := {
			"서재": "영감 서재구먼. 책은 많은데 다 폼이야.",
			"안방": "노인네들 방은 건드리지 말자. 아니다, 급하니까 뒤져.",
			"손님방": "여기가 내 방이었다. 사흘 동안.",
			"보일러실": "여기서 들어왔지. 춥다.",
			"거실": "저 안마의자 물건이다. 한번 앉아 봐.",
			"식당": "식탁 하나에 의자가 여덟 개. 둘이 사는 집에.",
			"주방": "냉장고에 먹을 거 있으면 나 좀 줘라.",
		}
		if lines.has(name):
			crook().bark(lines[name], 2.8)


func alarm() -> void:
	play.hud.hint("")
	Sfx.loop("alarm", true, -6.0)
	play.hud.red_flash(4)
	await me("어? 어어?", "shock")
	Sfx.play("shutter")
	await play.get_tree().create_timer(0.3).timeout
	Sfx.play("shutter")
	var door = W().obj("back_door")
	W().set_sprite(door, "shutter_back")
	door.solid = true
	_shutter_windows()
	await play.say("pa", "외부 침입이 감지되었습니다. 모든 출입구와 창문을 봉쇄합니다.")
	await play.say("pa", "경찰에 자동으로 신고되었습니다. 경찰 도착 예정 시각은 새벽 2시 30분입니다.")
	Sfx.loop("alarm", false)
	await me("망했다. 철문이 다 내려왔어.", "nervous")
	await me("20분. 경찰 오기 전에 무슨 수를 써서라도 여기서 나가야 해.", "nervous")
	Sfx.play("thud", 2.0)
	await play.get_tree().create_timer(0.5).timeout
	await me("...방금 위층에서 쿵 소리 났지? 이 집, 비어 있는 거 아니었어?", "shock")
	play.dlg.close()
	Game.phase = "play"
	Game.clock_on = true
	Game.prologue_done = true
	Game.save()
	play.hud.show_clock(true)
	Sfx.music("sneak")
	crook().active = true
	crook().start()
	play.hud.hint("집 안을 뒤져 나갈 방법을 찾아요. [C] 또는 '주머니'로 가진 것 보기.")
	play.get_tree().create_timer(7.0).timeout.connect(func():
		if is_instance_valid(play) and not Game.phase == "prologue":
			play.hud.hint(""))


func _shutter_windows() -> void:
	for id in W().objects.keys():
		var p = W().objects[id]
		if p.kind == "window":
			var s := World.Prop.new()
			s.id = "shutter_" + id
			s.floor_name = p.floor_name
			s.cell = p.cell
			s.w = 1
			s.h = p.h
			s.layer = "wall"
			s.solid = false
			s.centered = false
			W().add_prop(s, "shutter_window" if p.h == 2 else "shutter_window_small")


# ================================================================ 뒷마당, 다용도실 ====

func k_yard_exit(_p) -> void:
	await me("여기까지 와서 빈손으로 돌아갈 순 없지.")


func k_hedge(_p) -> void:
	await narr("잘 다듬은 울타리 나무다. 이 집 할아버지 솜씨일까.")


func k_tree(_p) -> void:
	await narr("밤바람에 나뭇잎이 사락거린다.")


func k_bush(_p) -> void:
	await narr("덤불이다. 숨기엔 너무 작다.")


func k_flowers(_p) -> void:
	await narr("누군가 정성껏 가꾼 꽃밭이다.")


func o_back_door(p) -> void:
	if Game.phase == "prologue":
		if not p.solid:
			await me("열어 놨다. 들어가자.")
			return
		await me("잠겨 있네. 이 정도야 뭐.")
		var ok: bool = await play.lockpick("뒷문 자물쇠", 0, true)
		if ok:
			Sfx.play("door_open")
			W().set_sprite(p, "door_side_open")
			p.solid = false
			W().refresh_nav()
			await me("열렸다. 역시 손은 안 녹슬었어.", "smile")
			play.hud.hint("안으로 들어가요.")
		else:
			await me("다시 해 보자. 초록 칸에서 누르면 돼.")
		return
	await narr("철문이 내려와 꿈쩍도 하지 않는다.")


func o_flashlight(_p) -> void:
	take_prop("flashlight")
	got("flashlight")
	await me("손전등. 이거 있으면 불 안 켜고 다닐 수 있지.")
	if Game.phase == "prologue":
		_prologue_step = 4
		play.hud.hint("[C] 또는 '주머니' 버튼으로 주머니를 열어 봐요.")


## 주머니를 닫았을 때 (프롤로그 안내용)
func pocket_closed() -> void:
	if Game.phase == "prologue" and _prologue_step == 4:
		_prologue_step = 5
		play.hud.hint("좋아요. 이제 부엌으로 가는 문(위쪽)으로 가 봐요.")


func k_washer(_p) -> void:
	await narr("세탁기다. 할머니 스웨터 한 벌이 돌다 만 채 들어 있다.")


func o_notepad(_p) -> void:
	await narr("세탁기 위에 할머니가 장 볼 거리를 적던 메모장과 볼펜이 있다.")
	take_prop("notepad")
	got("notepad")
	await me("메모장이랑 볼펜이네. 번호 같은 건 적어 두자.")
	# 잠깐 알려 주고, 원래 떠 있던 안내(프롤로그)로 돌려 놓는다
	var tip := "왼쪽 아래 메모장을 누르거나 M 키로 적어 봐요."
	var before: String = play.hud.hint_label.text if play.hud.hint_panel.visible else ""
	play.hud.hint(tip)
	play.get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(play) and play.hud.hint_panel.visible and play.hud.hint_label.text == tip:
			play.hud.hint(before))


func k_clothesline(_p) -> void:
	await narr("빨래가 널려 있다. 떠나기 전날 빨았나 보다.")


func k_table(_p) -> void:
	await narr("작은 탁자다.")


func k_counter(_p) -> void:
	await narr("찬장이다. 그릇이 가지런히 쌓여 있다.")


func k_boxes(_p) -> void:
	await narr("상자 더미다. 이삿짐 풀다 만 것처럼 보인다.")


func o_gloves(_p) -> void:
	take_prop("gloves")
	got("gloves")
	await me("목장갑이네. 끼고 다니면 지문 걱정은 없겠다.")
	await narr("주머니에서 끼고 벗을 수 있다.")


func o_rope(_p) -> void:
	take_prop("rope")
	got("rope")
	await me("빨랫줄. 뭐든 묶을 수 있겠어.")


# ================================================================ 식료품 창고, 주방 ====

func k_pantry_shelf(_p) -> void:
	await narr("라면이 상자째 쌓여 있다. 그런데 한 상자는 거의 비었다.")
	if not Game.met:
		await me("노인네 둘이 라면을 이렇게 먹었다고? 이상한데.")


func o_pantry_door(p) -> void:
	var state: String = p.state if p.state != "" else "open"
	var inside := _crook_in_pantry()
	var player_inside: bool = W().name_of_room(W().room_at(play.player.cell)) == "식료품 창고"
	if player_inside:
		if state == "latched":
			await me("밖에서 걸쇠가 걸렸어! 따개로 틈새를 들어 올려 보자.", "nervous")
			var ok: bool = await play.lockpick("문틈 걸쇠", 1)
			if ok:
				_set_pantry(p, "open")
				await me("열렸다.")
			return
		if state == "closed":
			_set_pantry(p, "open")
			Sfx.play("door_open")
			return
		_set_pantry(p, "closed")
		Sfx.play("door_close")
		return
	match state:
		"open":
			var opts := ["문을 닫는다", "그대로 둔다"]
			var i := await pick(opts)
			if i == 0:
				_set_pantry(p, "closed")
				Sfx.play("door_close")
				if inside:
					await him("야, 왜 닫아?", "angry")
		"closed":
			var i := await pick(["문을 연다", "걸쇠를 건다", "그대로 둔다"])
			if i == 0:
				_set_pantry(p, "open")
				Sfx.play("door_open")
			elif i == 1:
				_set_pantry(p, "latched")
				Sfx.play("latch")
				if inside:
					await lock_crook_in()
				else:
					await narr("걸쇠를 걸었다. 이제 안에서는 못 연다.")
		"latched":
			if inside and Game.crook_state == "locked":
				await him("야! 문 열어! 너 나중에 두고 보자!", "angry")
				var i := await pick(["걸쇠를 푼다", "못 들은 척한다"])
				if i == 0:
					await narr("걸쇠를 풀면 곧장 달려들 것이다.")
					var j := await pick(["그래도 푼다", "그만둔다"])
					if j == 0:
						_set_pantry(p, "open")
						crook().visible = true
						crook().get_up()
				return
			var i := await pick(["걸쇠를 푼다", "그대로 둔다"])
			if i == 0:
				_set_pantry(p, "open")


func _set_pantry(p, state: String) -> void:
	p.state = state
	W().set_sprite(p, {"open": "door_side_open", "closed": "door_side", "latched": "door_side_latched"}[state])
	p.solid = state != "open"
	W().refresh_nav()


func _crook_in_pantry() -> bool:
	var c: Actor = crook()
	return c.active and W().name_of_room(W().room_at(c.cell)) == "식료품 창고"


func lock_crook_in() -> void:
	await narr("걸쇠가 철컥 걸렸다. 안에서 문이 덜컹거린다.")
	await him("야! 뭐 하는 짓이야! 문 열어!", "angry")
	crook().knock_down("locked")
	Game.hostile = true
	Game.coop = false
	await me("미안해요. 경찰 오면 꺼내 줄 거예요.", "nervous")


func o_pans(_p) -> void:
	if Game.has("pan") or Game.flag("pan_taken"):
		await narr("냄비만 남아 있다.")
		return
	await narr("벽에 무쇠 프라이팬이 걸려 있다. 꽤 묵직하다.")
	var i := await pick(["챙긴다", "그냥 둔다"])
	if i == 0:
		Game.setf("pan_taken")
		W().set_sprite(W().obj("pans"), "hanging_pan_one")
		got("pan")
		await me("이걸로 뒤통수를 치면... 아니, 그럴 일은 없어야지.", "nervous")


func o_fridge(_p) -> void:
	await narr("냉장고 문에 달력이 붙어 있다. 5월 15일 칸에 빨간 하트가 그려져 있다.")
	Game.setf("clue_calendar")
	if not Game.flag("sandwich_taken"):
		await narr("안에는 랩을 씌운 샌드위치가 하나 있다. '영감 야식'이라고 적힌 쪽지가 붙어 있다.")
		var i := await pick(["샌드위치를 챙긴다", "그냥 닫는다"])
		if i == 0:
			Game.setf("sandwich_taken")
			got("sandwich")
	else:
		await narr("반찬통 몇 개뿐이다.")


func o_knife_block(_p) -> void:
	if Game.flag("knife_taken"):
		await narr("칼꽂이에 가장 큰 칼 한 자루가 비어 있다.")
		if not Game.has("knife") and Game.met:
			await me("그 사람이 가져갔나 봐...", "nervous")
		return
	await narr("칼꽂이에 식칼이 꽂혀 있다.")
	var i := await pick(["식칼을 챙긴다", "그냥 둔다"])
	if i != 0:
		return
	Game.setf("knife_taken")
	knife_gone()
	got("knife")
	Sfx.play("knife")
	if with_him():
		await him("그건 왜 챙기냐?", "angry")
		var j := await pick(["혹시 몰라서요.", "당신이 무서워서요."])
		if j == 0:
			await him("...그래. 혹시 모르지.")
		else:
			await him("솔직해서 좋다. 근데 그걸로 날 어쩔 생각이면 관둬라.", "angry")
			affinity(-5, "칼을 챙김")


func knife_gone() -> void:
	var kb = W().obj("knife_block")
	if kb:
		W().set_sprite(kb, "on_knife_block_empty")


func o_oil(_p) -> void:
	take_prop("oil")
	got("oil")
	await me("식용유 한 병. 바닥에 부으면 엄청 미끄럽겠지.")


func k_stove(_p) -> void:
	await narr("가스레인지다. 밸브는 잘 잠겨 있다.")


func k_sink(_p) -> void:
	await narr("개수대가 반짝반짝하다. 누가 쓴 컵 하나가 엎어져 있다.")


func k_chair(_p) -> void:
	await narr("의자다.")


# ================================================================ 식당 ====

func k_window(_p) -> void:
	if Game.phase == "prologue":
		await narr("창문 너머로 달이 떴다.")
	else:
		await narr("철제 셔터가 내려와 있다. 틈 하나 없다.")


func o_d_portrait(_p) -> void:
	await narr("노부부의 초상화다. 할아버지는 무뚝뚝하게, 할머니는 환하게 웃고 있다.")


func k_dining_table(_p) -> void:
	await narr("긴 식탁이다. 여덟 명은 앉겠다.")


func k_candelabra(_p) -> void:
	await narr("금빛 촛대다. 도금이라 값은 별로다.")


func o_glass(_p) -> void:
	await narr("할아버지 자리에 위스키 잔이 놓여 있다. 떠나기 전에 한잔하셨나 보다.")
	await narr("유리에 기름진 손자국이 선명하다.")
	Game.setf("saw_glass")
	await _try_fingerprint("위스키 잔")


func _try_fingerprint(source: String) -> void:
	if Game.has("fingerprint"):
		return
	var powder := "compact" if Game.has("compact") else ("ash" if Game.has("ash") else "")
	if powder == "" or not Game.has("tape"):
		if Game.flag("read_manual"):
			await me("지문 인식기... 이 손자국을 떠 갈 수만 있으면 될 텐데.")
			await me("가루를 뿌리고 투명 테이프로 떠내면 되지 않을까?")
		return
	var i := await pick(["가루를 뿌려 지문을 뜬다", "그냥 둔다"])
	if i != 0:
		return
	var ok: bool = await play.work(5.0, "지문을 뜨는 중")
	if not ok:
		return
	Game.give("fingerprint")
	Sfx.play("success")
	play.toast("할아버지 지문 테이프를 만들었다", UI.GOLD)
	await me("됐다. %s에서 할아버지 지문을 떴어. 영화에서 보던 거, 진짜 되네." % source, "smile")
	if with_him() and not Game.flag("impress_print"):
		Game.setf("impress_print")
		await him("...너 은근 쓸 만하다?", "grin")
		affinity(5, "지문 뜨기")


func o_silver_candle(_p) -> void:
	await narr("묵직한 은촛대다. 진짜 은이다.")
	await _steal_prompt("silver_candle", "silver_candle")


func o_liquor(_p) -> void:
	if Game.flag("whiskey_taken"):
		await narr("장식장에 빈 잔만 남았다.")
		return
	await narr("장식장에 비싼 위스키가 있다. 반쯤 비어 있다.")
	var i := await pick(["위스키를 챙긴다", "그냥 둔다"])
	if i == 0:
		Game.setf("whiskey_taken")
		got("whiskey")


func k_plant(_p) -> void:
	await narr("화분이다. 흙이 촉촉하다. 떠나기 전에 물을 듬뿍 주고 갔나 보다.")


# ================================================================ 훔치기 ====

## 훔칠까 묻고, 곽두철이 옆에 있으면 반을 달라고 한다.
func _steal_prompt(item: String, prop_id: String) -> bool:
	var v := Items.value(item)
	var i := await pick(["챙긴다 (약 %d만원)" % v, "손대지 않는다"])
	if i != 0:
		return false
	if prop_id != "":
		take_prop(prop_id)
	Game.steal(item, v)
	Sfx.play("coins")
	play.toast("%s을(를) 주머니에 넣었다" % Items.name_of(item), UI.GOLD)
	if with_him():
		await him("잠깐. 그거, 반은 내 몫이다.", "grin")
		var j := await pick(["반씩 나눠요.", "제가 찾은 건데요."])
		if j == 0:
			Game.loot_split[item] = true
			await him("말이 통하네.", "grin")
			affinity(10, "훔친 것을 나눔")
		else:
			await him("...그래, 두고 보자.", "angry")
			affinity(-15, "나누지 않음")
	return true


# ================================================================ 현관, 보안실 ====

func o_clock(_p) -> void:
	await narr("벽에 걸린 괘종시계가 멈춰 있다. 5시 15분.")
	await narr("건전지를 뺀 흔적이 있다. 일부러 멈춰 둔 것 같다.")
	Game.setf("clue_clock")
	if Game.flag("read_diary") or Game.flag("read_memo"):
		await me("5시 15분... 5월 15일. 결혼한 날이다!", "shock")


func o_h_mirror(_p) -> void:
	await me("...꼴이 말이 아니네.", "nervous")


func k_painting(_p) -> void:
	await narr("그림이 걸려 있다. 어디서 산 건지 싸구려는 아닌 것 같다.")


func k_mirror(p) -> void:
	await o_h_mirror(p)


func o_stair_lamp(p) -> void:
	if Game.flag("stair_dark"):
		await narr("지하 계단 전등이다. 전구가 빠져 캄캄하다.")
		if Game.has("bulb"):
			var i := await pick(["전구를 다시 끼운다", "그대로 둔다"])
			if i == 0:
				Game.take("bulb")
				Game.setf("stair_dark", false)
				W().set_sprite(p, "bulb_on")
		return
	await narr("지하로 내려가는 계단을 비추는 전등이다.")
	var i := await pick(["전구를 뺀다", "그대로 둔다"])
	if i == 0:
		Game.setf("stair_dark")
		W().set_sprite(p, "bulb_off")
		got("bulb")
		await me("앗 뜨거. 계단이 캄캄해졌다.")


func o_stairs_b1(_p) -> void:
	if Game.has("oil") and not Game.flag("stair_oiled"):
		await narr("지하로 내려가는 계단이다.")
		var i := await pick(["계단에 식용유를 붓는다", "그만둔다"])
		if i == 0:
			Game.take("oil")
			Game.setf("stair_oiled")
			await narr("계단 첫 칸부터 기름을 좍 부었다. 번들번들하다.")
			if not Game.flag("stair_dark"):
				await me("불이 켜져 있으면 누구라도 보고 피해 가겠지.")
			else:
				await me("캄캄해서 아무것도 안 보여. 나도 조심해야 해.", "nervous")
		return
	await narr("지하로 내려가는 계단이다.")


func o_stairs_2f(_p) -> void:
	await narr("2층으로 올라가는 계단이다.")


func o_console(p) -> void:
	if Game.flag("front_open"):
		await narr("보안 단말기에 초록불이 켜져 있다. 현관이 열렸다.")
		return
	await narr("현관 옆 보안 단말기. 화면에 빨간 글씨가 떠 있다. '출입 통제 중'")
	var opts := ["비밀번호를 누른다", "지문을 댄다", "그만둔다"]
	var dis := []
	if not Game.has("fingerprint"):
		dis.append(1)
	var i := await pick(opts, dis)
	if i == 0:
		if Game.keypad_locked_until > Game.t:
			await narr("화면: '입력이 잠겼습니다. %d초 뒤 다시 시도하세요.'" % int(Game.keypad_locked_until - Game.t + 1))
			return
		var code: String = await play.enter_code("현관 비밀번호", 6)
		if code == "":
			return
		if code == CODE_FRONT:
			await open_front(p, "비밀번호")
		else:
			Game.wrong_codes += 1
			Sfx.play("buzz")
			if Game.wrong_codes % 3 == 0:
				Game.keypad_locked_until = Game.t + 60.0
				await narr("화면: '비밀번호를 세 번 틀렸습니다. 1분 동안 입력이 잠깁니다.'")
				await me("아... 아무 숫자나 누르면 안 되겠다.", "nervous")
			else:
				await narr("화면: '비밀번호가 틀렸습니다.'")
	elif i == 1:
		Sfx.play("beep")
		await play.work(1.5, "지문 확인 중")
		await open_front(p, "지문")


func open_front(_p, how: String) -> void:
	Sfx.play("success")
	await narr("삐빅. 화면: '%s 확인. 현관 봉쇄를 해제합니다.'" % how)
	Sfx.play("shutter")
	Game.setf("front_open")
	var door = W().obj("front_door")
	W().set_sprite(door, "door_front_open")
	door.solid = false
	W().set_sprite(W().obj("console"), "console_open")
	W().refresh_nav()
	await me("열렸다! 열렸어!", "shock")
	if with_him():
		await him("잘했다, 좀도둑! 가자!", "grin")
	await narr("현관으로 걸어 나가면 밖이다.")


func o_front_door(_p) -> void:
	if Game.flag("front_open"):
		await exit_front()
		return
	await narr("현관이 철제 셔터로 막혀 있다. 옆의 보안 단말기로 열어야 한다.")


func exit_front() -> void:
	var i := await pick(["밖으로 나간다", "아직 안 나간다"])
	if i != 0:
		play.teleport_player(W().world_cell("1F", 27, 18), Vector2i.DOWN)
		return
	await _leave_house("front")


## 집을 나간다. 같이 가기로 한 사이인데 곽두철이 옆에 없으면 두고 가는 것이다.
func _leave_house(how: String) -> void:
	if Game.coop and not crook_near(4.0) and crook().active and not crook().is_down():
		await me("곽두철은 지금 옆에 없어.")
		var i := await pick(["그냥 혼자 나간다", "데리러 간다"])
		if i != 0:
			if how == "front":
				play.teleport_player(W().world_cell("1F", 27, 18), Vector2i.DOWN)
			return
		Game.left_behind = true
	elif Game.coop and crook_near(4.0):
		Game.escaped_with_crook = true
	Game.escaped = true
	play.dlg.close()
	Sfx.play("door_open")
	await play.fade(1.0, 0.8)
	play.end_game()


func o_cctv(_p) -> void:
	await narr("CCTV 화면 여러 개가 집 안 곳곳을 비추고 있다.")
	var c: Actor = crook()
	if Game.phase == "play" and c.active and c.mode != "gone":
		var room: String = W().name_of_room(W().room_at(c.cell))
		if room == "":
			room = "복도"
		if c.is_down():
			await narr("%s 화면에 누군가 쓰러져 있다." % room)
		else:
			await narr("%s 화면에 덩치 큰 남자가 보인다." % room)
			if not Game.met:
				await me("누구야, 저 사람... 이 집에 사람이 있었어!", "shock")
	elif c.mode == "gone":
		await narr("아무도 보이지 않는다.")
	if not Game.has("manual") and not Game.flag("manual_taken"):
		await narr("책상 위에 방범 장치 설명서가 있다.")
		Game.setf("manual_taken")
		got("manual")
		await read_doc("manual")


func k_statue(_p) -> void:
	await narr("누군지 모를 사람의 흉상이다. 할아버지를 닮았다.")


# ================================================================ 거실 ====

func o_fireplace(_p) -> void:
	await narr("벽난로에 불씨가 아직 살아 있다.")
	var opts := []
	var acts := []
	if Game.has("knife") and Game.crook_state == "dead" and not Game.kill_clean:
		opts.append("식칼을 불 속에 던진다")
		acts.append("burn")
	if not Game.has("ash") and not Game.has("compact"):
		opts.append("고운 재를 한 줌 챙긴다")
		acts.append("ash")
	opts.append("그만둔다")
	acts.append("none")
	var i := await pick(opts)
	match acts[i]:
		"burn":
			Game.take("knife")
			Game.kill_clean = true
			Sfx.play("wood_hit")
			await narr("칼이 불 속으로 떨어졌다. 손잡이가 금세 까맣게 탄다.")
			await me("...증거는 없다. 없는 거야.", "nervous")
		"ash":
			Game.give("ash")
			Sfx.play("cloth")
			play.toast("벽난로 재 한 줌 챙김", UI.GOLD)
			await me("분가루 대신 쓸 만하겠다.")


func o_photo_family(_p) -> void:
	await narr("가족사진이다. 노부부 사이에 초등학생 남자아이가 서 있다. 아래에 '지훈이 입학식'이라고 적혀 있다.")
	Game.setf("saw_grandson")
	if with_him() and not Game.flag("talk_photo"):
		Game.setf("talk_photo")
		await him("손자 녀석이 할아버지를 쏙 빼닮았네.", "soft")
		await him("...나도 딸이 하나 있다.", "soft")
		var i := await pick(["딸이요?", "(아무 말도 하지 않는다)"])
		if i == 0:
			await him("그 얘긴 나중에 하자. 지금은 나가는 게 먼저야.", "soft")
			affinity(3, "가족사진")


func o_photo_wedding(_p) -> void:
	await narr("흑백 결혼사진이다. 젊은 두 사람이 어색하게 웃고 있다.")
	var i := await pick(["사진 뒤를 본다", "그만둔다"])
	if i == 0:
		await narr("뒷면에 펜으로 적혀 있다. '은혼식 날 다시 꺼내 봤다. 2001년 5월'")
		await me("은혼식이면 결혼 25주년이지.")
		Game.setf("clue_year")


func o_piano(_p) -> void:
	Sfx.play("pluck", -4.0)
	await narr("건반 하나를 눌렀다. 이 한밤중에.")
	await me("미쳤나 봐, 나.", "nervous")
	play.noise_at(play.player.cell, 9.0)


func o_massage_chair(_p) -> void:
	await narr("안마의자다. 등받이에 사람 등 모양으로 눌린 자국이 선명하다.")
	if with_him():
		await him("사흘 동안 거기서 잤다. 그거 진짜 좋다.", "grin")
		var i := await pick(["저도 한번 앉아 봐도 돼요?", "남의 집에서 잘도 주무셨네요."])
		if i == 0:
			await him("나가면 하나 사라. 훔치지 말고.", "grin")
			affinity(5, "안마의자")
		else:
			await him("넌 지금 남의 집에서 뭐 하는데.", "angry")


func o_tv(_p) -> void:
	await narr("텔레비전이 소리 없이 켜져 있다. 뉴스 자막이 흐른다.")
	await play.say("tv", "공개수배 중인 강도상해 피의자 곽두철(47) 씨가 사흘째 행방이 묘연합니다.")
	await play.say("tv", "경찰은 곽 씨가 가평 일대 산속으로 숨어든 것으로 보고 수색을 넓히고 있습니다.")
	Game.setf("saw_news")
	if Game.met:
		Game.setf("crook_named")
	if with_him() and not Game.flag("talk_news"):
		Game.setf("talk_news")
		await him("사진 진짜 못 나왔네. 실물이 백배 낫지 않냐?", "grin")
		var i := await pick(["실물이 훨씬 나아요.", "딱 범죄자 얼굴이네요."])
		if i == 0:
			await him("보는 눈은 있네.", "grin")
			affinity(5, "뉴스")
		else:
			await him("너도 곧 그 얼굴 될 거다.", "angry")
			affinity(-5, "뉴스")
	elif not Game.met:
		await me("곽두철... 무섭게 생겼다. 설마 이 근처에 있는 건 아니겠지.", "nervous")


func k_sofa(_p) -> void:
	await narr("푹신한 소파다. 앉으면 못 일어날 것 같다.")


func k_armchair(_p) -> void:
	await narr("낡은 가죽 안락의자다.")


func k_bookshelf(_p) -> void:
	await narr("책이 빼곡하다. 제목만 봐도 졸리다.")


# ================================================================ 2층 ====

func o_bathtub(p) -> void:
	await _hide_prompt(p, "욕조 커튼 뒤")


func o_med_cabinet(_p) -> void:
	if Game.flag("pills_taken"):
		await narr("약장에 소화제랑 파스만 남았다.")
		return
	await narr("약장 안에 수면제 통이 있다. '남궁현, 자기 전 한 알'이라고 적힌 처방전이 붙어 있다.")
	var i := await pick(["수면제를 챙긴다", "그냥 둔다"])
	if i == 0:
		Game.setf("pills_taken")
		got("pills")
		await me("먹을 거에 타면 모를 거야. ...이런 걸 생각하는 내가 무섭다.", "nervous")


func k_basin(_p) -> void:
	await narr("세면대다. 칫솔 두 개가 나란히 꽂혀 있다.")


func k_toilet(_p) -> void:
	await me("지금 그럴 때가 아니야.")


func o_wardrobe(p) -> void:
	await _hide_prompt(p, "옷장 안")


func o_master_bed(p) -> void:
	await narr("커다란 침대다. 이불이 반듯하게 개어져 있다.")
	await _hide_prompt(p, "침대 밑")


func o_nightstand(_p) -> void:
	if Game.loot.has("watch"):
		await narr("서랍이 비었다.")
		return
	await narr("할아버지 쪽 협탁이다. 서랍 속에 금 회중시계가 들어 있다.")
	await narr("뚜껑 안쪽에 글씨가 새겨져 있다. '1974. 10. 3. 처음 만난 날. 순애가'")
	Game.setf("clue_watch")
	var took := await _steal_prompt("watch", "")
	if took:
		await me("처음 만난 날까지 새겨 뒀네... 좀 미안하다.", "nervous")


func o_vanity(_p) -> void:
	await narr("할머니 화장대다. 거울 앞에 분첩이 놓여 있다.")
	if not Game.has("compact") and not Game.flag("compact_taken"):
		var i := await pick(["분첩을 챙긴다", "그냥 둔다"])
		if i == 0:
			Game.setf("compact_taken")
			got("compact")
	if not Game.flag("memo_taken"):
		await narr("서랍 안에 메모 한 장이 있다.")
		Game.setf("memo_taken")
		got("memo")
		await read_doc("memo")


func o_jewelry_box(_p) -> void:
	if Game.loot.has("necklace"):
		await narr("빈 보석함이다.")
		return
	await narr("자물쇠가 달린 보석함이다.")
	var i := await pick(["자물쇠를 딴다", "그만둔다"])
	if i != 0:
		return
	var ok: bool = await play.lockpick("보석함 자물쇠", 2)
	if not ok:
		return
	await narr("딸깍. 안에 굵은 진주 목걸이가 있다.")
	await _impress_lock()
	await _steal_prompt("necklace", "jewelry_box")


func _impress_lock() -> void:
	if with_him() and not Game.flag("impress_lock"):
		Game.setf("impress_lock")
		await him("오, 손 빠르네.", "grin")
		affinity(5, "자물쇠 따기")


func k_dresser(_p) -> void:
	await narr("서랍장이다. 옷이 가지런하다.")


func k_master_bed(p) -> void:
	await o_master_bed(p)


func o_diary_shelf(_p) -> void:
	if Game.has("diary"):
		await narr("책이 빼곡하다.")
		return
	await narr("책장 한쪽에 손때 묻은 일기장이 꽂혀 있다.")
	got("diary")
	await read_doc("diary")


func o_desk(_p) -> void:
	await narr("묵직한 책상이다. 서랍 하나가 잠겨 있다.")
	var opts := ["잠긴 서랍을 딴다", "그만둔다"]
	if Game.flag("drawer_open"):
		opts[0] = "서랍을 다시 본다"
	var i := await pick(opts)
	if i != 0:
		return
	if not Game.flag("drawer_open"):
		var ok: bool = await play.lockpick("책상 서랍", 1)
		if not ok:
			return
		Game.setf("drawer_open")
		await _impress_lock()
	if Game.loot.has("cash"):
		await narr("서랍이 비었다.")
		return
	await narr("서랍 속에 돈 봉투가 있다. '지훈이 등록금 보탬'이라고 적혀 있다.")
	await _steal_prompt("cash", "")


func o_tape(_p) -> void:
	take_prop("tape")
	got("tape")
	await me("투명 테이프. 뭔가 붙이거나... 떠낼 때 쓰겠지.")


func o_reading_glasses(_p) -> void:
	await narr("할아버지 돋보기안경이다. 알에 지문이 잔뜩 묻어 있다.")
	await _try_fingerprint("돋보기안경")


func o_safe(p) -> void:
	if Game.flag("safe_open"):
		await narr("열린 금고다." + ("" if not Game.loot.has("gold") else " 텅 비었다."))
		if not Game.loot.has("gold"):
			await _steal_prompt("gold", "")
		return
	await narr("금고다. 네 자리 번호판이 달려 있다.")
	var i := await pick(["번호를 누른다", "그만둔다"])
	if i != 0:
		return
	var code: String = await play.enter_code("금고", 4)
	if code == "":
		return
	if code == CODE_SAFE:
		Sfx.play("success")
		Game.setf("safe_open")
		await narr("철컥. 금고 문이 열렸다. 금괴 두 개가 번쩍인다.")
		await _impress_lock()
		await _steal_prompt("gold", "")
	else:
		Sfx.play("buzz")
		await narr("삐. 틀렸다.")


func o_s_statue(p) -> void:
	await k_statue(p)


func o_guest_bed(p) -> void:
	await narr("이불이 엉망이다. 베개에 누가 누웠던 자국이 선명하다.")
	if not Game.met:
		await me("누가 여기서 잤어. 그것도 최근에.", "nervous")
	await _hide_prompt(p, "침대 밑")


func o_ramen(_p) -> void:
	await narr("컵라면 용기가 수북하다. 국물이 아직 촉촉하다.")


func o_newspaper(_p) -> void:
	take_prop("newspaper")
	got("newspaper")
	await read_doc("newspaper")


func o_crook_bag(_p) -> void:
	await narr("낡은 군용 가방이다. 속옷 몇 벌, 컵라면, 그리고 사진 한 장.")
	await narr("교복 입은 여자아이 사진이다. 뒷면에 '수아 중학교 입학'이라고 적혀 있다.")
	Game.setf("saw_daughter")
	if with_him():
		await him("남의 가방은 왜 뒤져.", "angry")
		affinity(-3, "가방")


func o_birthday_card(_p) -> void:
	take_prop("birthday_card")
	got("card")
	await read_doc("card")


# ================================================================ 지하 ====

func k_storage_shelf(_p) -> void:
	await narr("페인트통과 낡은 연장이 쌓여 있다.")


func k_chest(_p) -> void:
	await narr("낡은 궤짝이다. 안에는 오래된 앨범뿐이다.")


func o_crowbar(_p) -> void:
	take_prop("crowbar")
	Game.setf("crowbar_taken")
	got("crowbar")
	await me("빠루다. 문짝 하나쯤은 뜯겠다.")


func o_tool_cabinet(p) -> void:
	if Game.flag("cabinet_open"):
		if Game.flag("jack_taken"):
			await narr("공구함이 비어 있다.")
		else:
			await narr("공구함 안에 자동차 잭이 있다.")
			Game.setf("jack_taken")
			got("jack")
		return
	await narr("자물쇠가 걸린 철제 공구함이다.")
	var opts := ["자물쇠를 딴다", "쇠지렛대로 뜯는다", "그만둔다"]
	var dis := []
	if not Game.has("crowbar"):
		dis.append(1)
	var i := await pick(opts, dis)
	if i == 0:
		var ok: bool = await play.lockpick("공구함 자물쇠", 2)
		if not ok:
			return
	elif i == 1:
		var ok2: bool = await play.work(8.0, "공구함을 뜯는 중")
		play.noise_at(play.player.cell, 12.0)
		if not ok2:
			return
	else:
		return
	Game.setf("cabinet_open")
	W().set_sprite(p, "tool_cabinet_open")
	await narr("공구함이 열렸다. 안에 자동차 잭이 있다.")
	Game.setf("jack_taken")
	got("jack")
	await me("잭이다. 무거운 걸 들어 올릴 때 쓰는 거.")


func cabinet_broken() -> void:
	W().set_sprite(W().obj("tool_cabinet"), "tool_cabinet_broken")


func k_boiler(_p) -> void:
	if Game.has("knife") and Game.crook_state == "dead" and not Game.kill_clean:
		var i := await pick(["식칼을 아궁이에 넣는다", "그만둔다"])
		if i == 0:
			Game.take("knife")
			Game.kill_clean = true
			await narr("칼이 아궁이 속으로 사라졌다.")
		return
	await narr("낡은 보일러가 웅웅거린다.")


func k_coal(_p) -> void:
	await narr("석탄 더미다. 요즘도 이걸 때나?")


func k_bulb(_p) -> void:
	await narr("천장에 매달린 알전구다.")


func o_chute(p) -> void:
	if Game.flag("chute_open"):
		await _climb_chute()
		return
	await narr("벽 위쪽에 석탄을 넣던 구멍이 있다. 굵은 쇠창살이 덮여 있다.")
	if not Game.flag("chute_known"):
		Game.setf("chute_known")
		await me("밖으로 이어진 구멍이다! 방범 장치에는 안 걸려 있을 거야.", "shock")
	await narr("쇠창살을 들어 보았다. 꿈쩍도 하지 않는다. 혼자서는 무리다.")
	var opts := []
	var acts := []
	if Game.coop and crook_near(3.0):
		opts.append("곽두철과 같이 든다")
		acts.append("together")
	if Game.has("jack"):
		opts.append("자동차 잭으로 받친다")
		acts.append("jack")
	opts.append("그만둔다")
	acts.append("none")
	if acts.size() == 1:
		if Game.coop:
			await me("곽두철을 데려와야겠다.")
		else:
			await me("둘이면 모를까. 아니면 뭔가 받칠 게 있으면...")
		return
	var i := await pick(opts)
	match acts[i]:
		"together":
			await _lift_together(p)
		"jack":
			var ok: bool = await play.work(10.0, "잭으로 쇠창살을 받치는 중")
			if not ok:
				return
			Game.take("jack")
			_open_chute(p)
			await narr("잭이 끼익 소리를 내며 쇠창살을 밀어 올렸다. 사람 하나 빠져나갈 틈이 생겼다.")
			await _climb_chute()


func _open_chute(p) -> void:
	Game.setf("chute_open")
	W().set_sprite(p, "chute_open")
	Sfx.play("metal")


func _lift_together(p) -> void:
	await me("하나, 둘, 셋!")
	var ok: bool = await play.work(4.0, "둘이서 쇠창살을 드는 중")
	if not ok:
		return
	_open_chute(p)
	await narr("쇠창살이 들렸다. 곽두철이 어깨로 받치고 선다.")
	await him("내가 먼저 올라가서 끌어 줄게. 받치고 있어.")
	await narr("곽두철이 구멍으로 기어 올라간다.")
	if Game.affinity < Game.BETRAY_LINE:
		await _crook_betrays(p)
		return
	await him("손 잡아!", "grin")
	await narr("굵은 손이 만복을 끌어 올렸다. 차가운 밤공기가 얼굴에 닿는다.")
	Game.escaped = true
	Game.escaped_with_crook = true
	play.dlg.close()
	await play.fade(1.0, 0.8)
	play.end_game()


func _crook_betrays(p) -> void:
	await narr("밖에서 곽두철의 얼굴이 내려다본다. 웃고 있다.")
	await him("미안하다, 좀도둑. 너는 믿을 수가 없어서.", "grin")
	if Game.stole():
		await him("주머니에 든 건 내가 잘 쓸게.", "grin")
		Game.loot = {}
		Game.loot_split = {}
		Game.setf("loot_stolen_back")
	await narr("쇠창살이 쾅 하고 떨어졌다. 곽두철의 발소리가 멀어진다.")
	Sfx.play("shutter")
	W().set_sprite(p, "chute")
	Game.setf("chute_open", false)
	Game.betrayed_by_him = true
	Game.coop = false
	crook().leave()
	Game.crook_state = "escaped"
	await me("...저 인간이!", "shock")
	if not Game.has("jack"):
		await me("다른 길을 찾아야 해. 시간이 없어.", "nervous")


func _climb_chute() -> void:
	var i := await pick(["구멍으로 빠져나간다", "아직 안 나간다"])
	if i != 0:
		return
	await _leave_house("chute")


# ================================================================ 문서 ====

func read_doc(id: String) -> void:
	Sfx.play("page")
	match id:
		"diary":
			Game.setf("read_diary")
			await narr("(일기) 5월 2일. 현관 비밀번호를 또 까먹었다. 할멈이 한숨을 쉬었다.")
			await narr("(일기) 할멈이 이번엔 절대 안 잊을 번호로 바꿨단다. 우리가 부부가 된 날, 여섯 자리.")
			await narr("(일기) 그래도 잊을까 봐 현관 괘종시계를 그날에 맞춰 멈춰 뒀다고 한다. 시계가 멈추니 집이 조용하다.")
			await narr("(일기) 금고 번호는 지훈이 생일로 해 뒀다. 이건 할멈한테도 비밀이다.")
			if Game.flag("clue_clock"):
				await me("괘종시계가 5시 15분에 멈춰 있었어. 그럼 5월 15일?", "shock")
			if Game.flag("read_card"):
				await me("지훈이 생일은 카드에 8월 23일이라고 했지. 금고는 0823?", "smile")
		"memo":
			Game.setf("read_memo")
			await narr("(메모) 영감, 현관 번호 또 잊었지요? 우리 결혼한 날, 여섯 자리예요.")
			await narr("(메모) 달이랑 날은 현관 시계가, 해는 결혼사진이 알려 줄 거예요. 셈은 영감이 좀 해요.")
		"card":
			Game.setf("read_card")
			await narr("(카드) 할아버지 할머니, 자전거 고마워요! 8월 23일 생일 아침에 받은 선물 중에 최고예요. 지훈 올림")
			if Game.flag("read_diary"):
				await me("금고 번호가 지훈이 생일이랬지. 그럼 0823?", "smile")
		"manual":
			Game.setf("read_manual")
			await narr("(설명서) 침입이 감지되면 모든 출입구와 창문이 철제 셔터로 봉쇄되고, 경찰에 자동 신고됩니다.")
			await narr("(설명서) 봉쇄를 풀려면 현관 단말기에 등록된 비밀번호 여섯 자리를 누르거나, 집주인 지문을 대십시오.")
			await narr("(설명서) 비밀번호를 세 번 틀리면 1분 동안 입력이 잠깁니다. 정전이 되어도 셔터는 배터리로 잠긴 채 유지됩니다.")
		"newspaper":
			Game.setf("read_news")
			await narr("(신문, 5월 13일자) 강도상해 피의자 곽두철, 경찰 포위망 뚫고 도주.")
			await narr("(신문) 곽 씨는 불법 사채업자 사무실 세 곳을 털었으며, 마지막 범행에서 경비원 한 명이 크게 다쳤다.")
			if Game.flag("saw_news"):
				Game.setf("crook_named")


func use_item(item: String, action: String) -> void:
	match action:
		"읽는다":
			await read_doc(Items.info(item)["read"])
		"샌드위치에 탄다":
			Game.take("pills")
			Game.take("sandwich")
			Game.give("sandwich_laced")
			Sfx.play("cloth")
			await narr("수면제를 으깨 샌드위치 속에 골고루 넣었다.")
		"위스키에 탄다":
			Game.take("pills")
			Game.take("whiskey")
			Game.give("whiskey_laced")
			Sfx.play("glass")
			await narr("수면제를 위스키에 녹였다. 흔들어 보니 티가 안 난다.")
		"낀다":
			Game.setf("gloves_on")
			Sfx.play("cloth")
			await narr("목장갑을 꼈다.")
		"벗는다":
			Game.setf("gloves_on", false)
			await narr("목장갑을 벗었다.")
	pocket_closed()


# ================================================================ 곽두철 ====

## 곽두철이 다가와 말을 건다 (처음 만남, 또는 계획이 막혀서 다시 제안).
func crook_approaches() -> void:
	if not crook().greeted:
		await first_encounter()
	else:
		await second_offer()


func first_encounter() -> void:
	crook().greeted = true
	Game.met = true
	if Game.flag("saw_news") or Game.flag("read_news"):
		Game.setf("crook_named")
	await him("너 뭐야. 경보 울린 게 너지?", "angry")
	if Game.flag("crook_named"):
		await me("곽두철... 뉴스에 나온 그 사람이잖아.", "shock")
	else:
		await me("누, 누구세요? 이 집 빈집 아니었어요?", "shock")
	await him("묻는 말에나 대답해. 너 때문에 경찰이 온다잖아.", "angry")
	var opts := ["죄송해요. 도둑질하러 왔다가 저도 갇혔어요.", "저요? 이 집 손자인데요.", "경찰 오면 그쪽도 끝이에요. 비켜요."]
	var weapon := ""
	if Game.has("pan"):
		weapon = "pan"
	elif Game.has("crowbar"):
		weapon = "crowbar"
	if weapon != "":
		opts.append("(%s을 휘두른다)" % Items.name_of(weapon))
	var i := await pick(opts)
	var start := 40
	match i:
		0:
			await him("하. 도둑이 들어와서 도둑을 깨웠구먼.", "grin")
			await him("그래도 솔직하니까 봐준다.")
			start = 50
		1:
			await him("웃기지 마. 거실 사진 속 손자는 초등학생이던데.", "angry")
			await me("...요즘 애들이 빨리 크잖아요.", "nervous")
			await him("한 번만 더 거짓말하면 이빨 날아간다.", "angry")
			start = 30
			Game.setf("lied")
		2:
			await him("그래? 그럼 너부터 조용히 시켜 놓고 생각해 볼까.", "angry")
			await me("노, 농담이에요!", "nervous")
			start = 25
		3:
			await _first_strike(weapon)
			return
	Game.affinity = start
	await him("잘 들어. 여기 문은 비밀번호 아니면 집주인 지문이 있어야 열린대. 보안실 설명서에 그렇게 써 있더라.")
	await him("넌 도둑이니까 그런 거 잘 알 거 아냐. 같이 나가자. 대신 딴생각하면 죽는다.")
	var j := await pick(["좋아요. 같이 나가요.", "혼자 할게요."])
	if j == 0:
		await _become_partners()
	else:
		await him("마음대로 해. 대신 내 앞길은 막지 마라.", "angry")
		Game.setf("refused_once")


func _become_partners() -> void:
	Game.coop = true
	Game.coop_ever = true
	Game.setf("crook_named")
	await him("곽두철이다. 뉴스 봤으면 알겠지.")
	await me("오만복이에요.")
	await him("이름 한번 복스럽네. 그 복 좀 나눠 줘 봐라.", "grin")
	await narr("곽두철이 뒤를 따라온다. 말을 걸면 이야기를 나누거나 부탁을 할 수 있다.")
	crook().start_follow()


func second_offer() -> void:
	if Game.hostile:
		return
	await him("야, 도둑. 아까는 내가 좀 험하게 굴었다.")
	if crook().carrying.has("jack") == false and Game.flag("jack_taken"):
		await him("잭은 네가 가져갔지? 좋다. 그럼 둘이서 해 보자.")
	else:
		await him("혼자서는 도저히 안 되겠다. 같이 나가자.")
	var j := await pick(["좋아요. 같이 가요.", "싫어요."])
	if j == 0:
		if Game.affinity < 25:
			Game.affinity = 25
		await _become_partners()
	else:
		await him("그래, 끝까지 혼자 해라.", "angry")
		Game.setf("no_more_offers")


## 계획이 막힌 곽두철이 도둑을 보면 다시 말을 걸지
func wants_to_talk() -> bool:
	return not Game.hostile and not Game.coop and not Game.flag("no_more_offers")


## 처음 만났을 때 먼저 친다.
func _first_strike(weapon: String) -> void:
	Sfx.play("bonk" if weapon == "pan" else "metal", 2.0)
	play.hud.red_flash(1)
	await narr("퍽! %s이 곽두철의 머리를 정통으로 때렸다." % Items.name_of(weapon))
	await him("이, 이 자식이...", "angry")
	crook().knock_down("stunned", 25.0)
	Game.hostile = true
	await narr("곽두철이 머리를 감싸 쥐고 쓰러졌다. 깨어나면 가만두지 않을 것이다.")


## 곽두철에게 말을 건다 (상태에 따라 다르다).
func talk_crook() -> void:
	var c: Actor = crook()
	match Game.crook_state:
		"stunned", "asleep", "tied":
			await _talk_down()
			return
		"dead":
			await narr("...더는 볼 수가 없다.")
			return
	if c.mode in ["chase", "hunt", "search"]:
		return
	if not c.greeted:
		c.greeted = true
		await first_encounter()
		return
	if not Game.coop:
		await _talk_neutral()
		return
	await _talk_partner()


func _talk_neutral() -> void:
	await him("왜. 할 말 있으면 빨리 해.", "angry")
	var opts := ["같이 나가요.", "아무것도 아니에요."]
	var acts := ["join", "none"]
	var w := _blunt_weapon()
	if w != "" and not _facing_me():
		opts.insert(1, "(%s로 뒤통수를 친다)" % Items.name_of(w))
		acts.insert(1, "hit")
	var i := await pick(opts)
	match acts[i]:
		"join":
			if Game.flag("refused_once") and Game.affinity < 20:
				await him("아까는 싫다며. 됐다.", "angry")
				return
			await him("진작 그럴 것이지.", "grin")
			if Game.affinity < 30:
				Game.affinity = 30
			await _become_partners()
		"hit":
			await _hit_from_behind(w)


func _facing_me() -> bool:
	return crook().cell + crook().facing == play.player.cell


func _blunt_weapon() -> String:
	if Game.has("pan"):
		return "pan"
	if Game.has("crowbar"):
		return "crowbar"
	return ""


func _hit_from_behind(w: String) -> void:
	Sfx.play("bonk" if w == "pan" else "metal", 2.0)
	play.hud.red_flash(1)
	await narr("퍽! 곽두철이 앞으로 고꾸라졌다.")
	crook().knock_down("stunned", 30.0)
	Game.hostile = true
	Game.coop = false
	await narr("정신을 잃었다. 30초쯤 지나면 깨어날 것이다.")


func _talk_partner() -> void:
	var c: Actor = crook()
	var opts := ["어떻게 나갈까요?", "당신 얘기 좀 해 봐요.", "이거 드세요.", "여기서 기다려요." if c.mode == "follow" else "따라와요.", "아니에요."]
	var acts := ["how", "story", "give", "wait" if c.mode == "follow" else "follow", "none"]
	var dis := []
	if not (Game.has("sandwich") or Game.has("sandwich_laced") or Game.has("whiskey") or Game.has("whiskey_laced")):
		dis.append(2)
	if Game.count("story") >= 3:
		opts[1] = "(더 들을 얘기가 없다)"
		dis.append(1)
	# 식료품 창고 앞이면 심부름을 시킬 수 있다
	var in_kitchen: bool = W().name_of_room(W().room_at(play.player.cell)) == "주방"
	if in_kitchen and W().obj("pantry_door").state in ["", "open"]:
		opts.insert(4, "식료품 창고 좀 뒤져 봐 줄래요?")
		acts.insert(4, "pantry")
	var w := _blunt_weapon()
	if w != "" and not _facing_me():
		opts.insert(opts.size() - 1, "(%s로 뒤통수를 친다)" % Items.name_of(w))
		acts.insert(acts.size() - 1, "hit")
	var i := await pick(opts, dis)
	match acts[i]:
		"how":
			await _talk_how()
		"story":
			await _talk_story()
		"give":
			await _give_food()
		"wait":
			c.stay()
			await him("그래. 빨리 와라.")
		"follow":
			c.start_follow()
			await him("가자.")
		"pantry":
			await him("라면이라도 남았나 보자.")
			c.go_wait_at(W().world_cell("1F", 11, 5))
		"hit":
			await _hit_from_behind(w)


func _talk_how() -> void:
	await him("현관은 비밀번호 여섯 자리 아니면 집주인 지문이다. 번호는 모르겠고, 지문은 영감이 있어야지.")
	if Game.affinity >= 45 and not Game.flag("chute_told"):
		Game.setf("chute_told")
		Game.setf("chute_known")
		await him("...사실 하나 더 있다. 내가 들어온 길.", "soft")
		await him("지하 보일러실 석탄 구멍. 쇠창살이 무거워서 혼자선 못 들어. 둘이면 된다.")
		await me("그걸 왜 이제 말해요!", "shock")
		await him("널 믿어도 되는지 몰랐으니까.")
	elif Game.flag("chute_told"):
		await him("아니면 지하 석탄 구멍. 둘이서 쇠창살 들면 된다.")
	else:
		await him("넌 도둑이잖아. 네가 머리를 좀 써 봐.")
	if Game.flag("read_diary") or Game.flag("read_memo"):
		await me("비밀번호는 할아버지 할머니가 결혼한 날 같아요.")
		await him("노인네들 결혼기념일을 내가 어떻게 아냐. 찾아봐.")


func _talk_story() -> void:
	var n := Game.bump("story")
	match n:
		1:
			await him("사흘 전에 경찰한테 쫓겨서 이 산까지 올라왔다.")
			await him("마침 노인네 둘이 캐리어를 끌고 나가더라. 여행 간다고.")
			await him("그 뒤로는 이 집 라면이랑 안마의자 덕에 살았지.", "grin")
			var i := await pick(["안마의자 좋죠?", "남의 집에서 사흘이나요?"])
			if i == 0:
				await him("그거 하나는 인정이다.", "grin")
				affinity(5, "이야기 1")
			else:
				await him("넌 지금 남의 집에서 뭐 하는데.", "angry")
		2:
			await him("뉴스에선 강도상해 세 건이라더라. 틀린 말은 아니야.")
			await him("불법 사채업자 사무실만 털었다. 돈 못 갚은 사람들 손가락 부러뜨리던 놈들.")
			await him("마지막 날 경비 하나가 크게 다쳤어. 그건 내가 잘못했다.", "soft")
			var i := await pick(["그래도 사람을 다치게 한 건 잘못이죠.", "나쁜 놈들 돈이었으면 뭐...", "완전 범죄자네요."])
			match i:
				0:
					await him("안다. 그러니까 이러고 사는 거고.", "soft")
					affinity(3, "이야기 2")
				1:
					await him("넌 말이 좀 통하네.", "grin")
					affinity(5, "이야기 2")
				2:
					await him("너는 뭐 성인군자라 남의 집 담 넘었냐.", "angry")
					affinity(-10, "이야기 2")
		3:
			await him("딸이 하나 있다. 수아.", "soft")
			await him("마지막으로 본 게 일곱 살 때였으니까, 지금은 고등학생이겠지.", "soft")
			await him("여기서 빠져나가면 멀리서라도 한 번 보고 싶다. 그다음엔 자수를 하든 말든.", "soft")
			var opts := ["꼭 보러 가요.", "자수부터 하는 게 어때요?", "그 딸은 아빠가 수배범인 거 알아요?"]
			if Game.flag("saw_daughter"):
				opts.insert(1, "가방 속 교복 사진이 수아예요?")
			var i := await pick(opts)
			var a: String = opts[i]
			if a.begins_with("꼭"):
				await him("...그래. 꼭 간다.", "soft")
				affinity(10, "이야기 3")
			elif a.begins_with("가방"):
				await him("봤냐. 중학교 입학식 날 멀리서 찍었다. 그게 마지막이다.", "soft")
				affinity(8, "이야기 3")
			elif a.begins_with("자수"):
				await him("...생각은 해 보마.", "soft")
				affinity(2, "이야기 3")
			else:
				await him("말 조심해라.", "angry")
				affinity(-10, "이야기 3")


func _give_food() -> void:
	var opts := []
	var ids := []
	for id in ["sandwich", "sandwich_laced", "whiskey", "whiskey_laced"]:
		if Game.has(id):
			opts.append(Items.name_of(id))
			ids.append(id)
	opts.append("그만둔다")
	var i := await pick(opts)
	if i >= ids.size():
		return
	var id: String = ids[i]
	Game.take(id)
	if id.begins_with("sandwich"):
		await him("샌드위치? 사흘 동안 라면만 먹었다. 고맙다.", "grin")
		await narr("곽두철이 샌드위치를 세 입 만에 먹어 치웠다.")
		if not Game.flag("fed"):
			Game.setf("fed")
			affinity(10, "샌드위치")
	else:
		await him("캬, 이 영감 좋은 술 마시네.", "grin")
		await narr("곽두철이 위스키를 병째 들이켰다.")
		if not Game.flag("drank"):
			Game.setf("drank")
			affinity(5, "위스키")
	if id.ends_with("_laced"):
		Game.setf("drugged")
		play.get_tree().create_timer(10.0).timeout.connect(_drug_kicks_in)


func _drug_kicks_in() -> void:
	if not is_instance_valid(play):
		return
	var c: Actor = crook()
	if not c.active or c.is_down() or Game.phase != "play":
		return
	c.bark("왜 이렇게... 졸리지...", 2.5)
	await play.get_tree().create_timer(2.5).timeout
	if not is_instance_valid(play) or c.is_down():
		return
	c.knock_down("asleep", 150.0)
	Game.hostile = true
	Game.coop = false
	play.toast("곽두철이 곯아떨어졌다", UI.DIM)


## 쓰러져 있는 곽두철
func _talk_down() -> void:
	var state := Game.crook_state
	match state:
		"stunned":
			await narr("곽두철이 정신을 잃고 쓰러져 있다.")
		"asleep":
			await narr("곽두철이 코를 골며 자고 있다.")
		"tied":
			await narr("곽두철이 빨랫줄에 꽁꽁 묶여 있다.")
			await him("풀어라. 지금 풀면 없던 일로 해 준다.", "angry")
	var opts := []
	var acts := []
	if state != "tied" and Game.has("rope"):
		opts.append("빨랫줄로 묶는다")
		acts.append("tie")
	if not crook().carrying.is_empty():
		opts.append("주머니를 뒤진다")
		acts.append("search")
	if Game.has("knife"):
		opts.append("...식칼로 끝을 낸다")
		acts.append("kill")
	opts.append("그냥 둔다")
	acts.append("none")
	var i := await pick(opts)
	match acts[i]:
		"tie":
			var ok: bool = await play.work(6.0, "빨랫줄로 묶는 중")
			if ok and crook().is_down():
				Game.take("rope")
				crook().knock_down("tied")
				Game.hostile = true
				await narr("손발을 꽁꽁 묶었다. 이제 경찰이 올 때까지 꼼짝 못 한다.")
		"search":
			for it in crook().carrying:
				Game.give(it)
				if it == "crowbar":
					Game.setf("crowbar_taken")
				if it == "jack":
					Game.setf("jack_taken")
				play.toast("%s 챙김" % Items.name_of(it), UI.GOLD)
			crook().carrying.clear()
			Sfx.play("pick")
		"kill":
			await _kill()


func _kill() -> void:
	await narr("손이 덜덜 떨린다. 이건 되돌릴 수 없다.")
	var i := await pick(["...한다", "못 하겠다"])
	if i != 0:
		await me("못 해. 난 좀도둑이지 살인자가 아니야.", "nervous")
		return
	await play.fade(1.0, 0.4)
	Sfx.play("knife")
	await play.get_tree().create_timer(0.8).timeout
	crook().knock_down("dead")
	Game.kill_clean = Game.flag("gloves_on")
	await play.fade(0.0, 0.6)
	await narr("곽두철은 더 이상 움직이지 않는다.")
	if Game.flag("gloves_on"):
		await me("장갑... 장갑을 끼고 있었어. 괜찮아. 괜찮을 거야.", "nervous")
	else:
		await me("칼에... 내 지문이...", "shock")


func crook_woke(was: String) -> void:
	var c: Actor = crook()
	if was == "asleep":
		c.bark("너... 약 탔지!", 2.5)
	else:
		c.bark("너 이 자식, 거기 서!", 2.5)
	Game.hostile = true
	Game.coop = false
	c.start_hunt()
	await play.get_tree().process_frame


func crook_escapes_alone() -> void:
	var same_room: bool = W().room_at(crook().cell) == W().room_at(play.player.cell)
	if same_room:
		await narr("곽두철이 잭으로 쇠창살을 받치고 구멍으로 기어 올라간다.")
		await him("잘 있어라, 좀도둑.")
		await narr("밖에서 잭을 빼 가는 소리와 함께 쇠창살이 쾅 닫혔다.")
	else:
		Sfx.play("shutter", -8.0)
		await narr("저 아래 어딘가에서 쇠붙이가 쾅 닫히는 소리가 났다. 그 뒤로 조용하다.")
	crook().leave()
	Game.crook_state = "escaped"
	Game.setf("crook_escaped")
	Game.setf("jack_gone")


# ================================================================ 숨기, 추격 ====

const HIDE_SPOTS := {
	"wardrobe": {"stand": ["2F", 7, 4], "face": Vector2i.UP},
	"master_bed": {"stand": ["2F", 10, 5], "face": Vector2i.UP},
	"bathtub": {"stand": ["2F", 2, 4], "face": Vector2i.LEFT},
	"guest_bed": {"stand": ["2F", 2, 14], "face": Vector2i.LEFT},
}


func _hide_prompt(p, where: String) -> void:
	if Game.phase != "play":
		return
	var i := await pick(["%s에 숨는다" % where, "그만둔다"])
	if i != 0:
		return
	hide_seen = crook().active and crook().can_see_player()
	play.player.set_hidden(p.id)
	play.hud.show_hidden(true)
	Sfx.play("cloth")


func leave_hiding() -> void:
	play.player.set_hidden("")
	play.hud.show_hidden(false)
	Sfx.play("cloth")
	# 숨어 있는 동안 곽두철이 그 자리에 와 섰으면 옆 칸으로 나온다
	if crook().active and crook().cell == play.player.cell:
		for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if W().passable(play.player.cell + d, play.player):
				play.teleport_player(play.player.cell + d, play.player.facing)
				break
	await play.get_tree().process_frame


func hide_spots_near(c: Vector2i) -> Array:
	var out := []
	var f: String = W().floor_of(c)
	for id in HIDE_SPOTS:
		var s: Dictionary = HIDE_SPOTS[id]
		if s["stand"][0] != f:
			continue
		var stand: Vector2i = W().world_cell(s["stand"][0], s["stand"][1], s["stand"][2])
		if Vector2(stand - c).length() <= 9:
			out.append({"id": id, "stand": stand, "face": s["face"]})
	out.sort_custom(func(a, b): return Vector2(a["stand"] - c).length() < Vector2(b["stand"] - c).length())
	return out


func found_hiding(_spot: String) -> void:
	await him("숨는 거 다 봤다.", "angry")
	play.player.set_hidden("")
	play.hud.show_hidden(false)
	await caught()


func caught() -> void:
	var c: Actor = crook()
	c.catches += 1
	Sfx.play("punch")
	play.hud.red_flash(1)
	if c.catches >= 2:
		await _death_by_crook()
		return
	await him("잡았다, 이 자식!", "angry")
	await narr("곽두철이 멱살을 움켜쥐었다! [Z] 또는 A 버튼을 마구 눌러 뿌리쳐라!")
	play.dlg.close()
	var ok := await _struggle(10, 2.6)
	if ok:
		Sfx.play("punch")
		await narr("정강이를 걷어차고 겨우 빠져나왔다! 다음엔 끝이다.")
		c.knock_down("stunned", 2.0)
	else:
		await _death_by_crook()


func _struggle(presses: int, secs: float) -> bool:
	play.hud.work_begin("뿌리쳐라! [Z] 연타")
	Game.setf("_mash")
	var n := 0
	var t := 0.0
	while t < secs:
		await play.get_tree().process_frame
		t += play.get_process_delta_time()
		if Input.is_action_just_pressed("act"):
			n += 1
			Sfx.play("tick", -8.0)
		play.hud.work_progress(float(n) / presses)
		if n >= presses:
			break
	Game.setf("_mash", false)
	play.hud.work_end()
	return n >= presses


func _death_by_crook() -> void:
	Game.player_dead = true
	Game.death_cause = "crook"
	await him("경찰 오기 전에 입부터 막아야겠다.", "angry")
	await play.fade(1.0, 0.8)
	play.end_game()


# ================================================================ 계단, 덫 ====

func use_stairs(c: Vector2i, st: Array) -> void:
	var l: Array = W().to_local_cell(c)
	if l[0] == "1F" and st[0] == "B1" and Game.flag("stair_oiled"):
		if Game.flag("stair_dark"):
			await play.fade(1.0, 0.2)
			Sfx.play("thud", 3.0)
			await narr("캄캄한 계단 첫 칸에서 발이 쭉 미끄러졌다.")
			await me("아차, 기름...", "shock")
			Game.player_dead = true
			Game.death_cause = "slip"
			play.end_game()
			return
		await narr("기름 부은 곳을 피해 난간을 잡고 조심조심 내려갔다.")
	Sfx.play("step_wood", -6.0)
	await play.fade(1.0, 0.18)
	play.teleport_player(st[1], st[2])
	if Game.coop and crook().mode == "follow":
		var spot: Vector2i = st[1] + Vector2i.DOWN
		if not W().passable(spot, crook()):
			spot = st[1] + Vector2i.RIGHT
		crook().place(spot, Vector2i.DOWN)
	await play.fade(0.0, 0.18)


## 곽두철이 1층에서 지하로 내려가는 순간. 덫에 걸리면 true.
func crook_takes_stairs(c: Vector2i) -> bool:
	var l: Array = W().to_local_cell(c)
	if l[0] != "1F" or l[1].y != 12 or not Game.flag("stair_oiled"):
		return false
	if not Game.flag("stair_dark"):
		if not Game.flag("oil_noticed"):
			Game.setf("oil_noticed")
			crook().bark("누가 계단에 기름을 부었어?", 2.5)
			if Game.coop:
				affinity(-20, "기름")
		return false
	crook().knock_down("dead")
	Game.kill_clean = true
	Game.setf("trap_killed")
	var same_floor: bool = W().floor_of(play.player.cell) == "1F"
	Sfx.play_at("thud", 4.0 if same_floor else 20.0, 30.0, 2.0)
	play.run(func():
		if same_floor:
			await narr("쿵, 쿠당탕. 지하 계단 쪽에서 무거운 것이 굴러떨어지는 소리가 났다.")
			await narr("그리고 조용해졌다.")
		else:
			await narr("아래층에서 쿵 하는 소리가 울렸다.")
		await me("...설마.", "nervous"))
	return true


# ================================================================ 시간 ====

func siren_near() -> void:
	if with_him():
		await narr("멀리서 사이렌 소리가 들린다.")
		await him("젠장, 벌써 왔어? 이러다 둘 다 끝이다!", "angry")
		var i := await pick(["침착해요. 아직 몇 분 있어요.", "우린 끝났어요."])
		if i == 0:
			await him("...그래. 네 말이 맞다.", "soft")
			affinity(5, "사이렌")
		else:
			await him("재수 없는 소리 하지 마!", "angry")
			affinity(-5, "사이렌")
	else:
		await narr("멀리서 사이렌 소리가 들린다. 점점 가까워진다.")
		await me("시간이 없어...", "nervous")


func police_arrive() -> void:
	Sfx.stop_all_loops()
	Sfx.play("yelp", 2.0)
	await narr("사이렌이 집 앞에서 멎었다.")
	await play.say("police", "경찰입니다! 안에 있는 사람, 손 들고 나오세요!")
	await play.fade(1.0, 1.0)
	play.end_game()
