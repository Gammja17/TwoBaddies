class_name Actor
extends Node2D
## 칸을 한 칸씩 걷는 인물 (도둑, 수배범, 경찰).

signal arrived(cell: Vector2i)

const DIR_NAME := {Vector2i.DOWN: "down", Vector2i.LEFT: "left", Vector2i.RIGHT: "right", Vector2i.UP: "up"}

var world: World
var who := "thief"
var cell := Vector2i.ZERO
var facing := Vector2i.DOWN
var moving := false
var step_time := 0.2
var sprite: AnimatedSprite2D
var hidden_in := ""          # 숨은 곳의 물건 id
var active := true
var _flip := false
var _bubble: Label
var _bubble_timer: SceneTreeTimer


func setup(w: World, name: String, c: Vector2i, face := Vector2i.DOWN) -> void:
	world = w
	who = name
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Art.char_frames(name)
	sprite.centered = false
	sprite.offset = Vector2(-8, -24)
	add_child(sprite)
	world.ysort.add_child(self)
	world.actors.append(self)
	place(c, face)


func place(c: Vector2i, face := Vector2i.DOWN) -> void:
	cell = c
	facing = face
	moving = false
	position = world.cell_to_pos(c)
	idle()


func occupies(c: Vector2i) -> bool:
	return c == cell


func visible_in_world() -> bool:
	return active and hidden_in == ""


func idle() -> void:
	if sprite:
		sprite.play(DIR_NAME.get(facing, "down") + "_idle")


func face(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO:
		facing = dir
		if not moving:
			idle()


## 한 칸 걷기. 막혀 있으면 그쪽을 보기만 하고 false.
func try_step(dir: Vector2i) -> bool:
	if moving or dir == Vector2i.ZERO:
		return false
	facing = dir
	var target := cell + dir
	if not world.passable(target, self):
		idle()
		return false
	walk_to(target)
	return true


func walk_to(target: Vector2i) -> void:
	moving = true
	var d := target - cell
	if d != Vector2i.ZERO and abs(d.x) + abs(d.y) == 1:
		facing = d
	cell = target
	_flip = not _flip
	sprite.play(DIR_NAME.get(facing, "down") + ("_a" if _flip else "_b"))
	var tw := create_tween()
	tw.tween_property(self, "position", world.cell_to_pos(cell), step_time)
	tw.tween_callback(_on_arrived)


func _on_arrived() -> void:
	moving = false
	arrived.emit(cell)


func front() -> Vector2i:
	return cell + facing


## 머리 위 말풍선 (대화창을 열지 않는 짧은 혼잣말).
func bark(text: String, secs := 2.2) -> void:
	if _bubble == null:
		_bubble = Label.new()
		_bubble.add_theme_font_override("font", Art.font_small)
		_bubble.add_theme_font_size_override("font_size", 10)
		_bubble.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
		_bubble.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
		_bubble.add_theme_constant_override("outline_size", 3)
		_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bubble.z_index = 60
		add_child(_bubble)
	_bubble.text = text
	_bubble.reset_size()
	_bubble.position = Vector2(-_bubble.size.x / 2.0, -38)
	_bubble.visible = true
	var t := get_tree().create_timer(secs)
	_bubble_timer = t
	t.timeout.connect(func():
		if _bubble_timer == t and is_instance_valid(_bubble):
			_bubble.visible = false)


func hide_bubble() -> void:
	if _bubble:
		_bubble.visible = false


func set_hidden(spot: String) -> void:
	hidden_in = spot
	visible = spot == ""
