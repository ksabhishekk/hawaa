extends Node

# ── Legacy 2D constants (kept for reference) ──
const WORLD_SIZE    := 2000.0
const WORLD_HALF    := WORLD_SIZE / 2.0
const AUTO_SPEED    := 200.0
const AUTO_ACCEL    := 600.0
const AUTO_FRICTION := 800.0

# ── 3D world constants ──
const TILE_3D       := 4.0          # each grid cell = 4 × 4 metres
const MAP_W         := 100
const MAP_H         := 75
const MAP_ORIGIN    := Vector3(-MAP_W * TILE_3D * 0.5, 0.0, -MAP_H * TILE_3D * 0.5)

# Building heights
const BLDG_H_MIN    := 4.0
const BLDG_H_MAX    := 12.0

# Tree sizes
const TREE_TRUNK_H  := 2.5
const TREE_CANOPY_R := 2.2

# Street lamp spacing (every N tiles along road edges)
const LAMP_SPACING  := 5
const LAMP_HEIGHT   := 5.0
const LAMP_RANGE    := 12.0

# Road
const ROAD_Y        := 0.02         # tiny lift so road sits above ground
const SIDEWALK_Y    := 0.12
