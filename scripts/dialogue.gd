extends Control
## 아래쪽 대화창: 얼굴, 이름표, 한 글자씩 나오는 글, 선택지.

signal _next

const CPS := 42.0     # 초당 글자 수

var box: Panel
var portrait: TextureRect
var name_tag: Panel
var name_label: Label
var text: RichTextLabel
var arrow: Label
var choice_panel: Panel
var menu: UI.Menu
var _typing := false
var _shown := 0.0
var _total := 0
var _waiting := false
var _blink := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box = UI.panel(Rect2())
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = -78
	box.offset_bottom = -6
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.gui_input.connect(_on_box_input)
	add_child(box)
	portrait = TextureRect.new()
	portrait.position = Vector2(6, 4)
	portrait.size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(portrait)
	text = UI.rich(12)
	text.anchor_right = 1.0
	text.offset_left = 78
	text.offset_top = 7
	text.offset_right = -14
	text.offset_bottom = 67
	box.add_child(text)
	arrow = UI.label("▼", 10, UI.GOLD, true)
	arrow.anchor_left = 1.0
	arrow.anchor_right = 1.0
	arrow.anchor_top = 1.0
	arrow.anchor_bottom = 1.0
	arrow.offset_left = -16
	arrow.offset_top = -16
	box.add_child(arrow)
	name_tag = UI.panel(Rect2(0, 0, 90, 17))
	name_tag.anchor_top = 1.0
	name_tag.anchor_bottom = 1.0
	name_tag.offset_top = -95
	name_tag.offset_bottom = -78
	add_child(name_tag)
	name_label = UI.label("", 12)
	name_label.position = Vector2(6, 1)
	name_tag.add_child(name_label)
	choice_panel = UI.panel(Rect2())
	choice_panel.anchor_left = 1.0
	choice_panel.anchor_right = 1.0
	choice_panel.anchor_top = 1.0
	choice_panel.anchor_bottom = 1.0
	add_child(choice_panel)
	close()


func close() -> void:
	box.visible = false
	name_tag.visible = false
	choice_panel.visible = false
	_waiting = false
	_typing = false


func is_open() -> bool:
	return box.visible


func say(who: String, line: String, expr := "normal") -> void:
	if Game.test_mode:
		Game.test_log.append("%s: %s" % [who, line])
		return
	_show_speaker(who, expr)
	choice_panel.visible = false
	text.text = line
	_total = text.get_total_character_count()
	_shown = 0.0
	text.visible_characters = 0
	_typing = true
	_waiting = true
	arrow.visible = false
	await _next


func choose(options: Array, disabled: Array = []) -> int:
	if Game.test_mode:
		var pick: int = Game.test_choices.pop_front() if Game.test_choices.size() > 0 else 0
		pick = clampi(pick, 0, options.size() - 1)
		Game.test_log.append("  [%s] -> %s" % [" | ".join(options), options[pick]])
		return pick
	# 선택지는 대화창 위 오른쪽에 뜬다. 앞 대사는 그대로 보인다.
	if menu:
		menu.queue_free()
	menu = UI.Menu.new()
	menu.setup(options, false, disabled)
	var widest := 0.0
	for o in options:
		widest = max(widest, Art.font_main.get_string_size("▶ " + str(o), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
	var w: float = min(widest + 20.0, get_viewport_rect().size.x - 24.0)
	var h := options.size() * 18.0 + 10.0
	choice_panel.offset_left = -8 - w
	choice_panel.offset_right = -8
	choice_panel.offset_top = -84 - h
	choice_panel.offset_bottom = -84
	menu.position = Vector2(6, 5)
	choice_panel.add_child(menu)
	choice_panel.visible = true
	arrow.visible = false
	_typing = false
	_waiting = false
	text.visible_characters = -1
	var i: int = await menu.picked
	choice_panel.visible = false
	menu.queue_free()
	menu = null
	return i


func _show_speaker(who: String, expr: String) -> void:
	box.visible = true
	var sp: Dictionary = UI.SPEAKERS.get(who, {})
	var has_face := who == "thief" or who.begins_with("crook")
	portrait.visible = has_face
	if has_face:
		portrait.texture = Art.portrait("crook" if who.begins_with("crook") else "thief", expr)
	text.offset_left = 78 if has_face else 12
	if sp.is_empty():
		name_tag.visible = false
		text.add_theme_color_override("default_color", UI.TEXT if who != "narr" else Color(0.85, 0.82, 0.78))
		return
	text.add_theme_color_override("default_color", UI.TEXT)
	name_tag.visible = true
	name_label.text = sp["name"]
	name_label.add_theme_color_override("font_color", sp["color"])
	var w := Art.font_main.get_string_size(sp["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14
	name_tag.offset_left = 8 + (70 if has_face else 0)
	name_tag.offset_right = name_tag.offset_left + w


func _process(delta: float) -> void:
	if _typing:
		var before := int(_shown)
		_shown += delta * CPS
		text.visible_characters = int(_shown)
		if int(_shown) / 3 != before / 3:
			Sfx.play("text", -24.0)
		if _shown >= _total:
			_typing = false
			text.visible_characters = -1
	if _waiting and not _typing:
		_blink += delta
		arrow.visible = fmod(_blink, 0.8) < 0.5


func _advance() -> void:
	if not _waiting:
		return
	if _typing:
		_typing = false
		text.visible_characters = -1
		return
	_waiting = false
	arrow.visible = false
	_next.emit()


func _unhandled_input(ev: InputEvent) -> void:
	if not box.visible or not _waiting:
		return
	if ev.is_action_pressed("act") or ev.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_advance()


func _on_box_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		_advance()
