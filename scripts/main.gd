extends Node
## 흐름: 첫 화면 -> 한 판 -> 엔딩 -> (다시 하기 | 엔딩 모음 | 첫 화면). 멈춤 메뉴와 웹 배경 처리.

const PlayScript := preload("res://scripts/play.gd")

var layer: CanvasLayer
var screen: Control
var play: Node
var pause_panel: Control
var _visibility_cb: JavaScriptObject


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(Color(0.05, 0.045, 0.06))
	layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_setup_web()
	show_title()


var _rotate: Control
var _rotate_paused := false


## 휴대폰을 세로로 들면 가로로 돌려 달라고 한다 (그동안 멈춘다).
func _process(_delta: float) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	var s := get_viewport().get_visible_rect().size
	var portrait := s.y > s.x
	if portrait and _rotate == null:
		_rotate = ColorRect.new()
		_rotate.color = Color(0.05, 0.045, 0.06)
		_rotate.set_anchors_preset(Control.PRESET_FULL_RECT)
		var l := UI.label("휴대폰을 가로로 돌려 주세요", UI.BODY, UI.GOLD)
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.grow_vertical = Control.GROW_DIRECTION_BOTH
		_rotate.add_child(l)
		var top := CanvasLayer.new()
		top.layer = 40
		top.add_child(_rotate)
		add_child(top)
		if not get_tree().paused:
			get_tree().paused = true
			_rotate_paused = true
	elif not portrait and _rotate != null:
		_rotate.get_parent().queue_free()
		_rotate = null
		if _rotate_paused and pause_panel == null:
			get_tree().paused = false
		_rotate_paused = false


func _clear_screen() -> void:
	if screen:
		screen.queue_free()
		screen = null


func _new_screen() -> Control:
	_clear_screen()
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.065, 0.09)
	screen.add_child(bg)
	layer.add_child(screen)
	return screen


func _centered(node: Control, y: float) -> void:
	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.offset_top = y
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	if node is Label:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# ---------------------------------------------------------------- 첫 화면 ----

func show_title() -> void:
	Game.phase = "title"
	Engine.max_fps = 30
	Sfx.stop_all_loops()
	Sfx.music("title")
	var s := _new_screen()
	# 달밤의 산자락 별장 (위층 손님방 창에만 불이 켜져 있다)
	var ground := ColorRect.new()
	ground.color = Color(0.06, 0.07, 0.07)
	ground.anchor_top = 0.5
	ground.anchor_right = 1.0
	ground.anchor_bottom = 1.0
	s.add_child(ground)
	var sky := ColorRect.new()
	sky.color = Color(0.055, 0.05, 0.11)
	sky.anchor_right = 1.0
	sky.anchor_bottom = 0.5
	s.add_child(sky)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/title_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED   # 넓은 화면에서도 양옆에 띠가 생기지 않게
	s.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(35, 104)
	col.add_theme_constant_override("separation", 3)
	s.add_child(col)
	col.add_child(UI.outline(UI.label("TWO BADDIES", UI.BIG, UI.GOLD), 5))
	col.add_child(UI.outline(UI.label("두 악당", UI.BODY, UI.TEXT)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	col.add_child(gap)
	col.add_child(UI.outline(UI.label("잠긴 별장에 좀도둑과 수배범.", UI.SMALL, Color(0.86, 0.84, 0.8), true)))
	col.add_child(UI.outline(UI.label("경찰이 오기까지 20분.", UI.SMALL, Color(0.86, 0.84, 0.8), true)))
	var opts := ["새로 시작", "엔딩 모음 (%d / %d)" % [Game.endings.size(), Endings.ORDER.size()], "소리 설정"]
	var m := UI.Menu.new()
	m.setup(opts, false)
	m.position = Vector2(32, 222)
	for l in m.labels:
		UI.outline(l)
	s.add_child(m)
	var foot := UI.outline(UI.label("기획 이서연   그림 VARCO, 소리 Kenney 외", UI.SMALL, Color(0.7, 0.68, 0.66), true))
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_left = 35
	foot.offset_top = -24
	s.add_child(foot)
	var i: int = await m.picked
	match i:
		0:
			_ask_start()
		1:
			show_gallery()
		2:
			await _sound_settings(s)
			show_title()


func _ask_start() -> void:
	if not Game.prologue_done:
		start_run(false)
		return
	var s := _new_screen()
	var q := UI.label("어디서부터 시작할까요?", UI.BODY)
	_centered(q, 120)
	s.add_child(q)
	var m := UI.Menu.new()
	m.setup(["경보가 울리는 순간부터", "잠입 연습부터 (조작 배우기)"], true)
	_centered(m, 155)
	m.offset_left = -120
	s.add_child(m)
	m.cancelled.connect(show_title)
	var i: int = await m.picked
	start_run(i == 0)


func start_run(skip_prologue: bool) -> void:
	_clear_screen()
	if play:
		play.queue_free()
	Engine.max_fps = 60
	Sfx.music("")
	play = PlayScript.new()
	play.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(play)
	play.finished.connect(_on_finished)
	play.setup(skip_prologue)


# ---------------------------------------------------------------- 엔딩 ----

func _on_finished(id: String) -> void:
	await get_tree().create_timer(0.6).timeout
	var fresh := Game.record_ending(id)
	if play:
		play.queue_free()
		play = null
	show_ending(id, fresh)


func show_ending(id: String, fresh: bool) -> void:
	Engine.max_fps = 30
	var tone := Endings.tone(id)
	Sfx.music("title" if tone != "bad" else "")
	Sfx.play({"good": "jingle_sax_a", "mid": "jingle_steel", "bad": "jingle_bad"}[tone])
	var s := _new_screen()
	var num := UI.label("엔딩 %d / %d%s" % [Endings.number(id), Endings.ORDER.size(), "   새로 찾음!" if fresh else ""], UI.SMALL, UI.GOLD if fresh else UI.DIM, true)
	_centered(num, 24)
	s.add_child(num)
	var col: Color = {"good": UI.GOLD, "mid": UI.BLUE, "bad": UI.RED}[tone]
	var title := UI.outline(UI.label(Endings.TITLE[id], UI.BIG, col), 5)
	_centered(title, 44)
	s.add_child(title)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -267
	box.offset_right = 267
	box.offset_top = 99
	s.add_child(box)
	var skip := [false]
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			skip[0] = true)
	s.add_child(catcher)
	for line in Endings.lines(id):
		var r := UI.rich(UI.BODY)
		r.text = line
		r.fit_content = true
		r.custom_minimum_size = Vector2(534, 0)
		r.modulate.a = 0.0
		box.add_child(r)
		var tw := create_tween()
		tw.tween_property(r, "modulate:a", 1.0, 0.6)
		var waited := 0.0
		while waited < 1.6 and not skip[0]:
			await get_tree().process_frame
			waited += get_process_delta_time()
			if Input.is_action_just_pressed("act"):
				skip[0] = true
		r.modulate.a = 1.0
	catcher.queue_free()
	var stats := UI.label(_stats_line(), UI.SMALL, UI.DIM, true)
	stats.anchor_top = 1.0
	stats.anchor_bottom = 1.0
	_centered(stats, -83)
	stats.anchor_top = 1.0
	s.add_child(stats)
	var m := UI.Menu.new()
	m.setup(["다시 하기", "엔딩 모음", "첫 화면"], false)
	m.anchor_top = 1.0
	m.anchor_bottom = 1.0
	m.anchor_left = 0.5
	m.offset_left = -53
	m.offset_top = -61
	s.add_child(m)
	var i: int = await m.picked
	match i:
		0:
			start_run(true)
		1:
			show_gallery()
		2:
			show_title()


func _stats_line() -> String:
	var parts := []
	parts.append("탈출 성공" if Game.escaped else "탈출 실패")
	if Game.met:
		parts.append("곽두철과 %s" % Game.relation_text())
	parts.append("훔친 것 %s" % (Endings.money(Game.loot_total()) if Game.stole() else "없음"))
	parts.append("끝난 시각 %s" % Game.clock_text())
	return "   ".join(parts)


# ---------------------------------------------------------------- 엔딩 모음 ----

func show_gallery() -> void:
	Engine.max_fps = 30
	var s := _new_screen()
	var t := UI.label("엔딩 모음  %d / %d" % [Game.endings.size(), Endings.ORDER.size()], UI.BODY, UI.GOLD)
	t.position = Vector2(21, 13)
	s.add_child(t)
	var names := []
	for i in Endings.ORDER.size():
		var id: String = Endings.ORDER[i]
		names.append("%02d  %s" % [i + 1, Endings.TITLE[id] if Game.endings.has(id) else "???"])
	var m := UI.Menu.new()
	m.font_size = UI.BODY
	m.setup(names, true)
	m.position = Vector2(19, 40)
	m.add_theme_constant_override("separation", 0)
	s.add_child(m)
	var detail := UI.rich(UI.BODY)
	detail.anchor_left = 0.5
	detail.anchor_right = 1.0
	detail.offset_left = 13
	detail.offset_right = -21
	detail.offset_top = 53
	detail.offset_bottom = 293
	s.add_child(detail)
	var help := UI.label("[X] 돌아가기", UI.SMALL, UI.DIM, true)
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 21
	help.offset_top = -24
	s.add_child(help)
	var upd := func():
		var id: String = Endings.ORDER[m.index]
		if Game.endings.has(id):
			var ls: Array = Endings.lines(id)
			detail.text = "[color=#eec76b]%s[/color]\n\n%s" % [Endings.TITLE[id], ls[0] if ls.size() > 0 else ""]
		else:
			detail.text = "[color=#a8a095]아직 못 본 엔딩\n\n귀띔: %s...[/color]" % Endings.HINT[id]
	upd.call()
	var poll := Timer.new()
	poll.wait_time = 0.05
	poll.autostart = true
	poll.timeout.connect(upd)
	s.add_child(poll)
	await m.cancelled
	show_title()


# ---------------------------------------------------------------- 소리 설정 ----

func _sound_settings(parent: Control) -> void:
	var p := UI.panel(Rect2())
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -147
	p.offset_right = 147
	p.offset_top = -67
	p.offset_bottom = 75
	parent.add_child(p)
	var buses := ["Master", "Music", "SFX"]
	var names := {"Master": "전체", "Music": "음악", "SFX": "효과음"}
	var rows: Array[Label] = []
	for i in 3:
		var l := UI.label("", UI.BODY)
		l.position = Vector2(16, 13 + i * 27)
		p.add_child(l)
		rows.append(l)
	var help := UI.label("위아래로 고르고 좌우로 조절, [X] 닫기", UI.SMALL, UI.DIM, true)
	help.position = Vector2(16, 104)
	p.add_child(help)
	var sel := [0]
	var draw := func():
		for i in 3:
			var v: float = Game.volumes[buses[i]]
			var bars := ""
			for k in 10:
				bars += "■" if k < roundi(v * 10) else "□"
			rows[i].text = ("▶ " if i == sel[0] else "   ") + "%s  %s" % [names[buses[i]], bars]
			rows[i].add_theme_color_override("font_color", UI.GOLD if i == sel[0] else UI.TEXT)
	draw.call()
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("up"):
			sel[0] = (sel[0] + 2) % 3
		elif Input.is_action_just_pressed("down"):
			sel[0] = (sel[0] + 1) % 3
		elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
			var b: String = buses[sel[0]]
			var d := -0.1 if Input.is_action_just_pressed("left") else 0.1
			Game.volumes[b] = clampf(snappedf(Game.volumes[b] + d, 0.1), 0.0, 1.0)
			Sfx.set_volume(b, Game.volumes[b])
			Sfx.play("tick", -6.0)
		elif Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
			break
		else:
			continue
		draw.call()
	Game.save()
	p.queue_free()


# ---------------------------------------------------------------- 멈춤 ----

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") and play and Game.phase in ["play", "prologue"] and pause_panel == null:
		get_viewport().set_input_as_handled()
		_open_pause()


func _open_pause() -> void:
	get_tree().paused = true
	Engine.max_fps = 30
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	pause_panel.add_child(dim)
	layer.add_child(pause_panel)
	var box := UI.panel(Rect2())
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -93
	box.offset_right = 93
	box.offset_top = -69
	box.offset_bottom = 59
	pause_panel.add_child(box)
	var t := UI.label("멈춤", UI.BODY, UI.GOLD)
	t.position = Vector2(16, 11)
	box.add_child(t)
	var m := UI.Menu.new()
	m.setup(["계속하기", "소리 설정", "첫 화면으로"], true)
	m.position = Vector2(16, 40)
	box.add_child(m)
	m.cancelled.connect(func():
		m.picked.emit(0))
	var i: int = await m.picked
	match i:
		1:
			m.visible = false
			await _sound_settings(pause_panel)
			pause_panel.queue_free()
			pause_panel = null
			_open_pause()
			return
		2:
			pause_panel.queue_free()
			pause_panel = null
			get_tree().paused = false
			if play:
				play.queue_free()
				play = null
			Game.phase = "title"
			show_title()
			return
	pause_panel.queue_free()
	pause_panel = null
	get_tree().paused = false
	Engine.max_fps = 60


# ---------------------------------------------------------------- 웹 ----

## 브라우저에서 탭을 숨기면 게임, 소리, 그리기를 모두 멈춘다 (휴대폰 배터리).
func _setup_web() -> void:
	if not OS.has_feature("web"):
		return
	_visibility_cb = JavaScriptBridge.create_callback(_on_visibility_change)
	var document := JavaScriptBridge.get_interface("document")
	document.addEventListener("visibilitychange", _visibility_cb)
	if OS.is_debug_build():
		# 디버그 빌드: window.gdShot('이름') 으로 지금 화면을 미리보기 서버에 보낸다 (tools/serve.py)
		_shot_cb = JavaScriptBridge.create_callback(_on_shot)
		JavaScriptBridge.get_interface("window").gdShot = _shot_cb
		# window.gdCmd('명령') 으로 시험용 조작 (tools/webdrive.py)
		_cmd_cb = JavaScriptBridge.create_callback(_on_cmd)
		JavaScriptBridge.get_interface("window").gdCmd = _cmd_cb


var _shot_cb: JavaScriptObject
var _cmd_cb: JavaScriptObject


func _on_cmd(args: Array) -> void:
	var parts := str(args[0]).split(" ")
	var w: World = play.world if play else null
	match parts[0]:
		"skip":
			start_run(true)
		"start":
			start_run(false)
		"tp":
			play.teleport_player(w.world_cell(parts[1], int(parts[2]), int(parts[3])), Vector2i.DOWN)
		"face":
			play.player.face({"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}[parts[1]])
		"give":
			Game.give(parts[1])
		"steal":
			Game.steal(parts[1], Items.value(parts[1]))
		"flag":
			Game.setf(parts[1])
		"time":
			Game.t = float(parts[1])
		"crook":
			play.crook.active = true
			play.crook.place(w.world_cell(parts[1], int(parts[2]), int(parts[3])), Vector2i.DOWN)
		"coop":
			Game.met = true
			Game.coop = true
			Game.coop_ever = true
			Game.setf("crook_named")
			play.crook.greeted = true
			play.crook.active = true
			play.crook.start_follow()
		"hostile":
			Game.met = true
			Game.hostile = true
			play.crook.greeted = true
			play.crook.start_hunt()
		"ending":
			if play:
				play.queue_free()
				play = null
			show_ending(parts[1], true)
		"gallery":
			show_gallery()
		"memo":
			# 메모장에 적힌 글을 window.__memo 로 꺼내 본다 (한글 입력 시험)
			JavaScriptBridge.eval("window.__memo = %s" % JSON.stringify(Game.memo))


func _on_shot(args: Array) -> void:
	var name := str(args[0]) if args.size() > 0 else "shot"
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var b64 := Marshalls.raw_to_base64(img.save_png_to_buffer())
	JavaScriptBridge.eval("fetch('/shot/%s', {method: 'POST', body: '%s'})" % [name, b64])


func _on_visibility_change(_args: Array) -> void:
	var hidden := bool(JavaScriptBridge.eval("document.hidden", true))
	if hidden:
		AudioServer.set_bus_mute(0, true)
		Engine.max_fps = 5
		if play and Game.phase in ["play", "prologue"] and pause_panel == null:
			_open_pause()
		else:
			get_tree().paused = true
	else:
		Sfx.set_volume("Master", Game.volumes["Master"])
		if pause_panel == null:
			get_tree().paused = false
		Engine.max_fps = 30 if pause_panel != null or play == null else 60
