extends Actor
## 오만복. 방향키로 걷고, Shift(또는 B)를 누르고 있으면 뛴다. 뛰면 발소리가 커진다.

const WALK := 0.19
const RUN := 0.12

var play: Node
var control := true
var running := false
var _held: Array[Vector2i] = []


var torch: PointLight2D      # 손전등 불빛 (바라보는 쪽으로 퍼진다)
var glow: PointLight2D       # 손전등 불빛이 번져 몸 둘레가 조금 밝다


func _ready() -> void:
	arrived.connect(_on_step)
	torch = PointLight2D.new()
	torch.texture = _cone_texture()
	torch.texture_scale = 2.8
	torch.color = Color(1.0, 0.95, 0.82)
	torch.energy = 0.9
	torch.position = Vector2(0, -22)
	add_child(torch)
	glow = PointLight2D.new()
	glow.texture = _cone_texture(true)
	glow.texture_scale = 1.1
	glow.color = Color(1.0, 0.92, 0.8)
	glow.energy = 0.45
	glow.position = Vector2(0, -20)
	add_child(glow)


static var _tex_cache := {}


## 오른쪽으로 퍼지는 원뿔 (round 면 둥근 빛). 한 번 만들어 두고 판마다 다시 쓴다.
static func _cone_texture(round := false) -> ImageTexture:
	if _tex_cache.has(round):
		return _tex_cache[round]
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var v := Vector2(x - n / 2.0, y - n / 2.0)
			var d := v.length() / (n / 2.0)
			var a := 0.0
			if d < 1.0:
				if round:
					a = pow(1.0 - d, 1.5)
				elif v.x > 0.0:
					var ang: float = absf(v.angle())
					var edge := clampf((0.52 - ang) / 0.18, 0.0, 1.0)
					a = edge * pow(1.0 - d, 1.2) * clampf(d * 6.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tex_cache[round] = ImageTexture.create_from_image(img)
	return _tex_cache[round]


func _process(delta: float) -> void:
	super(delta)
	var lit := Game.has("flashlight") and hidden_in == "" and active
	torch.visible = lit
	glow.visible = lit
	torch.rotation = Vector2(facing).angle()


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
	if Input.is_action_just_pressed("memo") and Game.has("notepad"):
		play.open_memo()
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
