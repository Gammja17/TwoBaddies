extends Control
## 메모장: 플레이어가 직접 적는다. 판이 끝나면 지워진다.

signal closed

const PAPER := Color(0.93, 0.89, 0.78)
const INK := Color(0.22, 0.18, 0.17)

var _edit: TextEdit
var _active := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open() -> void:
	if Game.test_mode:
		Game.test_log.append("[메모장] %d자" % Game.memo.length())
		return
	for c in get_children():
		c.queue_free()
	var p := UI.panel(Rect2())
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -220
	p.offset_right = 220
	p.offset_top = -140
	p.offset_bottom = 130
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(p)
	var title := UI.label("메모장", UI.BODY, UI.GOLD)
	title.position = Vector2(13, 7)
	p.add_child(title)
	var close_btn := UI.label("닫기", UI.BODY, UI.GOLD)
	close_btn.position = Vector2(395, 7)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_close())
	p.add_child(close_btn)
	_edit = TextEdit.new()
	_edit.position = Vector2(13, 34)
	_edit.size = Vector2(414, 208)
	_edit.text = Game.memo
	_edit.placeholder_text = "여기에 적어 두세요. 이번 판이 끝나면 지워져요."
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.add_theme_font_override("font", Art.font_main)
	_edit.add_theme_font_size_override("font_size", UI.BODY)
	_edit.add_theme_color_override("font_color", INK)
	_edit.add_theme_color_override("font_placeholder_color", INK * Color(1, 1, 1, 0.45))
	_edit.add_theme_color_override("caret_color", INK)
	_edit.add_theme_color_override("selection_color", Color(0.85, 0.72, 0.45, 0.6))
	_edit.add_theme_constant_override("line_spacing", 4)
	_edit.add_theme_stylebox_override("normal", _paper(UI.EDGE))
	_edit.add_theme_stylebox_override("focus", _paper(UI.GOLD))
	_edit.text_changed.connect(func(): Game.memo = _edit.text)
	p.add_child(_edit)
	var help := UI.label("[Esc] 닫기", UI.SMALL, UI.DIM, true)
	help.position = Vector2(13, 249)
	p.add_child(help)
	visible = true
	_active = true
	# 휴대폰은 눌러야 자판이 뜨게 둔다 (열자마자 화면을 가리지 않게)
	if not DisplayServer.is_touchscreen_available():
		_edit.grab_focus()
	await closed
	visible = false


func _paper(edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_content_margin_all(8)
	return sb


func _close() -> void:
	if not _active:
		return
	_active = false
	_edit.release_focus()
	Sfx.play("ui_close", -6.0)
	closed.emit()


## 적는 중에는 Z, X 가 글자로 들어가니 Esc 로 닫는다.
func _input(ev: InputEvent) -> void:
	if _active and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()


func _unhandled_input(ev: InputEvent) -> void:
	if not _active or _edit.has_focus():
		return
	if ev.is_action_pressed("cancel") or ev.is_action_pressed("menu") or ev.is_action_pressed("memo"):
		get_viewport().set_input_as_handled()
		_close()
