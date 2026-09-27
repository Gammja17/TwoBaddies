extends Node
## 그림 아틀라스(assets/art/*.png + atlas.json)에서 이름으로 조각을 꺼낸다.

const DIRS := ["down", "left", "right", "up"]

var meta: Dictionary = {}
var sheets: Dictionary = {}
var _cache: Dictionary = {}
var font_main: FontFile
var font_small: FontFile


func _ready() -> void:
	var f := FileAccess.open("res://assets/art/atlas.json", FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	for k in ["tiles", "props", "items", "chars", "portraits"]:
		sheets[k] = load("res://assets/art/%s.png" % k)
	font_main = _pixel_font("res://assets/fonts/Galmuri14.ttf")    # 15px 에서 또렷하다
	font_small = _pixel_font("res://assets/fonts/Galmuri11.ttf")   # 12px 에서 또렷하다


func _pixel_font(path: String) -> FontFile:
	var ff: FontFile = load(path)
	ff.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	ff.hinting = TextServer.HINTING_NONE
	ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	ff.generate_mipmaps = false
	return ff


func rect(sheet: String, name: String) -> Rect2:
	var r: Array = meta[sheet].get(name, [0, 0, 16, 16])
	return Rect2(r[0], r[1], r[2], r[3])


func has(sheet: String, name: String) -> bool:
	return meta.has(sheet) and meta[sheet].has(name)


func tex(sheet: String, name: String) -> AtlasTexture:
	var key := sheet + "/" + name
	if _cache.has(key):
		return _cache[key]
	var at := AtlasTexture.new()
	at.atlas = sheets[sheet]
	at.region = rect(sheet, name)
	_cache[key] = at
	return at


func prop(name: String) -> AtlasTexture:
	return tex("props", name)


func item(name: String) -> AtlasTexture:
	return tex("items", name)


func portrait(who: String, expr: String) -> AtlasTexture:
	var n := "%s_%s" % [who, expr]
	if not has("portraits", n):
		n = "%s_normal" % who
	return tex("portraits", n)


## 인물 걷기 프레임: 애니메이션 이름은 "down_idle", "down_a", "down_b" 처럼 방향_자세.
func char_frames(who: String) -> SpriteFrames:
	var key := "frames/" + who
	if _cache.has(key):
		return _cache[key]
	var base: Rect2 = rect("chars", who)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var poses := ["idle", "a", "b"]
	for di in 4:
		for pi in 3:
			var anim: String = "%s_%s" % [DIRS[di], poses[pi]]
			sf.add_animation(anim)
			sf.set_animation_loop(anim, false)
			var at := AtlasTexture.new()
			at.atlas = sheets["chars"]
			at.region = Rect2(base.position.x + (di * 3 + pi) * base.size.x, base.position.y, base.size.x, base.size.y)
			sf.add_frame(anim, at)
	_cache[key] = sf
	return sf


## 타일 이름 -> 아틀라스 칸 좌표 (칸 크기 단위)
func tile_coord(name: String) -> Vector2i:
	var r: Array = meta["tiles"][name]
	var s: int = meta["tiles"]["_size"]
	return Vector2i(int(r[0]) / s, int(r[1]) / s)


func has_tile(name: String) -> bool:
	return meta["tiles"].has(name)


func wall_tile(set_name: String, mask: int) -> String:
	return meta["tiles"]["_walls"]["%s:%d" % [set_name, mask]]
