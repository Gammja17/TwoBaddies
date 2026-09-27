class_name UI
extends RefCounted
## 화면 조각을 같은 모양으로 만드는 도우미 (고른 테두리의 어두운 판, 도트 글꼴).

const BG := Color(0.09, 0.08, 0.11, 0.93)
const EDGE := Color(0.47, 0.40, 0.33)
const INNER := Color(0.17, 0.15, 0.19)
const TEXT := Color(0.95, 0.91, 0.84)
const DIM := Color(0.66, 0.62, 0.58)
const GOLD := Color(0.93, 0.78, 0.42)
const RED := Color(0.90, 0.40, 0.35)
const GREEN := Color(0.52, 0.82, 0.55)
const BLUE := Color(0.62, 0.72, 0.88)
## 글자 크기 (갈무리 글꼴이 또렷하게 나오는 크기)
const BODY := 15     # Galmuri14
const SMALL := 12    # Galmuri11
const BIG := 30      # Galmuri14 두 배

const SPEAKERS := {
	"thief": {"name": "오만복", "color": Color(0.62, 0.72, 0.88)},
	"crook": {"name": "곽두철", "color": Color(0.90, 0.64, 0.44)},
	"crook_unknown": {"name": "험상궂은 남자", "color": Color(0.90, 0.64, 0.44)},
	"pa": {"name": "안내 방송", "color": Color(0.90, 0.40, 0.35)},
	"tv": {"name": "텔레비전", "color": Color(0.70, 0.82, 0.70)},
	"police": {"name": "경찰", "color": Color(0.55, 0.65, 0.95)},
}


static func panel_style(bg := BG, edge := EDGE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(1, 2)
	return sb


static func panel(rect: Rect2, bg := BG, edge := EDGE) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", panel_style(bg, edge))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func label(text: String, size := BODY, color := TEXT, small := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Art.font_small if small else Art.font_main)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func rich(size := BODY) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = false
	r.add_theme_font_override("normal_font", Art.font_main)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", TEXT)
	r.add_theme_constant_override("line_separation", 3)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func outline(l: Label, width := 3) -> Label:
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08))
	l.add_theme_constant_override("outline_size", width)
	return l


## 한 줄짜리 선택 목록. 위아래로 고르고 확인 버튼(또는 누르기)으로 정한다.
class Menu extends VBoxContainer:
	signal picked(index: int)
	signal cancelled
	var items: Array = []
	var labels: Array[Label] = []
	var index := 0
	var enabled: Array = []
	var allow_cancel := true
	var font_size := UI.BODY

	func setup(options: Array, can_cancel := true, disabled: Array = []) -> void:
		items = options
		allow_cancel = can_cancel
		add_theme_constant_override("separation", 3)
		for i in options.size():
			var l := UI.label("", font_size)
			l.mouse_filter = Control.MOUSE_FILTER_STOP
			var idx := i
			l.gui_input.connect(func(ev: InputEvent):
				if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
					if enabled[idx]:
						index = idx
						_refresh()
						Sfx.play("ui_ok", -6.0)
						picked.emit(idx))
			add_child(l)
			labels.append(l)
			enabled.append(not disabled.has(i))
		while index < enabled.size() - 1 and not enabled[index]:
			index += 1
		_refresh()

	func _refresh() -> void:
		for i in labels.size():
			var on := i == index
			labels[i].text = ("▶ " if on else "   ") + str(items[i])
			var col := UI.GOLD if on else UI.TEXT
			if not enabled[i]:
				col = UI.DIM * Color(1, 1, 1, 0.7)
			labels[i].add_theme_color_override("font_color", col)

	func _move(d: int) -> void:
		if items.is_empty():
			return
		var n := items.size()
		for _k in n:
			index = (index + d + n) % n
			if enabled[index]:
				break
		Sfx.play("ui_move", -10.0)
		_refresh()

	func _unhandled_input(ev: InputEvent) -> void:
		if not is_visible_in_tree():
			return
		if ev.is_action_pressed("up"):
			_move(-1)
			get_viewport().set_input_as_handled()
		elif ev.is_action_pressed("down"):
			_move(1)
			get_viewport().set_input_as_handled()
		elif ev.is_action_pressed("act"):
			get_viewport().set_input_as_handled()
			if enabled[index]:
				Sfx.play("ui_ok", -6.0)
				picked.emit(index)
		elif ev.is_action_pressed("cancel") and allow_cancel:
			get_viewport().set_input_as_handled()
			Sfx.play("ui_back", -6.0)
			cancelled.emit()


## 터치 버튼용 동그라미 그림
static func circle_tex(r: int, fill: Color, edge: Color) -> ImageTexture:
	var img := Image.create(r * 2, r * 2, false, Image.FORMAT_RGBA8)
	for y in r * 2:
		for x in r * 2:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			if d <= r - 1.5:
				img.set_pixel(x, y, fill)
			elif d <= r:
				img.set_pixel(x, y, edge)
	return ImageTexture.create_from_image(img)
