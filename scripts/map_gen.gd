extends TileMap

const MAP_W   := 100
const MAP_H   := 75
const TILE_SZ := 32
const MAP_OFF := Vector2(-1600.0, -1200.0)

const T_ROAD     := 0
const T_SIDEWALK := 1
const T_BUILDING := 2
const T_GRASS    := 3
const T_WATER    := 4
const T_STATION  := 5
const T_MALL     := 6
const T_PETROL   := 7

var grid: Array = []

signal map_ready(grid: Array)

func _ready() -> void:
	position = MAP_OFF
	_build_tileset()
	_build_grid()
	_paint_tiles()
	map_ready.emit(grid)

func _build_tileset() -> void:
	var img: Image = Image.create(256, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0,   0, 32, 32), Color("#2a2a2a"))  # road
	img.fill_rect(Rect2i(32,  0, 32, 32), Color("#c8b89a"))  # sidewalk
	img.fill_rect(Rect2i(64,  0, 32, 32), Color("#e8d5b0"))  # building
	img.fill_rect(Rect2i(96,  0, 32, 32), Color("#4a7c3f"))  # grass
	img.fill_rect(Rect2i(128, 0, 32, 32), Color("#4a7abf"))  # water
	img.fill_rect(Rect2i(160, 0, 32, 32), Color("#888888"))  # station
	img.fill_rect(Rect2i(192, 0, 32, 32), Color("#d4b896"))  # mall
	img.fill_rect(Rect2i(224, 0, 32, 32), Color("#cc3333"))  # petrol

	var tex: ImageTexture = ImageTexture.create_from_image(img)

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	for i in 8:
		src.create_tile(Vector2i(i, 0))

	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()
	ts.add_source(src, 0)
	tile_set = ts

	var col_pts := PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16),
		Vector2(16,  16),  Vector2(-16,  16),
	])
	for t in [2, 5, 6, 7]:
		var td: TileData = src.get_tile_data(Vector2i(t, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, col_pts)

# ── Road predicates ─────────────────────────────────────────────────────────

func _is_road(x: int, y: int) -> bool:
	# Palm Beach Road — full width
	if y >= 60 and y <= 62: return true
	# Seawoods Station Road — full height
	if x >= 48 and x <= 50: return true
	# Sector 40 Road — full width
	if y >= 33 and y <= 35: return true
	# Sector 44 Road — full width
	if y >= 16 and y <= 18: return true
	# Small sector lane, west of Station Road
	if y >= 26 and y <= 27 and x < 48: return true
	# Small sector lane, east of Station Road
	if y >= 51 and y <= 52 and x > 50: return true
	return false

# ── Landmark predicates ──────────────────────────────────────────────────────

func _is_station(x: int, y: int) -> bool:
	return x >= 38 and x <= 47 and y >= 29 and y <= 39

func _is_mall(x: int, y: int) -> bool:
	return x >= 53 and x <= 70 and y >= 38 and y <= 49

func _is_water(x: int, y: int) -> bool:
	if x >= 4  and x <= 18 and y >= 48 and y <= 58: return true  # Seawoods Lake
	if x >= 2  and x <= 14 and y >= 66 and y <= 73: return true  # DPS Lake
	return false

func _is_petrol(x: int, y: int) -> bool:
	return x >= 78 and x <= 80 and y >= 57 and y <= 59

func _near_road(x: int, y: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0: continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < MAP_W and ny >= 0 and ny < MAP_H:
				if _is_road(nx, ny): return true
	return false

func _build_grid() -> void:
	grid.resize(MAP_H)
	for y in MAP_H:
		grid[y] = []
		grid[y].resize(MAP_W)
		for x in MAP_W:
			# Roads take priority over all landmarks
			if _is_road(x, y):
				grid[y][x] = T_ROAD
			elif _is_station(x, y):
				grid[y][x] = T_STATION
			elif _is_mall(x, y):
				grid[y][x] = T_MALL
			elif _is_petrol(x, y):
				grid[y][x] = T_PETROL
			elif _is_water(x, y):
				grid[y][x] = T_WATER
			elif _near_road(x, y):
				grid[y][x] = T_SIDEWALK
			else:
				grid[y][x] = T_BUILDING

func _paint_tiles() -> void:
	for y in MAP_H:
		for x in MAP_W:
			set_cell(0, Vector2i(x, y), 0, Vector2i(grid[y][x], 0))

func get_world_bounds() -> Rect2:
	return Rect2(MAP_OFF, Vector2(MAP_W * TILE_SZ, MAP_H * TILE_SZ))

func tile_center_world(tx: int, ty: int) -> Vector2:
	return MAP_OFF + Vector2(tx * TILE_SZ + TILE_SZ * 0.5, ty * TILE_SZ + TILE_SZ * 0.5)
