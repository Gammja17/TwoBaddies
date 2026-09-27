extends Control
## 번호판 (현관 6자리, 금고 4자리). 방향키로 고르거나 숫자 키, 화면 누르기.

signal done(code: String)

const KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "지움", "0", "확인"]

var digits := 6
var _code := ""
var _sel := 0
var _active := false
var _display: Label
var _buttons: Array[Label] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(title: String, n: int) -> String:
	if Game.test_mode:
		var code: String = Game.test_codes.pop_front() if Game.test_codes.size() > 0 else ""
		Game.test_log.append("  (번호판 %s: %s)" % [title, code])
		return code
	for c in get_children():
		c.queue_free()
	_buttons.clear()
	digits = n
	_code = ""
	_sel = 0
	var p := UI.panel(Rect2())
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -104
	p.offset_right = 104
	p.offset_top = -133
	p.offset_bottom = 128
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(p)
	var t := UI.label(title, UI.BODY, UI.GOLD)
	t.position = Vector2(13, 7)
	p.add_child(t)
	var screen := ColorRect.new()
	screen.color = Color(0.11, 0.17, 0.14)
	screen.position = Vector2(13, 32)
	screen.size = Vector2(182, 29)
	p.add_child(screen)
	_display = UI.label("", UI.BODY, Color(0.55, 0.9, 0.6))
	_display.position = Vector2(24, 37)
	p.add_child(_display)
	for i in KEYS.size():
		var l := UI.label(KEYS[i], UI.BODY)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(56, 35)
		l.position = Vector2(13 + (i % 3) * 61, 72 + (i / 3) * 40)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		var bg := StyleBoxFlat.new()
		bg.bg_color = UI.INNER
		bg.border_color = UI.EDGE
		bg.set_border_width_all(1)
		l.add_theme_stylebox_override("normal", bg)
		var idx := i
		l.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				_sel = idx
				_refresh()
				_press(KEYS[idx]))
		p.add_child(l)
		_buttons.append(l)
	var help := UI.label("[X] 닫기", UI.SMALL, UI.GOLD, true)
	help.position = Vector2(13, 236)
	help.mouse_filter = Control.MOUSE_FILTER_STOP
	help.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			if _active:
				_active = false
				Sfx.play("ui_back")
				done.emit(""))
	p.add_child(help)
	_refresh()
	visible = true
	_active = true
	var code: String = await done
	visible = false
	return code


func _refresh() -> void:
	var s := ""
	for i in digits:
		s += (_code[i] if i < _code.length() else "_") + " "
	_display.text = s.strip_edges()
	for i in _buttons.size():
		_buttons[i].add_theme_color_override("font_color", UI.GOLD if i == _sel else UI.TEXT)
		var sb: StyleBoxFlat = _buttons[i].get_theme_stylebox("normal")
		sb.border_color = UI.GOLD if i == _sel else UI.EDGE


func _press(k: String) -> void:
	if not _active:
		return
	if k == "지움":
		_code = _code.substr(0, max(0, _code.length() - 1))
		Sfx.play("beep", -6.0, 0.8)
	elif k == "확인":
		if _code.length() == digits:
			_active = false
			done.emit(_code)
			return
		Sfx.play("buzz", -8.0)
	elif _code.length() < digits:
		_code += k
		Sfx.play("beep", -6.0)
	_refresh()


func _unhandled_input(ev: InputEvent) -> void:
	if not _active:
		return
	var handled := true
	if ev.is_action_pressed("left"):
		_sel = (_sel + 11) % 12
	elif ev.is_action_pressed("right"):
		_sel = (_sel + 1) % 12
	elif ev.is_action_pressed("up"):
		_sel = (_sel + 9) % 12
	elif ev.is_action_pressed("down"):
		_sel = (_sel + 3) % 12
	elif ev.is_action_pressed("act"):
		_press(KEYS[_sel])
	elif ev.is_action_pressed("cancel"):
		_active = false
		Sfx.play("ui_back")
		done.emit("")
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var code: int = ev.physical_keycode
		if code >= KEY_0 and code <= KEY_9:
			_press(str(code - KEY_0))
		elif code >= KEY_KP_0 and code <= KEY_KP_9:
			_press(str(code - KEY_KP_0))
		else:
			handled = false
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh()
