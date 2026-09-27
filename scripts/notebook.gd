extends Control
## 수첩: 눈여겨본 단서가 적힌다.

signal closed

var _body: RichTextLabel
var _active := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## lines: [[제목, 내용], ...] 적은 차례대로
func open(lines: Array) -> void:
	if Game.test_mode:
		Game.test_log.append("[수첩] %d줄" % lines.size())
		return
	for c in get_children():
		c.queue_free()
	var p := UI.panel(Rect2())
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -210
	p.offset_right = 210
	p.offset_top = -118
	p.offset_bottom = 110
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(p)
	var title := UI.label("만복의 수첩", 12, UI.GOLD)
	title.position = Vector2(10, 5)
	p.add_child(title)
	var close_btn := UI.label("닫기", 12, UI.GOLD)
	close_btn.position = Vector2(376, 4)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_close())
	p.add_child(close_btn)
	_body = UI.rich(12)
	_body.position = Vector2(10, 26)
	_body.size = Vector2(400, 176)
	_body.scroll_active = true
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	var parts := []
	for l in lines:
		parts.append("[color=#eec76b]%s[/color]\n%s" % [l[0], l[1]])
	_body.text = "\n\n".join(parts) if parts.size() > 0 else "[color=#a8a095]아직 적은 게 없다. 눈여겨볼 만한 걸 보면 여기 적는다.[/color]"
	p.add_child(_body)
	var help := UI.label("[위아래] 넘기기   [X] 닫기", 10, UI.DIM, true)
	help.position = Vector2(10, 206)
	p.add_child(help)
	visible = true
	_active = true
	await closed
	visible = false


func _close() -> void:
	if not _active:
		return
	_active = false
	Sfx.play("ui_close", -6.0)
	closed.emit()


func _unhandled_input(ev: InputEvent) -> void:
	if not _active:
		return
	var bar := _body.get_v_scroll_bar()
	if ev.is_action_pressed("up"):
		bar.value -= 30
	elif ev.is_action_pressed("down"):
		bar.value += 30
	elif ev.is_action_pressed("cancel") or ev.is_action_pressed("menu") or ev.is_action_pressed("act"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()
