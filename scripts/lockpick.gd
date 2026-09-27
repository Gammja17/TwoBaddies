extends Control
## 자물쇠 따기: 오가는 바늘이 초록 칸에 왔을 때 누르면 핀 하나가 걸린다.
## 헛누르면 딸깍 소리가 나고 (가까이 있는 사람이 들을 수 있다) 칸이 다른 자리로 옮겨 간다.

signal done(ok: bool)
signal slipped

var pins := 3
var zone_w := 0.22
var speed := 0.9
var _set := 0
var _pos := 0.0
var _dir := 1.0
var _zone := 0.5
var _active := false
var _panel: Panel
var _bar: ColorRect
var _zone_rect: ColorRect
var _needle: ColorRect
var _pin_rects: Array[ColorRect] = []
var _title: Label
var _help: Label
var _flash := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(title: String, difficulty: int, tutorial := false) -> bool:
	if Game.test_mode:
		Game.test_log.append("  (자물쇠: %s -> %s)" % [title, Game.test_lockpick])
		return Game.test_lockpick
	for c in get_children():
		c.queue_free()
	_pin_rects.clear()
	pins = [2, 3, 3, 4][clampi(difficulty, 0, 3)]
	zone_w = [0.30, 0.24, 0.18, 0.15][clampi(difficulty, 0, 3)]
	speed = [0.65, 0.85, 1.05, 1.25][clampi(difficulty, 0, 3)]
	_panel = UI.panel(Rect2())
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -120
	_panel.offset_right = 120
	_panel.offset_top = -62
	_panel.offset_bottom = 62
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_press())
	add_child(_panel)
	_title = UI.label(title, 12, UI.GOLD)
	_title.position = Vector2(10, 5)
	_panel.add_child(_title)
	# 자물쇠 몸통과 핀
	var body := ColorRect.new()
	body.color = Color(0.55, 0.47, 0.30)
	body.position = Vector2(20, 26)
	body.size = Vector2(200, 26)
	_panel.add_child(body)
	for i in pins:
		var r := ColorRect.new()
		r.color = Color(0.25, 0.22, 0.2)
		r.size = Vector2(10, 14)
		r.position = Vector2(20 + (i + 1) * 200.0 / (pins + 1) - 5, 32)
		_panel.add_child(r)
		_pin_rects.append(r)
	_bar = ColorRect.new()
	_bar.color = UI.INNER
	_bar.position = Vector2(20, 62)
	_bar.size = Vector2(200, 10)
	_panel.add_child(_bar)
	_zone_rect = ColorRect.new()
	_zone_rect.color = Color(0.36, 0.66, 0.40)
	_zone_rect.size = Vector2(200 * zone_w, 10)
	_bar.add_child(_zone_rect)
	_needle = ColorRect.new()
	_needle.color = Color(0.96, 0.92, 0.82)
	_needle.size = Vector2(2, 16)
	_needle.position.y = -3
	_bar.add_child(_needle)
	_help = UI.label("", 10, UI.DIM, true)
	_help.position = Vector2(10, 80)
	_help.text = "바늘이 초록 칸 안에 들어왔을 때 [Z] 또는 판 누르기" if tutorial else "초록 칸에서 [Z] 또는 판 누르기"
	_panel.add_child(_help)
	var quit := UI.label("그만두기", 10, UI.GOLD, true)
	quit.position = Vector2(180, 100)
	quit.mouse_filter = Control.MOUSE_FILTER_STOP
	quit.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			if _active:
				_active = false
				Sfx.play("ui_back")
				done.emit(false))
	_panel.add_child(quit)
	_set = 0
	_pos = 0.0
	_dir = 1.0
	_new_zone()
	visible = true
	_active = true
	var ok: bool = await done
	visible = false
	return ok


func _new_zone() -> void:
	_zone = randf_range(0.1, 0.9 - zone_w)
	_zone_rect.position.x = 200 * _zone


func _process(delta: float) -> void:
	if not _active:
		return
	_pos += _dir * speed * delta
	if _pos > 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos < 0.0:
		_pos = 0.0
		_dir = 1.0
	_needle.position.x = 200 * _pos - 1
	if _flash > 0.0:
		_flash -= delta
		_bar.color = UI.RED.darkened(0.4) if _flash > 0.0 else UI.INNER


func _press() -> void:
	if not _active:
		return
	if _pos >= _zone and _pos <= _zone + zone_w:
		_pin_rects[_set].color = UI.GOLD
		_set += 1
		Sfx.play("lock_click")
		if _set >= pins:
			_active = false
			Sfx.play("latch")
			await get_tree().create_timer(0.35).timeout
			done.emit(true)
			return
		_new_zone()
	else:
		Sfx.play("scratch", -2.0)
		_flash = 0.25
		slipped.emit()
		_new_zone()


func _unhandled_input(ev: InputEvent) -> void:
	if not _active:
		return
	if ev.is_action_pressed("act"):
		get_viewport().set_input_as_handled()
		_press()
	elif ev.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_active = false
		Sfx.play("ui_back")
		done.emit(false)
