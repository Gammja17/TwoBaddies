extends Control
## 시계, 방 이름, 알림, 조작 안내, 작업 막대, 화면 전환.

var clock_panel: Panel
var clock_label: Label
var left_label: Label
var room_label: Label
var toast_box: VBoxContainer
var hint_panel: Panel
var hint_label: Label
var work_panel: Panel
var work_label: Label
var work_bar: ColorRect
var work_fill: ColorRect
var fade: ColorRect
var flash: ColorRect
var hide_label: Label
var _room_tw: Tween


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_panel = UI.panel(Rect2(8, 8, 128, 44))
	add_child(clock_panel)
	clock_label = UI.label("02:10", UI.BODY, UI.TEXT)
	clock_label.position = Vector2(9, 3)
	clock_panel.add_child(clock_label)
	left_label = UI.label("", UI.SMALL, UI.DIM, true)
	left_label.position = Vector2(9, 24)
	clock_panel.add_child(left_label)
	clock_panel.visible = false

	room_label = UI.outline(UI.label("", UI.BODY, UI.TEXT))
	room_label.anchor_left = 0.5
	room_label.anchor_right = 0.5
	room_label.offset_top = 11
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	room_label.modulate.a = 0.0
	add_child(room_label)

	toast_box = VBoxContainer.new()
	toast_box.anchor_left = 0.5
	toast_box.anchor_right = 0.5
	toast_box.offset_top = 35
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)

	hint_panel = UI.panel(Rect2())
	hint_panel.anchor_left = 0.5
	hint_panel.anchor_right = 0.5
	hint_panel.anchor_top = 1.0
	hint_panel.anchor_bottom = 1.0
	hint_panel.offset_top = -40
	hint_panel.offset_bottom = -13
	add_child(hint_panel)
	hint_label = UI.label("", UI.BODY, UI.GOLD)
	hint_label.position = Vector2(10, 4)
	hint_panel.add_child(hint_label)
	hint_panel.visible = false

	hide_label = UI.outline(UI.label("숨어 있다. [Z] 나가기", UI.BODY, UI.BLUE))
	hide_label.anchor_left = 0.5
	hide_label.anchor_right = 0.5
	hide_label.anchor_top = 1.0
	hide_label.anchor_bottom = 1.0
	hide_label.offset_top = -70
	hide_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hide_label.visible = false
	add_child(hide_label)

	work_panel = UI.panel(Rect2())
	work_panel.anchor_left = 0.5
	work_panel.anchor_right = 0.5
	work_panel.anchor_top = 0.5
	work_panel.anchor_bottom = 0.5
	work_panel.offset_left = -107
	work_panel.offset_right = 107
	work_panel.offset_top = 32
	work_panel.offset_bottom = 78
	add_child(work_panel)
	work_label = UI.label("", UI.BODY)
	work_label.position = Vector2(10, 4)
	work_panel.add_child(work_label)
	work_bar = ColorRect.new()
	work_bar.color = UI.INNER
	work_bar.position = Vector2(10, 29)
	work_bar.size = Vector2(194, 8)
	work_panel.add_child(work_bar)
	work_fill = ColorRect.new()
	work_fill.color = UI.GOLD
	work_fill.position = Vector2(10, 29)
	work_fill.size = Vector2(0, 8)
	work_panel.add_child(work_fill)
	work_panel.visible = false

	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.9, 0.1, 0.08, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func _process(_delta: float) -> void:
	if clock_panel.visible:
		clock_label.text = Game.clock_text()
		var m := Game.minutes_left()
		left_label.text = "경찰 도착까지 %d분" % m
		var urgent := Game.time_left() < 180.0
		clock_label.add_theme_color_override("font_color", UI.RED if urgent else UI.TEXT)
		left_label.add_theme_color_override("font_color", UI.RED if urgent else UI.DIM)


func show_clock(on: bool) -> void:
	clock_panel.visible = on


func show_room(name: String) -> void:
	if name == "":
		return
	room_label.text = name
	if _room_tw:
		_room_tw.kill()
	_room_tw = create_tween()
	room_label.modulate.a = 1.0
	_room_tw.tween_interval(1.4)
	_room_tw.tween_property(room_label, "modulate:a", 0.0, 0.6)


func toast(text: String, color := UI.TEXT) -> void:
	var l := UI.outline(UI.label(text, UI.BODY, color))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_box.add_child(l)
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	while toast_box.get_child_count() > 3:
		toast_box.get_child(0).free()


func hint(text: String) -> void:
	if text == "":
		hint_panel.visible = false
		return
	hint_label.text = text
	var w := Art.font_main.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.BODY).x + 20
	hint_panel.offset_left = -w / 2.0
	hint_panel.offset_right = w / 2.0
	hint_panel.visible = true


func show_hidden(on: bool) -> void:
	hide_label.visible = on


func work_begin(text: String) -> void:
	work_label.text = text
	work_fill.size.x = 0
	work_panel.visible = true


func work_progress(f: float) -> void:
	work_fill.size.x = 194.0 * clampf(f, 0.0, 1.0)


func work_end() -> void:
	work_panel.visible = false


func fade_to(a: float, secs := 0.4) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, secs)
	await tw.finished


func red_flash(times := 3) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(flash, "color:a", 0.35, 0.18)
		tw.tween_property(flash, "color:a", 0.0, 0.32)
	await tw.finished
