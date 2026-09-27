class_name World
extends Node2D
## 저택: 층별 지도(data/map.txt), 가구(data/objects.json), 길찾기, 방, 안개.
## 모든 층을 한 격자에 세로로 쌓아 둔다 (1F 위, 2F 가운데, B1 아래).

const T := 16
const FLOOR_ORIGIN := {"1F": Vector2i(0, 0), "2F": Vector2i(0, 30), "B1": Vector2i(0, 56)}
const WALL_SET := {"1F": "beige", "2F": "beige", "B1": "grey"}
const FLOOR_TILE := {".": "floor_wood", ",": "floor_tile", ":": "floor_plank", "_": "floor_stone",
		"g": "grass", "p": "dirt", "B": "floor_tile", "O": "floor_wood"}
const WALKABLE := ".,:_gpDBO"
const TINT := {"1F": Color(0.80, 0.83, 0.98), "2F": Color(0.80, 0.83, 0.98), "B1": Color(0.60, 0.60, 0.70),
		"yard": Color(0.55, 0.62, 0.85)}
## 계단: 올라서는 칸 -> 도착 (층, 칸, 바라보는 방향)
const STAIRS := {
	"1F:21,12": ["B1", Vector2i(21, 5), Vector2i.DOWN],
	"1F:22,12": ["B1", Vector2i(22, 5), Vector2i.DOWN],
	"1F:32,12": ["2F", Vector2i(30, 15), Vector2i.DOWN],
	"1F:33,12": ["2F", Vector2i(31, 15), Vector2i.DOWN],
	"2F:30,13": ["1F", Vector2i(32, 14), Vector2i.DOWN],
	"2F:31,13": ["1F", Vector2i(33, 14), Vector2i.DOWN],
	"B1:21,3": ["1F", Vector2i(21, 14), Vector2i.DOWN],
	"B1:22,3": ["1F", Vector2i(22, 14), Vector2i.DOWN],
}
## 방 이름: 방 안의 아무 칸 하나로 정한다.
const ROOM_NAMES := {
	"1F:4,18": "뒷마당", "1F:11,5": "식료품 창고", "1F:18,5": "주방", "1F:28,4": "식당",
	"1F:40,8": "거실", "1F:12,15": "다용도실", "1F:18,16": "보안실", "1F:26,15": "현관",
	"2F:3,6": "욕실", "2F:12,6": "안방", "2F:25,8": "서재", "2F:5,15": "손님방", "2F:20,15": "2층 복도",
	"B1:4,6": "지하 창고", "B1:14,6": "보일러실",
}

var rows: Dictionary = {}          # floor -> PackedStringArray
var size_of: Dictionary = {}       # floor -> Vector2i
var tilemap: TileMapLayer
var floor_layer: Node2D            # 깔개, 계단
var ysort: Node2D                  # 가구, 인물
var fog: Sprite2D
var tint: CanvasModulate
var objects: Dictionary = {}       # id -> Prop
var _at: Dictionary = {}           # Vector2i(world) -> Array[Prop]
var room_id: Dictionary = {}       # Vector2i(world) -> int
var room_cells: Dictionary = {}    # int -> Array[Vector2i]
var room_name: Dictionary = {}     # int -> String
var room_floor: Dictionary = {}    # int -> floor
var visited: Dictionary = {}       # room -> true
var astar := AStar2D.new()
var _fog_img: Image
var _fog_tex: ImageTexture
var _fog_origin := Vector2i.ZERO
var _fog_room := -99
var actors: Array = []             # 칸을 차지하는 인물들


class Prop extends Sprite2D:
	var id := ""
	var kind := ""
	var floor_name := ""
	var cell := Vector2i.ZERO       # 발자리 왼쪽 위 (월드 칸)
	var w := 1
	var h := 1
	var layer := "obj"
	var solid := true
	var sprite_name := ""
	var state := ""

	func cells() -> Array:
		var out := []
		for dy in h:
			for dx in w:
				out.append(cell + Vector2i(dx, dy))
		return out


func _ready() -> void:
	tint = CanvasModulate.new()
	add_child(tint)
	tilemap = TileMapLayer.new()
	tilemap.tile_set = _make_tileset()
	add_child(tilemap)
	floor_layer = Node2D.new()
	add_child(floor_layer)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	fog = Sprite2D.new()
	fog.centered = false
	fog.scale = Vector2(T, T)
	fog.z_index = 50
	add_child(fog)
	_load_map()
	_paint_tiles()
	_load_objects()
	_find_rooms()
	_build_nav()


# ---------------------------------------------------------------- 불러오기 ----

func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = Art.sheets["tiles"]
	src.texture_region_size = Vector2i(T, T)
	var tex_size: Vector2i = Art.sheets["tiles"].get_size()
	for y in tex_size.y / T:
		for x in tex_size.x / T:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	return ts


func _load_map() -> void:
	var text := FileAccess.open("res://data/map.txt", FileAccess.READ).get_as_text()
	var cur := ""
	for line in text.split("\n"):
		line = line.trim_suffix("\r")
		if line.begins_with("[") and line.ends_with("]"):
			cur = line.substr(1, line.length() - 2)
			rows[cur] = PackedStringArray()
		elif cur != "":
			rows[cur].append(line)
	for f in rows:
		var arr: PackedStringArray = rows[f]
		while arr.size() > 0 and arr[arr.size() - 1].strip_edges() == "":
			arr.remove_at(arr.size() - 1)
		var w := 0
		for r in arr:
			w = max(w, r.length())
		for i in arr.size():
			arr[i] = arr[i].rpad(w)
		rows[f] = arr
		size_of[f] = Vector2i(w, arr.size())


func ch(f: String, lx: int, ly: int) -> String:
	var arr: PackedStringArray = rows[f]
	if ly < 0 or ly >= arr.size() or lx < 0 or lx >= arr[ly].length():
		return " "
	return arr[ly][lx]


func _floor_tile(f: String, x: int, y: int) -> String:
	var c := ch(f, x, y)
	if FLOOR_TILE.has(c):
		if c == "g" and (x * 7 + y * 13) % 5 == 0:
			return "grass2"
		return FLOOR_TILE[c]
	if c == "D":
		var counts := {}
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(0, 3), Vector2i(0, -3)]:
			var n := ch(f, x + d.x, y + d.y)
			if FLOOR_TILE.has(n):
				counts[n] = counts.get(n, 0) + 1
		var best := "."
		var bn := -1
		for k in counts:
			if counts[k] > bn:
				best = k
				bn = counts[k]
		return FLOOR_TILE[best]
	return ""


func _paint_tiles() -> void:
	for f in rows:
		var o: Vector2i = FLOOR_ORIGIN[f]
		var sz: Vector2i = size_of[f]
		var set_name: String = WALL_SET[f]
		for y in sz.y:
			for x in sz.x:
				var c := ch(f, x, y)
				var name := _floor_tile(f, x, y)
				if name == "":
					if c == "#":
						name = Art.wall_tile(set_name, _wall_mask(f, x, y))
					elif c == "F":
						var lower := ch(f, x, y - 1) == "F"
						var le := ch(f, x - 1, y) != "F"
						var re := ch(f, x + 1, y) != "F"
						name = "face_%s_%s%s%s" % [set_name, "lo" if lower else "up", "_l" if le else "", "_r" if re else ""]
				if name != "":
					tilemap.set_cell(o + Vector2i(x, y), 0, Art.tile_coord(name))


func _wall_mask(f: String, x: int, y: int) -> int:
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var m := 0
	for i in dirs.size():
		if ch(f, x + dirs[i].x, y + dirs[i].y) == "#":
			m |= 1 << i
	if ch(f, x, y + 1) == "F":
		m |= 1 << 8
	return m


func _load_objects() -> void:
	var list: Array = JSON.parse_string(FileAccess.open("res://data/objects.json", FileAccess.READ).get_as_text())
	for d in list:
		var p := Prop.new()
		p.id = d["id"]
		p.kind = d.get("k", "")
		p.floor_name = d["f"]
		p.cell = FLOOR_ORIGIN[p.floor_name] + Vector2i(int(d["x"]), int(d["y"]))
		p.w = int(d.get("w", 1))
		p.h = int(d.get("h", 1))
		p.layer = d.get("l", "obj")
		p.solid = bool(d.get("solid", p.layer == "obj"))
		p.centered = false
		add_prop(p, d.get("s", ""))


func add_prop(p: Prop, sprite_name: String) -> void:
	objects[p.id] = p
	for c in p.cells():
		if not _at.has(c):
			_at[c] = []
		_at[c].append(p)
	if p.layer == "floor":
		floor_layer.add_child(p)
	else:
		ysort.add_child(p)
	set_sprite(p, sprite_name)


func set_sprite(p: Prop, sprite_name: String) -> void:
	p.sprite_name = sprite_name
	if sprite_name == "":
		p.texture = null
		return
	var tex := Art.prop(sprite_name)
	p.texture = tex
	var bottom := (p.cell.y + p.h) * T
	# 바닥 기준으로 세운다. 벽에 붙은 것과 가구 위 소품은 뒤에 그려지도록 기준점을 조금 옮긴다.
	var sort_y := bottom
	match p.layer:
		"wall":
			sort_y = bottom - 1
		"top":
			sort_y = bottom + 1
	p.position = Vector2(p.cell.x * T, sort_y)
	p.offset = Vector2(0, bottom - sort_y - tex.get_height())


func obj(id: String) -> Prop:
	return objects.get(id)


func objects_at(c: Vector2i) -> Array:
	return _at.get(c, [])


func remove_prop(id: String) -> void:
	var p: Prop = objects.get(id)
	if p == null:
		return
	for c in p.cells():
		if _at.has(c):
			_at[c].erase(p)
	objects.erase(id)
	p.queue_free()


# ---------------------------------------------------------------- 칸 ----

func to_local_cell(c: Vector2i) -> Array:
	for f in FLOOR_ORIGIN:
		var o: Vector2i = FLOOR_ORIGIN[f]
		var sz: Vector2i = size_of[f]
		var l := c - o
		if l.x >= 0 and l.y >= 0 and l.x < sz.x and l.y < sz.y:
			return [f, l]
	return ["", c]


func floor_of(c: Vector2i) -> String:
	return to_local_cell(c)[0]


func char_at(c: Vector2i) -> String:
	var fl := to_local_cell(c)
	if fl[0] == "":
		return " "
	return ch(fl[0], fl[1].x, fl[1].y)


func is_face(c: Vector2i) -> bool:
	return char_at(c) == "F"


func terrain_walkable(c: Vector2i) -> bool:
	return WALKABLE.contains(char_at(c)) and char_at(c) != " "


func blocked_by_object(c: Vector2i) -> bool:
	for p in objects_at(c):
		if p.solid:
			return true
	return false


func actor_at(c: Vector2i, except: Node = null) -> Node:
	for a in actors:
		if a != except and a.visible_in_world() and a.occupies(c):
			return a
	return null


func passable(c: Vector2i, who: Node = null) -> bool:
	if not terrain_walkable(c) or blocked_by_object(c):
		return false
	return actor_at(c, who) == null


func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2.0, (c.y + 1) * T)


func stairs_at(c: Vector2i) -> Array:
	var fl := to_local_cell(c)
	var key := "%s:%d,%d" % [fl[0], fl[1].x, fl[1].y]
	if not STAIRS.has(key):
		return []
	var d: Array = STAIRS[key]
	return [d[0], FLOOR_ORIGIN[d[0]] + d[1], d[2]]


func world_cell(f: String, lx: int, ly: int) -> Vector2i:
	return FLOOR_ORIGIN[f] + Vector2i(lx, ly)


func floor_rect_px(f: String) -> Rect2:
	var o: Vector2i = FLOOR_ORIGIN[f]
	var sz: Vector2i = size_of[f]
	return Rect2(o.x * T, o.y * T, sz.x * T, sz.y * T)


# ---------------------------------------------------------------- 방 ----

func _find_rooms() -> void:
	var next := 0
	for f in rows:
		var o: Vector2i = FLOOR_ORIGIN[f]
		var sz: Vector2i = size_of[f]
		for y in sz.y:
			for x in sz.x:
				var c := o + Vector2i(x, y)
				if room_id.has(c):
					continue
				var k := ch(f, x, y)
				if not ".,:_gp".contains(k):
					continue
				var stack: Array[Vector2i] = [c]
				room_id[c] = next
				var cells: Array[Vector2i] = []
				while stack.size() > 0:
					var cur: Vector2i = stack.pop_back()
					cells.append(cur)
					for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
						var n: Vector2i = cur + d
						if room_id.has(n):
							continue
						var nl := n - o
						var nk := ch(f, nl.x, nl.y)
						if ".,:_gp".contains(nk) and nk != " ":
							room_id[n] = next
							stack.append(n)
				room_cells[next] = cells
				room_floor[next] = f
				next += 1
	for key in ROOM_NAMES:
		var parts: PackedStringArray = key.split(":")
		var xy: PackedStringArray = parts[1].split(",")
		var c := world_cell(parts[0], int(xy[0]), int(xy[1]))
		if room_id.has(c):
			room_name[room_id[c]] = ROOM_NAMES[key]
	# 문칸은 이웃한 방 가운데 하나로 묶는다 (-1: 문, 따로 기억해 둔다)
	for f in rows:
		var o: Vector2i = FLOOR_ORIGIN[f]
		var sz: Vector2i = size_of[f]
		for y in sz.y:
			for x in sz.x:
				if "DBO".contains(ch(f, x, y)):
					room_id[o + Vector2i(x, y)] = -1


func room_at(c: Vector2i) -> int:
	return room_id.get(c, -2)


## 문칸이면 붙어 있는 방들을 모두 돌려준다.
func rooms_touching(c: Vector2i) -> Array:
	var r := room_at(c)
	if r >= 0:
		return [r]
	var out := []
	if r == -1:
		var seen := {c: true}
		var stack := [c]
		while stack.size() > 0:
			var cur: Vector2i = stack.pop_back()
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = cur + d
				if seen.has(n):
					continue
				seen[n] = true
				var rn := room_at(n)
				if rn >= 0 and not out.has(rn):
					out.append(rn)
				elif rn == -1:
					stack.append(n)
	return out


func name_of_room(r: int) -> String:
	return room_name.get(r, "")


func room_of_name(n: String) -> int:
	for r in room_name:
		if room_name[r] == n:
			return r
	return -1


# ---------------------------------------------------------------- 길찾기 ----

func _nav_id(c: Vector2i) -> int:
	return (c.y + 10) * 1000 + (c.x + 10)


func _build_nav() -> void:
	for f in rows:
		var o: Vector2i = FLOOR_ORIGIN[f]
		var sz: Vector2i = size_of[f]
		for y in sz.y:
			for x in sz.x:
				var c := o + Vector2i(x, y)
				if terrain_walkable(c):
					astar.add_point(_nav_id(c), Vector2(c))
	for id in astar.get_point_ids():
		var p := astar.get_point_position(id)
		var c := Vector2i(p)
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			var n: Vector2i = c + d
			var nid := _nav_id(n)
			if astar.has_point(nid):
				astar.connect_points(id, nid)
	for key in STAIRS:
		var parts: PackedStringArray = key.split(":")
		var xy: PackedStringArray = parts[1].split(",")
		var a := world_cell(parts[0], int(xy[0]), int(xy[1]))
		var dest: Array = STAIRS[key]
		var b: Vector2i = FLOOR_ORIGIN[dest[0]] + dest[1]
		if astar.has_point(_nav_id(a)) and astar.has_point(_nav_id(b)):
			astar.connect_points(_nav_id(a), _nav_id(b), false)
	refresh_nav()


## 단단한 가구 칸은 길에서 뺀다 (가구가 바뀌면 다시 부른다).
func refresh_nav() -> void:
	for id in astar.get_point_ids():
		var c := Vector2i(astar.get_point_position(id))
		astar.set_point_disabled(id, blocked_by_object(c))


func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a := _nav_id(from)
	var b := _nav_id(to)
	if not astar.has_point(a) or not astar.has_point(b):
		return out
	var was_a := astar.is_point_disabled(a)
	var was_b := astar.is_point_disabled(b)
	astar.set_point_disabled(a, false)
	astar.set_point_disabled(b, false)
	for p in astar.get_point_path(a, b):
		out.append(Vector2i(p))
	astar.set_point_disabled(a, was_a)
	astar.set_point_disabled(b, was_b)
	return out


## 두 칸 사이에 벽이 없는지 (같은 층). 가구는 시야를 가리지 않는다.
func line_clear(a: Vector2i, b: Vector2i) -> bool:
	if floor_of(a) != floor_of(b):
		return false
	var d := b - a
	var n: int = max(abs(d.x), abs(d.y))
	for i in range(1, n):
		var p := Vector2(a) + Vector2(d) * (float(i) / n)
		var c := Vector2i(roundi(p.x), roundi(p.y))
		if not terrain_walkable(c):
			return false
	return true


# ---------------------------------------------------------------- 안개 ----

## 지금 있는 방은 밝게, 가 본 방은 흐리게, 안 가 본 곳은 까맣게.
func update_fog(player_cell: Vector2i, force := false) -> void:
	var f := floor_of(player_cell)
	if f == "":
		return
	var rooms := rooms_touching(player_cell)
	var key: int = -3 if rooms.is_empty() else int(rooms[0]) * 100 + rooms.size()
	if not force and key == _fog_room and _fog_origin == FLOOR_ORIGIN[f]:
		return
	_fog_room = key
	for r in rooms:
		visited[r] = true
	var o: Vector2i = FLOOR_ORIGIN[f]
	var sz: Vector2i = size_of[f]
	_fog_origin = o
	var lit := {}
	var seen := {}
	for r in room_cells:
		if room_floor[r] != f:
			continue
		var target: Dictionary
		if rooms.has(r):
			target = lit
		elif visited.has(r):
			target = seen
		else:
			continue
		for c in room_cells[r]:
			for dy in range(-3, 2):
				for dx in range(-1, 2):
					target[c + Vector2i(dx, dy)] = true
	# 문칸 자체도 밝힌다
	for c in _door_cells_near(rooms, f):
		lit[c] = true
	_fog_img = Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	for y in sz.y:
		for x in sz.x:
			var c := o + Vector2i(x, y)
			var a := 1.0
			if lit.has(c):
				a = 0.0
			elif seen.has(c):
				a = 0.62
			_fog_img.set_pixel(x, y, Color(0, 0, 0, a))
	if _fog_tex == null or _fog_tex.get_size() != Vector2(sz):
		_fog_tex = ImageTexture.create_from_image(_fog_img)
	else:
		_fog_tex.update(_fog_img)
	fog.texture = _fog_tex
	fog.position = Vector2(o * T)
	tint.color = TINT["yard"] if name_of_room(rooms[0] if rooms.size() > 0 else -9) == "뒷마당" else TINT[f]


func _door_cells_near(rooms: Array, f: String) -> Array:
	var out := []
	var o: Vector2i = FLOOR_ORIGIN[f]
	var sz: Vector2i = size_of[f]
	for y in sz.y:
		for x in sz.x:
			var c := o + Vector2i(x, y)
			if room_at(c) == -1:
				for r in rooms_touching(c):
					if rooms.has(r):
						out.append(c)
						break
	return out


## 인물이 지금 플레이어 눈에 보이는 칸에 있는지.
func cell_lit(c: Vector2i) -> bool:
	if _fog_img == null:
		return true
	var l := c - _fog_origin
	if l.x < 0 or l.y < 0 or l.x >= _fog_img.get_width() or l.y >= _fog_img.get_height():
		return false
	return _fog_img.get_pixel(l.x, l.y).a < 0.1
