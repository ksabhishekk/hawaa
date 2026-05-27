extends Control
## Minimap — now reads Vector3 position from the 3D auto, projects XZ.

const MAP_W   := 100
const MAP_H   := 75
const TILE_PX := 1
const INNER_W := float(MAP_W * TILE_PX)
const INNER_H := float(MAP_H * TILE_PX)
const PAD     := Vector2(25.0, 37.0)

const C_ROAD     := Color("#2a2a2a")
const C_SIDEWALK := Color("#c8b89a")
const C_BUILDING := Color("#e8d5b0")
const C_GRASS    := Color("#2a4a2f")
const C_WATER    := Color("#2a4a6f")
const C_STATION  := Color("#888888")
const C_MALL     := Color("#d4b896")
const C_PETROL   := Color("#cc3333")

var _map_tex: ImageTexture
var _auto: Node3D   # now a Node3D

func setup(grid: Array, auto_node: Node3D) -> void:
	_auto = auto_node
	_bake_map(grid)
	queue_redraw()

func _bake_map(grid: Array) -> void:
	var img: Image = Image.create(MAP_W, MAP_H, false, Image.FORMAT_RGBA8)
	for y in MAP_H:
		for x in MAP_W:
			var c: Color
			match grid[y][x]:
				0: c = C_ROAD
				1: c = C_SIDEWALK
				2: c = C_BUILDING
				3: c = C_GRASS
				4: c = C_WATER
				5: c = C_STATION
				6: c = C_MALL
				7: c = C_PETROL
				_: c = C_BUILDING
			img.fill_rect(Rect2i(x * TILE_PX, y * TILE_PX, TILE_PX, TILE_PX), c)
	_map_tex = ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	if _auto:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.08, 0.08, 0.92))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.55, 0.55), false, 1.5)

	if _map_tex:
		draw_texture_rect(_map_tex, Rect2(PAD, Vector2(INNER_W, INNER_H)), false)

	if _auto:
		# Project 3D position (XZ) into minimap space
		var world_sz := Vector2(Globals.MAP_W * Globals.TILE_3D, Globals.MAP_H * Globals.TILE_3D)
		var origin_xz := Vector2(Globals.MAP_ORIGIN.x, Globals.MAP_ORIGIN.z)
		var auto_xz := Vector2(_auto.global_position.x, _auto.global_position.z)
		var norm: Vector2 = (auto_xz - origin_xz) / world_sz
		norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
		var dot: Vector2 = PAD + norm * Vector2(INNER_W, INNER_H)
		draw_circle(dot, 4.0, Color.BLACK)
		draw_circle(dot, 3.0, Color(1.0, 0.85, 0.0))
