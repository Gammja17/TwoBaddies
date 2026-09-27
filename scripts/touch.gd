extends Node2D
## 휴대폰용 화면 버튼: 왼쪽 방향 패드, 오른쪽 A(조사) B(뛰기, 취소), 위쪽 주머니와 멈춤.
## 터치 화면에서만 보인다.

var _buttons: Dictionary = {}


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		visible = false
		set_process(false)
		return
	var r := 17
	for a in ["up", "down", "left", "right"]:
		_add(a, r, _arrow(a))
	_add("act", 21, "A")
	_add("run", 17, "B")
	_add("menu", 14, "주머니", true)
	_add("pause", 12, "II", true)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _add(action: String, r: int, text: String, small := false) -> void:
	var b := TouchScreenButton.new()
	b.texture_normal = UI.circle_tex(r, Color(0.1, 0.09, 0.12, 0.45), Color(0.9, 0.85, 0.75, 0.55))
	b.texture_pressed = UI.circle_tex(r, Color(0.9, 0.78, 0.42, 0.55), Color(1, 0.95, 0.8, 0.8))
	b.action = action
	b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	b.passby_press = action in ["up", "down", "left", "right"]
	var l := UI.outline(UI.label(text, 10 if small else 12, UI.TEXT, small))
	l.size = Vector2(r * 2, r * 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	add_child(b)
	_buttons[action] = [b, r]
	if action == "run":
		# B 는 걸을 때는 뛰기, 메뉴에서는 취소
		b.pressed.connect(func(): _inject("cancel", true))
		b.released.connect(func(): _inject("cancel", false))


func _inject(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


## 대화창이나 메뉴가 떠 있으면 버튼을 숨긴다 (대화창을 누르면 넘어가고, 선택지는 눌러서 고른다).
func _process(_delta: float) -> void:
	var talking := Game.busy > 0
	for a in _buttons:
		if a != "pause":
			_buttons[a][0].visible = not talking or (a == "act" and Game.flag("_mash"))


func _arrow(a: String) -> String:
	return {"up": "▲", "down": "▼", "left": "◀", "right": "▶"}[a]


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var cx := 52.0
	var cy := s.y - 52.0
	var gap := 30.0
	_place("up", cx, cy - gap)
	_place("down", cx, cy + gap)
	_place("left", cx - gap, cy)
	_place("right", cx + gap, cy)
	_place("act", s.x - 34, s.y - 60)
	_place("run", s.x - 78, s.y - 34)
	_place("menu", s.x - 58, 22)
	_place("pause", s.x - 22, 22)


func _place(action: String, x: float, y: float) -> void:
	var b: TouchScreenButton = _buttons[action][0]
	var r: int = _buttons[action][1]
	b.position = Vector2(x - r, y - r)
