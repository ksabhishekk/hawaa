extends Node3D
## Procedural 3D world built from REAL OpenStreetMap data for Navi Mumbai.
## Roads are rasterized from actual OSM highway data (Seawoods/Nerul area).
## Uses MultiMeshInstance3D for flat tiles to keep draw-call count low.

const T_ROAD     := 0
const T_SIDEWALK := 1
const T_BUILDING := 2
const T_GRASS    := 3
const T_WATER    := 4
const T_STATION  := 5
const T_MALL     := 6
const T_PETROL   := 7

var grid: Array = []
var astar: AStarGrid2D

signal map_ready(grid: Array)

# ── Material cache ───────────────────────────────────────────────────────────
var _mat_road:      StandardMaterial3D
var _mat_sidewalk:  StandardMaterial3D
var _mat_grass:     StandardMaterial3D
var _mat_water:     StandardMaterial3D
var _mat_station:   StandardMaterial3D
var _mat_mall:      StandardMaterial3D
var _mat_petrol:    StandardMaterial3D
var _mat_trunk:     StandardMaterial3D

var _rng := RandomNumberGenerator.new()

# ── Real OSM road data (auto-generated from OpenStreetMap) ───────────────────
# Each entry: [row_y, x_start, x_end] — a horizontal run of road cells.
# Bounding box: lat 19.015-19.065, lon 73.005-73.045 (Seawoods/Nerul, Navi Mumbai)
const OSM_ROAD_RUNS: Array = [
	[0, 13, 15], [0, 24, 39], [0, 53, 60], [0, 65, 67],
	[1, 13, 15], [1, 24, 39], [1, 53, 63], [1, 65, 68],
	[2, 0, 23], [2, 30, 68],
	[3, 0, 23], [3, 30, 68],
	[4, 0, 69],
	[5, 0, 1], [5, 21, 37], [5, 63, 69],
	[6, 0, 1], [6, 21, 37], [6, 63, 69],
	[7, 0, 1], [7, 21, 23], [7, 28, 30], [7, 33, 37], [7, 63, 69],
	[8, 0, 1], [8, 21, 23], [8, 28, 30], [8, 33, 37], [8, 63, 70],
	[9, 0, 1], [9, 21, 23], [9, 28, 30], [9, 33, 37], [9, 64, 70],
	[10, 0, 1], [10, 21, 23], [10, 28, 30], [10, 33, 37], [10, 64, 70],
	[11, 0, 1], [11, 21, 30], [11, 33, 37], [11, 65, 68],
	[12, 0, 1], [12, 21, 30], [12, 33, 37], [12, 65, 68],
	[13, 0, 2], [13, 21, 30], [13, 33, 37], [13, 66, 69],
	[14, 0, 3], [14, 23, 30], [14, 33, 37], [14, 66, 69],
	[15, 0, 4], [15, 25, 30], [15, 33, 69],
	[16, 0, 5], [16, 27, 30], [16, 33, 69],
	[17, 0, 6], [17, 27, 30], [17, 33, 69],
	[18, 1, 8], [18, 27, 30], [18, 34, 40], [18, 67, 69],
	[19, 4, 9], [19, 27, 30], [19, 34, 41], [19, 67, 69],
	[20, 5, 9], [20, 28, 30], [20, 35, 43], [20, 67, 69],
	[21, 6, 9], [21, 28, 31], [21, 36, 45], [21, 50, 55], [21, 67, 69],
	[22, 7, 9], [22, 28, 31], [22, 37, 46], [22, 50, 56], [22, 67, 69],
	[23, 7, 9], [23, 29, 31], [23, 37, 48], [23, 50, 56], [23, 67, 69],
	[24, 7, 9], [24, 29, 31], [24, 37, 56], [24, 67, 69],
	[25, 7, 9], [25, 29, 32], [25, 36, 56], [25, 67, 69],
	[26, 7, 9], [26, 29, 32], [26, 36, 39], [26, 43, 53], [26, 67, 69],
	[27, 6, 9], [27, 30, 32], [27, 35, 39], [27, 44, 54], [27, 67, 69],
	[28, 6, 9], [28, 30, 32], [28, 35, 38], [28, 44, 56], [28, 67, 67],
	[29, 6, 9], [29, 30, 32], [29, 34, 37], [29, 44, 57], [29, 66, 66],
	[30, 6, 39], [30, 42, 49], [30, 51, 58], [30, 63, 65],
	[31, 5, 47], [31, 52, 59], [31, 61, 62],
	[32, 5, 46], [32, 52, 60],
	[33, 5, 12], [33, 23, 25], [33, 28, 45], [33, 54, 60],
	[34, 5, 8], [34, 10, 12], [34, 23, 25], [34, 30, 37], [34, 39, 45], [34, 55, 60],
	[35, 5, 8], [35, 10, 47], [35, 56, 60],
	[36, 5, 8], [36, 10, 49], [36, 56, 60],
	[37, 5, 8], [37, 10, 42], [37, 44, 52], [37, 57, 61],
	[38, 5, 8], [38, 10, 12], [38, 17, 20], [38, 22, 25], [38, 30, 39], [38, 46, 53], [38, 57, 61],
	[39, 5, 8], [39, 10, 12], [39, 17, 19], [39, 22, 25], [39, 30, 39], [39, 48, 53], [39, 57, 61],
	[40, 5, 12], [40, 17, 25], [40, 29, 33], [40, 35, 38], [40, 47, 53], [40, 57, 62],
	[41, 5, 12], [41, 17, 33], [41, 35, 38], [41, 46, 51], [41, 58, 62],
	[42, 5, 11], [42, 17, 33], [42, 35, 38], [42, 43, 50], [42, 58, 62],
	[43, 5, 10], [43, 17, 33], [43, 35, 37], [43, 42, 50], [43, 58, 63],
	[44, 5, 10], [44, 17, 19], [44, 29, 31], [44, 35, 37], [44, 40, 54], [44, 58, 63],
	[45, 5, 10], [45, 17, 19], [45, 29, 31], [45, 33, 44], [45, 47, 56], [45, 58, 63],
	[46, 5, 10], [46, 17, 19], [46, 29, 31], [46, 33, 44], [46, 49, 63],
	[47, 5, 10], [47, 16, 19], [47, 29, 31], [47, 33, 44], [47, 50, 63],
	[48, 4, 19], [48, 28, 31], [48, 33, 37], [48, 39, 44], [48, 55, 63], [48, 69, 73],
	[49, 4, 19], [49, 28, 36], [49, 40, 44], [49, 58, 63], [49, 69, 76],
	[50, 3, 19], [50, 28, 36], [50, 40, 45], [50, 58, 64], [50, 69, 78], [50, 89, 99],
	[51, 3, 7], [51, 16, 19], [51, 28, 35], [51, 40, 45], [51, 58, 83], [51, 87, 99],
	[52, 3, 6], [52, 16, 18], [52, 28, 35], [52, 42, 46], [52, 57, 99],
	[53, 3, 6], [53, 16, 18], [53, 28, 36], [53, 43, 46], [53, 57, 99],
	[54, 3, 6], [54, 16, 18], [54, 27, 36], [54, 43, 46], [54, 57, 60], [54, 63, 67], [54, 70, 78], [54, 82, 99],
	[55, 3, 6], [55, 16, 18], [55, 26, 30], [55, 34, 37], [55, 43, 46], [55, 57, 60], [55, 72, 90], [55, 92, 99],
	[56, 3, 6], [56, 16, 18], [56, 25, 29], [56, 34, 38], [56, 42, 46], [56, 56, 59], [56, 73, 91], [56, 94, 99],
	[57, 3, 6], [57, 16, 20], [57, 24, 29], [57, 35, 45], [57, 56, 59], [57, 77, 94], [57, 96, 99],
	[58, 3, 6], [58, 16, 28], [58, 35, 45], [58, 55, 58], [58, 77, 86], [58, 88, 99],
	[59, 3, 6], [59, 16, 27], [59, 36, 44], [59, 55, 58], [59, 77, 99],
	[60, 4, 7], [60, 19, 25], [60, 37, 49], [60, 55, 57], [60, 77, 99],
	[61, 4, 8], [61, 21, 28], [61, 36, 53], [61, 55, 58], [61, 77, 99],
	[62, 5, 9], [62, 22, 29], [62, 36, 58], [62, 77, 99],
	[63, 6, 9], [63, 20, 30], [63, 36, 46], [63, 48, 59], [63, 80, 99],
	[64, 6, 32], [64, 37, 45], [64, 52, 59], [64, 73, 89], [64, 96, 99],
	[65, 6, 24], [65, 27, 34], [65, 37, 44], [65, 54, 59], [65, 73, 95],
	[66, 6, 25], [66, 27, 46], [66, 56, 59], [66, 73, 83], [66, 85, 96],
	[67, 6, 9], [67, 13, 16], [67, 19, 48], [67, 56, 59], [67, 73, 77], [67, 87, 98],
	[68, 6, 8], [68, 17, 50], [68, 56, 59], [68, 74, 77], [68, 87, 99],
	[69, 6, 8], [69, 16, 43], [69, 45, 52], [69, 57, 59], [69, 75, 78], [69, 85, 99],
	[70, 6, 9], [70, 16, 36], [70, 39, 44], [70, 46, 54], [70, 57, 59], [70, 75, 79], [70, 84, 99],
	[71, 6, 9], [71, 16, 35], [71, 40, 44], [71, 48, 63], [71, 76, 79], [71, 83, 99],
	[72, 6, 9], [72, 17, 33], [72, 41, 44], [72, 50, 63], [72, 77, 80], [72, 82, 99],
	[73, 6, 45], [73, 53, 63], [73, 77, 98],
	[74, 6, 45], [74, 57, 60], [74, 78, 97],
]

# Real Navi Mumbai landmark positions (from OpenStreetMap)
const OSM_LANDMARKS: Dictionary = {
	"Seawoods Station":    Vector2i(35, 67),
	"Nerul Station":       Vector2i(23, 46),
	"Nexus Mall":          Vector2i(44, 65),
	"DY Patil Stadium":    Vector2i(55, 31),
	"NRI Lake":            Vector2i(50, 72),
	"DPS Lake":            Vector2i(65, 74),
	"Belapur Station":     Vector2i(87, 63),
	"CBD Belapur":         Vector2i(88, 65),
	"Sanpada Station":     Vector2i(5, 7),
	"Palm Beach Galleria": Vector2i(43, 74),
}

# ── Water body definitions (approximate real locations) ──────────────────────
const WATER_BODIES: Array = [
	# NRI Lake / Seawoods Lake area
	{"min": Vector2i(46, 70), "max": Vector2i(54, 74)},
	# DPS Lake area
	{"min": Vector2i(62, 72), "max": Vector2i(68, 74)},
]

func _ready() -> void:
	_rng.seed = 42
	_create_materials()
	_build_grid()
	_generate_ground()
	_generate_flat_tiles()
	_generate_3d_objects()
	_generate_street_lamps()
	map_ready.emit(grid)

# ── Materials ────────────────────────────────────────────────────────────────

func _create_materials() -> void:
	_mat_road     = _flat_mat(Color("#2a2a2a"))
	_mat_sidewalk = _flat_mat(Color("#c8b89a"))
	_mat_grass    = _flat_mat(Color("#2a4a2f"))
	_mat_water    = _flat_mat(Color("#1a3a5f"), 0.4)
	_mat_station  = _flat_mat(Color("#666666"))
	_mat_mall     = _flat_mat(Color("#d4b896"))
	_mat_petrol   = _flat_mat(Color("#cc3333"))
	_mat_trunk    = _flat_mat(Color("#3d2b1f"))

func _flat_mat(col: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color  = col
	m.metallic      = metallic
	m.roughness     = 0.85
	return m

func _canopy_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness    = 1.0
	m.emission_enabled = true
	m.emission         = col * 0.15
	m.emission_energy_multiplier = 0.3
	return m

# ── Grid from OSM data ──────────────────────────────────────────────────────

func _is_osm_road(x: int, y: int) -> bool:
	for run in OSM_ROAD_RUNS:
		var ry: int = run[0]
		var rx0: int = run[1]
		var rx1: int = run[2]
		if y == ry and x >= rx0 and x <= rx1:
			return true
	return false

func _is_water_body(x: int, y: int) -> bool:
	for wb in WATER_BODIES:
		if x >= wb["min"].x and x <= wb["max"].x and y >= wb["min"].y and y <= wb["max"].y:
			return true
	return false

func _is_landmark(x: int, y: int) -> String:
	for lname in OSM_LANDMARKS:
		var pos: Vector2i = OSM_LANDMARKS[lname]
		if abs(x - pos.x) <= 2 and abs(y - pos.y) <= 2:
			return lname
	return ""

func _near_road(x: int, y: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < Globals.MAP_W and ny >= 0 and ny < Globals.MAP_H:
				if _is_osm_road(nx, ny):
					return true
	return false

func _build_grid() -> void:
	grid.resize(Globals.MAP_H)
	
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, Globals.MAP_W, Globals.MAP_H)
	astar.cell_size = Vector2(Globals.TILE_3D, Globals.TILE_3D)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	
	for y in Globals.MAP_H:
		grid[y] = []
		grid[y].resize(Globals.MAP_W)
		for x in Globals.MAP_W:
			if _is_osm_road(x, y):
				grid[y][x] = T_ROAD
			elif _is_water_body(x, y):
				grid[y][x] = T_WATER
			elif _is_landmark(x, y) != "":
				var lname := _is_landmark(x, y)
				if "Station" in lname:
					grid[y][x] = T_STATION
				elif "Mall" in lname or "Galleria" in lname:
					grid[y][x] = T_MALL
				elif "Stadium" in lname:
					grid[y][x] = T_PETROL  # reuse petrol color for stadium
				else:
					grid[y][x] = T_STATION
			elif _near_road(x, y):
				grid[y][x] = T_SIDEWALK
			else:
				if _rng.randf() < 0.50:
					grid[y][x] = T_BUILDING
				else:
					grid[y][x] = T_GRASS

			# Set solid in AStar if not a road
			if grid[y][x] != T_ROAD:
				astar.set_point_solid(Vector2i(x, y), true)

# ── Position helper ──────────────────────────────────────────────────────────

func _tile_pos(x: int, y: int) -> Vector3:
	return Globals.MAP_ORIGIN + Vector3(
		x * Globals.TILE_3D + Globals.TILE_3D * 0.5,
		0.0,
		y * Globals.TILE_3D + Globals.TILE_3D * 0.5
	)

# ── Ground plane ─────────────────────────────────────────────────────────────

func _generate_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(Globals.MAP_W * Globals.TILE_3D, Globals.MAP_H * Globals.TILE_3D)
	mesh.material = _flat_mat(Color("#1a1a1a"))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0.0, -0.05, 0.0)
	add_child(mi)

	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(Globals.MAP_W * Globals.TILE_3D + 40.0, 0.1, Globals.MAP_H * Globals.TILE_3D + 40.0)
	cs.shape = box
	sb.position = Vector3(0.0, -0.05, 0.0)
	sb.add_child(cs)
	add_child(sb)

# ── Flat tiles via MultiMesh ─────────────────────────────────────────────────

func _generate_flat_tiles() -> void:
	var road_pos:     Array[Vector3] = []
	var sidewalk_pos: Array[Vector3] = []
	var grass_pos:    Array[Vector3] = []
	var water_pos:    Array[Vector3] = []

	for y in Globals.MAP_H:
		for x in Globals.MAP_W:
			var t: int = grid[y][x]
			var pos := _tile_pos(x, y)
			match t:
				T_ROAD:     road_pos.append(pos)
				T_SIDEWALK: sidewalk_pos.append(pos)
				T_GRASS:    grass_pos.append(pos)
				T_WATER:    water_pos.append(pos)

	_add_multimesh_tiles(road_pos, Globals.ROAD_Y, _mat_road)
	_add_multimesh_tiles(sidewalk_pos, Globals.SIDEWALK_Y, _mat_sidewalk)
	_add_multimesh_tiles(grass_pos, 0.01, _mat_grass)
	_add_multimesh_tiles(water_pos, -0.08, _mat_water)

func _add_multimesh_tiles(positions: Array[Vector3], y_off: float, mat: StandardMaterial3D) -> void:
	if positions.is_empty():
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(Globals.TILE_3D, Globals.TILE_3D)
	plane.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = plane
	mm.instance_count = positions.size()
	for i in positions.size():
		var t := Transform3D.IDENTITY
		t.origin = Vector3(positions[i].x, y_off, positions[i].z)
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

# ── 3D objects (buildings, trees, landmarks) ─────────────────────────────────

func _generate_3d_objects() -> void:
	for y in Globals.MAP_H:
		for x in Globals.MAP_W:
			var t: int = grid[y][x]
			var pos := _tile_pos(x, y)
			match t:
				T_BUILDING:
					_add_building(pos)
				T_GRASS:
					if _rng.randf() < 0.35:
						_add_tree(pos)
				T_STATION:
					_add_landmark_building(pos, _mat_station, 8.0, "station")
				T_MALL:
					_add_landmark_building(pos, _mat_mall, 10.0, "mall")
				T_PETROL:
					_add_landmark_building(pos, _mat_petrol, 12.0, "stadium")

func _add_building(pos: Vector3) -> void:
	var h: float = _rng.randf_range(Globals.BLDG_H_MIN, Globals.BLDG_H_MAX)
	var w: float = Globals.TILE_3D * _rng.randf_range(0.6, 0.95)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, w)

	var base := Color("#e8d5b0")
	var variation := _rng.randf_range(-0.08, 0.08)
	var col := Color(base.r + variation, base.g + variation, base.b + variation)
	var mat := _flat_mat(col)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(pos.x, h * 0.5, pos.z)
	add_child(mi)

	# ── COLLISION — buildings block the auto ──
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask  = 0
	var cs := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(w, h, w)
	cs.shape = cbox
	sb.position = Vector3(pos.x, h * 0.5, pos.z)
	sb.add_child(cs)
	add_child(sb)

	# Window light
	if _rng.randf() < 0.15:
		_add_window_light(pos, h)

func _add_window_light(pos: Vector3, building_h: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.6)
	light.light_energy = 0.4
	light.omni_range = 4.0
	light.position = Vector3(
		pos.x + _rng.randf_range(-1.0, 1.0),
		_rng.randf_range(1.5, building_h * 0.7),
		pos.z + _rng.randf_range(-1.0, 1.0)
	)
	light.shadow_enabled = false
	add_child(light)

func _add_tree(pos: Vector3) -> void:
	var trunk_h: float = _rng.randf_range(1.8, 3.5)
	var canopy_r: float = _rng.randf_range(1.5, 3.0)

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius    = 0.12
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height        = trunk_h
	trunk_mesh.material      = _mat_trunk

	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(
		pos.x + _rng.randf_range(-0.5, 0.5),
		trunk_h * 0.5,
		pos.z + _rng.randf_range(-0.5, 0.5)
	)
	add_child(trunk)

	var canopy_colors := [
		Color("#8B1A1A"), Color("#A0522D"), Color("#CC4422"),
		Color("#B22222"), Color("#6B3A2A"), Color("#994422"),
		Color("#2d5a1e"),
	]
	var c_col: Color = canopy_colors[_rng.randi() % canopy_colors.size()]
	var c_mat := _canopy_mat(c_col)

	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = canopy_r
	canopy_mesh.height = canopy_r * 1.6
	canopy_mesh.material = c_mat

	var canopy := MeshInstance3D.new()
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(trunk.position.x, trunk_h + canopy_r * 0.5, trunk.position.z)
	add_child(canopy)

func _add_landmark_building(pos: Vector3, mat: StandardMaterial3D, h: float, _type: String) -> void:
	var w := Globals.TILE_3D * 0.9
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, w)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(pos.x, h * 0.5, pos.z)
	add_child(mi)

	# Collision
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask  = 0
	var cs := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(w, h, w)
	cs.shape = cbox
	sb.position = Vector3(pos.x, h * 0.5, pos.z)
	sb.add_child(cs)
	add_child(sb)

	# Landmark light (brighter)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.7)
	light.light_energy = 1.0
	light.omni_range = 8.0
	light.position = Vector3(pos.x, h + 1.0, pos.z)
	light.shadow_enabled = false
	add_child(light)

# ── Street lamps ─────────────────────────────────────────────────────────────

func _generate_street_lamps() -> void:
	for y in Globals.MAP_H:
		for x in Globals.MAP_W:
			if grid[y][x] != T_ROAD:
				continue
			if x % Globals.LAMP_SPACING != 0 and y % Globals.LAMP_SPACING != 0:
				continue
			if not _is_road_edge(x, y):
				continue
			_add_street_lamp(_tile_pos(x, y))

func _is_road_edge(x: int, y: int) -> bool:
	for dx in [-1, 1]:
		var nx: int = x + dx
		if nx >= 0 and nx < Globals.MAP_W:
			if grid[y][nx] != T_ROAD:
				return true
	for dy in [-1, 1]:
		var ny: int = y + dy
		if ny >= 0 and ny < Globals.MAP_H:
			if grid[ny][x] != T_ROAD:
				return true
	return false

func _add_street_lamp(pos: Vector3) -> void:
	var h := Globals.LAMP_HEIGHT

	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius    = 0.05
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height        = h
	pole_mesh.material      = _flat_mat(Color("#555555"))

	var pole := MeshInstance3D.new()
	pole.mesh = pole_mesh
	pole.position = Vector3(pos.x, h * 0.5, pos.z)
	add_child(pole)

	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.15
	bulb_mesh.height = 0.3
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color   = Color(1.0, 0.85, 0.4)
	bulb_mat.emission_enabled = true
	bulb_mat.emission       = Color(1.0, 0.85, 0.4)
	bulb_mat.emission_energy_multiplier = 3.0
	bulb_mesh.material = bulb_mat

	var bulb := MeshInstance3D.new()
	bulb.mesh = bulb_mesh
	bulb.position = Vector3(pos.x, h + 0.2, pos.z)
	add_child(bulb)

	var light := OmniLight3D.new()
	light.light_color   = Color(1.0, 0.82, 0.45)
	light.light_energy  = 1.8
	light.omni_range    = Globals.LAMP_RANGE
	light.shadow_enabled = false
	light.position = Vector3(pos.x, h + 0.1, pos.z)
	add_child(light)

# ── Helpers ──────────────────────────────────────────────────────────────────

func get_sidewalk_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for y in Globals.MAP_H:
		for x in Globals.MAP_W:
			if grid[y][x] == T_SIDEWALK:
				result.append(_tile_pos(x, y))
	return result

func get_world_bounds() -> AABB:
	var sz := Vector3(Globals.MAP_W * Globals.TILE_3D, 20.0, Globals.MAP_H * Globals.TILE_3D)
	return AABB(Globals.MAP_ORIGIN, sz)

func get_path_points(start_pos: Vector3, end_pos: Vector3) -> Array[Vector3]:
	if not astar:
		return []
	var sx := clampi(int((start_pos.x - Globals.MAP_ORIGIN.x) / Globals.TILE_3D), 0, Globals.MAP_W - 1)
	var sy := clampi(int((start_pos.z - Globals.MAP_ORIGIN.z) / Globals.TILE_3D), 0, Globals.MAP_H - 1)
	var ex := clampi(int((end_pos.x - Globals.MAP_ORIGIN.x) / Globals.TILE_3D), 0, Globals.MAP_W - 1)
	var ey := clampi(int((end_pos.z - Globals.MAP_ORIGIN.z) / Globals.TILE_3D), 0, Globals.MAP_H - 1)
	
	var start_coord := _find_nearest_road(Vector2i(sx, sy))
	var end_coord := _find_nearest_road(Vector2i(ex, ey))

	var path_coords := astar.get_id_path(start_coord, end_coord)
	
	var result: Array[Vector3] = []
	for id in path_coords:
		result.append(_tile_pos(id.x, id.y))
	return result

func _find_nearest_road(start: Vector2i) -> Vector2i:
	if not astar.is_point_solid(start):
		return start
	var queue := [start]
	var visited := {start: true}
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		if not astar.is_point_solid(curr):
			return curr
		for d in dirs:
			var n: Vector2i = curr + d
			if n.x >= 0 and n.x < Globals.MAP_W and n.y >= 0 and n.y < Globals.MAP_H:
				if not visited.has(n):
					visited[n] = true
					queue.append(n)
	return start
