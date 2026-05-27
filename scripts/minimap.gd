extends Control
## Minimap — high-contrast full-map view with player direction arrow.
## Renders the tile grid as a bright, readable overhead map with a yellow
## arrow showing the auto's position and heading.

const PAD := 8.0

# ── Dark Mode GPS palette ───────────────────────────────────────────────────
const C_BG       := Color(0.05, 0.06, 0.08, 0.95)
const C_ROAD     := Color(0.18, 0.20, 0.25)       # dark blue/grey roads
const C_SIDEWALK := Color(0.12, 0.14, 0.18)       # very dark blue
const C_BUILDING := Color(0.08, 0.09, 0.12)       # almost black buildings
const C_GRASS    := Color(0.08, 0.16, 0.10)       # deep green
const C_WATER    := Color(0.05, 0.15, 0.25)       # dark water
const C_STATION  := Color(0.80, 0.45, 0.00)       # orange — stations
const C_MALL     := Color(0.60, 0.15, 0.35)       # magenta — malls
const C_STADIUM  := Color(0.60, 0.10, 0.10)       # red — stadiums
const C_PLAYER   := Color(1.00, 0.90, 0.00)       # neon yellow
const C_BORDER   := Color(0.20, 0.25, 0.30, 0.80) # sleek slate border

const ZOOM := 6.0

var _map_tex: ImageTexture
var _auto:    Node3D
var _world:   Node3D
var _route:   Array[Vector3] = []

func _ready() -> void:
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func setup(grid: Array, auto_node: Node3D, world_node: Node3D = null) -> void:
	_auto = auto_node
	_world = world_node
	_bake_map(grid)
	queue_redraw()

func set_route(path: Array[Vector3]) -> void:
	_route = path
	queue_redraw()

func clear_route() -> void:
	_route.clear()
	queue_redraw()

# ── Bake tile grid into a small image texture ────────────────────────────────

func _bake_map(grid: Array) -> void:
	var w := Globals.MAP_W
	var h := Globals.MAP_H
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c: Color
			match grid[y][x]:
				0: c = C_ROAD
				1: c = C_SIDEWALK
				2: c = C_BUILDING
				3: c = C_GRASS
				4: c = C_WATER
				5: c = C_STATION
				6: c = C_MALL
				7: c = C_STADIUM
				_: c = C_BUILDING
			img.set_pixel(x, y, c)
	_map_tex = ImageTexture.create_from_image(img)

# ── Redraw every frame when auto exists ──────────────────────────────────────

func _process(_delta: float) -> void:
	if _auto:
		queue_redraw()

# ── Draw ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	# ── Background ───────────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, size), C_BG)

	if not _auto:
		return

	# ── Scrolling Map Texture ────────────────────────────────────────────
	if _map_tex:
		var ui_center := size * 0.5
		var world_sz  := Vector2(Globals.MAP_W * Globals.TILE_3D, Globals.MAP_H * Globals.TILE_3D)
		var origin_xz := Vector2(Globals.MAP_ORIGIN.x, Globals.MAP_ORIGIN.z)
		var auto_xz   := Vector2(_auto.global_position.x, _auto.global_position.z)
		var auto_norm := ((auto_xz - origin_xz) / world_sz).clamp(Vector2.ZERO, Vector2.ONE)
		
		var tex_size  := Vector2(Globals.MAP_W, Globals.MAP_H) * ZOOM
		var tex_pos   := ui_center - (auto_norm * tex_size)
		
		draw_texture_rect(_map_tex, Rect2(tex_pos, tex_size), false)

	# ── GPS Route ────────────────────────────────────────────────────────
	if _route.size() > 1:
		var pts := PackedVector2Array()
		for p in _route:
			pts.append(_world_to_map(p))
		draw_polyline(pts, Color(0.0, 0.9, 1.0, 0.85), 4.5, true)
		# Destination pin
		draw_circle(pts[-1], 5.0, Color.RED)
		draw_circle(pts[-1], 2.5, Color.WHITE)

	# ── Area Names ───────────────────────────────────────────────────────
	if _world and "OSM_LANDMARKS" in _world:
		for name_str in _world.OSM_LANDMARKS:
			var coord: Vector2i = _world.OSM_LANDMARKS[name_str]
			var map_pos = _world_to_map(_world._tile_pos(coord.x, coord.y))
			if Rect2(Vector2.ZERO, size).has_point(map_pos):
				draw_string(get_theme_default_font(), map_pos + Vector2(0, -5), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1, 1, 1, 0.8))

	# ── Border ───────────────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, size), C_BORDER, false, 2.0)
	# Inner accent line 	
	draw_rect(
		Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)),
		Color(0.3, 0.28, 0.22, 0.3), false, 1.0
	)

	# ── Player direction arrow (FIXED TO CENTER) ─────────────────────────
	var dot_pos := size * 0.5

	# Arrow points in the auto's heading direction
	var heading   := -_auto.rotation.y
	var arrow_len := 8.0
	var dir  := Vector2(sin(heading), cos(heading))
	var perp := Vector2(dir.y, -dir.x)

	var tip   := dot_pos + dir * arrow_len
	var left  := dot_pos - dir * (arrow_len * 0.6) + perp * (arrow_len * 0.5)
	var right := dot_pos - dir * (arrow_len * 0.6) - perp * (arrow_len * 0.5)
	var back  := dot_pos - dir * (arrow_len * 0.2)

	# Drop shadow
	var sh := Vector2(1.0, 1.0)
	draw_colored_polygon(
		PackedVector2Array([tip + sh, left + sh, back + sh, right + sh]),
		Color(0.0, 0.0, 0.0, 0.6)
	)
	# Arrow body
	draw_colored_polygon(
		PackedVector2Array([tip, left, back, right]),
		C_PLAYER
	)
	# Outline
	draw_polyline(
		PackedVector2Array([tip, left, back, right, tip]),
		Color.BLACK, 1.0, true
	)
	# Center dot
	draw_circle(dot_pos, 1.5, Color.BLACK)

func _world_to_map(world_pos: Vector3) -> Vector2:
	if not _auto: 
		return Vector2.ZERO
	
	var ui_center := size * 0.5
	var world_sz  := Vector2(Globals.MAP_W * Globals.TILE_3D, Globals.MAP_H * Globals.TILE_3D)
	var origin_xz := Vector2(Globals.MAP_ORIGIN.x, Globals.MAP_ORIGIN.z)
	
	var tex_size  := Vector2(Globals.MAP_W, Globals.MAP_H) * ZOOM
	
	var auto_xz   := Vector2(_auto.global_position.x, _auto.global_position.z)
	var auto_norm := ((auto_xz - origin_xz) / world_sz).clamp(Vector2.ZERO, Vector2.ONE)
	
	var pos_xz    := Vector2(world_pos.x, world_pos.z)
	var pos_norm  := ((pos_xz - origin_xz) / world_sz).clamp(Vector2.ZERO, Vector2.ONE)
	
	var offset_pixels := (pos_norm - auto_norm) * tex_size
	return ui_center + offset_pixels
