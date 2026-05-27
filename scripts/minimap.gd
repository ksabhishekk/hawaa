extends Control
## Minimap — high-contrast full-map view with player direction arrow.
## Renders the tile grid as a bright, readable overhead map with a yellow
## arrow showing the auto's position and heading.

const PAD := 8.0

# ── Bright minimap palette (visibility over realism) ─────────────────────────
const C_BG       := Color(0.06, 0.07, 0.10, 0.92)
const C_ROAD     := Color(0.82, 0.78, 0.70)       # warm beige roads
const C_SIDEWALK := Color(0.50, 0.46, 0.40)       # medium brown
const C_BUILDING := Color(0.28, 0.26, 0.25)       # dark grey
const C_GRASS    := Color(0.15, 0.32, 0.12)       # dark green
const C_WATER    := Color(0.12, 0.30, 0.55)       # blue
const C_STATION  := Color(1.0, 0.55, 0.05)        # orange — stations
const C_MALL     := Color(0.85, 0.25, 0.55)       # magenta — malls
const C_STADIUM  := Color(0.85, 0.20, 0.20)       # red — stadiums
const C_PLAYER   := Color(1.0, 0.85, 0.0)         # bright yellow
const C_BORDER   := Color(0.50, 0.45, 0.35, 0.70) # warm border

var _map_tex: ImageTexture
var _auto:    Node3D
var _map_rect := Rect2()   # cached inner rect for coordinate mapping

func _ready() -> void:
	pass

func setup(grid: Array, auto_node: Node3D) -> void:
	_auto = auto_node
	_bake_map(grid)
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

	# ── Map texture (aspect-corrected fit) ───────────────────────────────
	var inner := size - Vector2(PAD * 2.0, PAD * 2.0)
	var map_aspect := float(Globals.MAP_W) / float(Globals.MAP_H)
	var fit_w := inner.x
	var fit_h := fit_w / map_aspect
	if fit_h > inner.y:
		fit_h = inner.y
		fit_w = fit_h * map_aspect
	var offset := Vector2(
		PAD + (inner.x - fit_w) * 0.5,
		PAD + (inner.y - fit_h) * 0.5
	)
	_map_rect = Rect2(offset, Vector2(fit_w, fit_h))

	if _map_tex:
		draw_texture_rect(_map_tex, _map_rect, false)

	# ── Border ───────────────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, size), C_BORDER, false, 2.0)
	# Inner accent line
	draw_rect(
		Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)),
		Color(0.3, 0.28, 0.22, 0.3), false, 1.0
	)

	# ── Player direction arrow ───────────────────────────────────────────
	if not _auto:
		return

	# Map world position → minimap pixel
	var world_sz  := Vector2(
		Globals.MAP_W * Globals.TILE_3D,
		Globals.MAP_H * Globals.TILE_3D
	)
	var origin_xz := Vector2(Globals.MAP_ORIGIN.x, Globals.MAP_ORIGIN.z)
	var auto_xz   := Vector2(_auto.global_position.x, _auto.global_position.z)
	var norm      := ((auto_xz - origin_xz) / world_sz).clamp(Vector2.ZERO, Vector2.ONE)
	var dot_pos   := _map_rect.position + norm * _map_rect.size

	# Arrow points in the auto's heading direction
	var heading   := -_auto.rotation.y
	var arrow_len := 6.0
	var dir  := Vector2(sin(heading), cos(heading))
	var perp := Vector2(dir.y, -dir.x)

	var tip   := dot_pos + dir * arrow_len
	var left  := dot_pos - dir * (arrow_len * 0.5) + perp * (arrow_len * 0.4)
	var right := dot_pos - dir * (arrow_len * 0.5) - perp * (arrow_len * 0.4)

	# Drop shadow
	var sh := Vector2(1.0, 1.0)
	draw_colored_polygon(
		PackedVector2Array([tip + sh, left + sh, right + sh]),
		Color(0.0, 0.0, 0.0, 0.45)
	)
	# Arrow body
	draw_colored_polygon(
		PackedVector2Array([tip, left, right]),
		C_PLAYER
	)
	# Center dot
	draw_circle(dot_pos, 1.5, Color.WHITE)
