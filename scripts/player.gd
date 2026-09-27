extends Actor
## 오만복. 방향키로 걷고, Shift(또는 B)를 누르고 있으면 뛴다. 뛰면 발소리가 커진다.

const WALK := 0.19
const RUN := 0.12

var play: Node
var control := true
var running := false
var _held: Array[Vector2i] = []


func _ready() -> void:
	arrived.connect(_on_step)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	_track_held()
	if not control or Game.busy > 0:
		return
	if hidden_in != "":
		# 숨어 있을 때는 조사(Z)나 취소(X)로 나온다
		if Input.is_action_just_pressed("act") or Input.is_action_just_pressed("cancel"):
			play.interact()
		return
	if Input.is_action_just_pressed("act"):
		play.interact()
		return
	if Input.is_action_just_pressed("menu"):
		play.open_pocket()
		return
	if moving:
		return
	var dir: Vector2i = _held.back() if _held.size() > 0 else Vector2i.ZERO
	running = Input.is_action_pressed("run")
	step_time = RUN if running else WALK
	if dir != Vector2i.ZERO:
		if not try_step(dir):
			play.bumped(cell + dir)


## 가장 나중에 누른 방향이 이긴다.
func _track_held() -> void:
	for a in [["up", Vector2i.UP], ["down", Vector2i.DOWN], ["left", Vector2i.LEFT], ["right", Vector2i.RIGHT]]:
		var pressed := Input.is_action_pressed(a[0])
		var v: Vector2i = a[1]
		if pressed and not _held.has(v):
			_held.append(v)
		elif not pressed and _held.has(v):
			_held.erase(v)


func _on_step(c: Vector2i) -> void:
	var ground := world.char_at(c)
	var snd := "step_wood"
	if ground == "g" or ground == "p":
		snd = "step_grass"
	elif ground == "_" or ground == "," or ground == "B":
		snd = "step_stone"
	Sfx.play(snd, -4.0 if running else -14.0)
	play.player_stepped(c, running)
