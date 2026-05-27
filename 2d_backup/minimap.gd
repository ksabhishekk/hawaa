extends Control

const MAP_W   := 100
const MAP_H   := 75
const TILE_PX := 1
const INNER_W := float(MAP_W * TILE_PX)  # 100
const INNER_H := float(MAP_H * TILE_PX)  # 75
# Center the 100×75 inner area inside the 150×150 control
const PAD     := Vector2(25.0, 37.0)
const MAP_OFF := Vector2(-1600.0, -1200.0)
const MAP_SZ  := Vector2(3200.0, 2400.0)

const C_ROAD     := Color("#2a2a2a")
const C_SIDEWALK := Color("#c8b89a")
const C_BUILDING := Color("#e8d5b0")
const C_GRASS    := Color("#4a7c3f")
const C_WATER    := Color("#4a7abf")
const C_STATION  := Color("#888888")
const C_MALL     := Color("#d4b896")
const C_PETROL   := Color("#cc3333")

var _map_tex: ImageTexture
var _auto: Node2D

func setup(grid: Array, auto_node: Node2D) -> void:
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
		var norm: Vector2 = (_auto.global_position - MAP_OFF) / MAP_SZ
		norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
		var dot: Vector2 = PAD + norm * Vector2(INNER_W, INNER_H)
		draw_circle(dot, 4.0, Color.BLACK)
		draw_circle(dot, 3.0, Color(1.0, 0.85, 0.0))
