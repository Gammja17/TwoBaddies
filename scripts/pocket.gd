extends Control
## 주머니: 가진 것, 훔친 것의 값, 곽두철과의 사이.

signal closed(result: Dictionary)

var _list: VBoxContainer
var _rows: Array = []
var _desc: RichTextLabel
var _money: Label
var _rel: Label
var _sel := 0
var _ids: Array = []
var _active := false
var _action_menu: UI.Menu
var _action_panel: Panel


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open() -> Dictionary:
	for c in get_children():
		c.queue_free()
	_rows.clear()
	_ids = Game.inventory.duplicate()
	for k in Game.loot:
		if not _ids.has(k):
			_ids.append(k)
	_sel = 0
	var p := UI.panel(Rect2())
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -280
	p.offset_right = 280
	p.offset_top = -157
	p.offset_bottom = 147
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(p)
	var title := UI.label("주머니", UI.BODY, UI.GOLD)
	title.position = Vector2(13, 7)
	p.add_child(title)
	_money = UI.label("", UI.BODY, UI.TEXT)
	_money.position = Vector2(93, 7)
	p.add_child(_money)
	_rel = UI.label("", UI.SMALL, UI.DIM, true)
	_rel.position = Vector2(13, 30)
	p.add_child(_rel)
	var sc := ScrollContainer.new()
	sc.position = Vector2(11, 53)
	sc.size = Vector2(227, 216)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.custom_minimum_size = Vector2(213, 0)
	sc.add_child(_list)
	for i in _ids.size():
		var id: String = _ids[i]
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon := TextureRect.new()
		icon.texture = Art.item(Items.info(id).get("icon", id))
		icon.custom_minimum_size = Vector2(24, 24)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var l := UI.label(Items.name_of(id), UI.BODY)
		row.add_child(l)
		var idx := i
		row.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				if _sel == idx:
					_act()
				else:
					_sel = idx
					_refresh())
		_list.add_child(row)
		_rows.append([row, l])
	var line := ColorRect.new()
	line.color = UI.EDGE
	line.position = Vector2(248, 53)
	line.size = Vector2(1, 216)
	p.add_child(line)
	_desc = UI.rich(UI.BODY)
	_desc.position = Vector2(261, 53)
	_desc.size = Vector2(285, 200)
	p.add_child(_desc)
	var help := UI.label("[Z] 쓰기, 읽기   [X] 닫기", UI.SMALL, UI.DIM, true)
	help.position = Vector2(261, 275)
	p.add_child(help)
	var close_btn := UI.label("닫기", UI.BODY, UI.GOLD)
	close_btn.position = Vector2(501, 6)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			if _active:
				Sfx.play("ui_close", -6.0)
				_finish({}))
	p.add_child(close_btn)
	_refresh()
	visible = true
	_active = true
	var r: Dictionary = await closed
	visible = false
	return r


func _refresh() -> void:
	var total := Game.loot_total()
	_money.text = "훔친 것 %s만원" % _comma(total) if total > 0 else "훔친 것 없음"
	_rel.text = "곽두철: " + Game.relation_text() if Game.met else ""
	for i in _rows.size():
		var l: Label = _rows[i][1]
		l.add_theme_color_override("font_color", UI.GOLD if i == _sel else UI.TEXT)
	if _ids.is_empty():
		_desc.text = "텅 비었다."
		return
	var id: String = _ids[_sel]
	var info := Items.info(id)
	var t: String = "[color=#eec76b]%s[/color]\n%s" % [Items.name_of(id), info.get("desc", "")]
	if Items.is_loot(id):
		var v := Items.value(id)
		t += "\n[color=#a8a095]값: 약 %s만원%s[/color]" % [_comma(v), " (반은 곽두철 몫)" if Game.loot_split.has(id) else ""]
	if id == "gloves" and Game.flag("gloves_on"):
		t += "\n[color=#84d18c]지금 끼고 있다.[/color]"
	var acts := actions_for(id)
	if acts.size() > 0:
		t += "\n\n[color=#a8a095][Z] %s[/color]" % " / ".join(acts)
	_desc.text = t


static func actions_for(id: String) -> Array:
	var info := Items.info(id)
	if info.has("read"):
		return ["읽는다"]
	match id:
		"notebook":
			return ["펼친다"]
		"pills":
			var out := []
			if Game.has("sandwich"):
				out.append("샌드위치에 탄다")
			if Game.has("whiskey"):
				out.append("위스키에 탄다")
			return out
		"gloves":
			return ["벗는다"] if Game.flag("gloves_on") else ["낀다"]
	return []


func _act() -> void:
	if _ids.is_empty():
		return
	var id: String = _ids[_sel]
	var acts := actions_for(id)
	if acts.is_empty():
		Sfx.play("buzz", -12.0)
		return
	if acts.size() == 1:
		_finish({"item": id, "action": acts[0]})
		return
	_action_panel = UI.panel(Rect2())
	_action_panel.anchor_left = 0.5
	_action_panel.anchor_top = 0.5
	_action_panel.offset_left = -27
	_action_panel.offset_top = 53
	_action_panel.offset_right = 147
	_action_panel.offset_bottom = 53 + acts.size() * 21 + 12
	add_child(_action_panel)
	_action_menu = UI.Menu.new()
	_action_menu.setup(acts, true)
	_action_menu.position = Vector2(8, 6)
	_action_panel.add_child(_action_menu)
	_active = false
	_action_menu.picked.connect(func(i: int): _finish({"item": id, "action": acts[i]}))
	_action_menu.cancelled.connect(func():
		_action_panel.queue_free()
		_action_menu = null
		_active = true)


func _finish(r: Dictionary) -> void:
	_active = false
	closed.emit(r)


func _unhandled_input(ev: InputEvent) -> void:
	if not _active:
		return
	if ev.is_action_pressed("up") and _rows.size() > 0:
		_sel = (_sel - 1 + _rows.size()) % _rows.size()
		Sfx.play("ui_move", -10.0)
	elif ev.is_action_pressed("down") and _rows.size() > 0:
		_sel = (_sel + 1) % _rows.size()
		Sfx.play("ui_move", -10.0)
	elif ev.is_action_pressed("act"):
		_act()
	elif ev.is_action_pressed("cancel") or ev.is_action_pressed("menu"):
		Sfx.play("ui_close", -6.0)
		_finish({})
	else:
		return
	get_viewport().set_input_as_handled()
	if _active:
		_refresh()


static func _comma(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
