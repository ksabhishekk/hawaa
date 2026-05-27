extends Node2D

const HALF  := 1000.0
const GRID  := 200.0
const GROUND_COLOR  := Color(0.14, 0.14, 0.14)
const GRID_COLOR    := Color(0.22, 0.22, 0.22)
const BORDER_COLOR  := Color(0.55, 0.55, 0.55)

func _draw() -> void:
	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), GROUND_COLOR)

	var x := -HALF + GRID
	while x < HALF:
		draw_line(Vector2(x, -HALF), Vector2(x, HALF), GRID_COLOR, 1.0)
		x += GRID

	var y := -HALF + GRID
	while y < HALF:
		draw_line(Vector2(-HALF, y), Vector2(HALF, y), GRID_COLOR, 1.0)
		y += GRID

	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), BORDER_COLOR, false, 3.0)
