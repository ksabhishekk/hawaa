extends Node2D

const NPC_COUNT  := 5
const T_SIDEWALK := 1  # mirrors map_gen.gd

var _npc_scene := preload("res://scenes/npc.tscn")

var _nearby_npcs:  Array[Node] = []
var _declined_npcs: Array[Node] = []
var _active_npc: Node = null

func _ready() -> void:
	$TileMap.map_ready.connect(_on_map_ready)
	$HUD/PassengerCard.accepted.connect(_on_card_accepted)
	$HUD/PassengerCard.declined.connect(_on_card_declined)

func _on_map_ready(grid: Array) -> void:
	var bounds: Rect2 = $TileMap.get_world_bounds()
	$Auto.set_camera_limits(
		int(bounds.position.x), int(bounds.position.y),
		int(bounds.end.x),      int(bounds.end.y)
	)
	$HUD/Minimap.setup(grid, $Auto)
	_spawn_npcs(grid)

func _spawn_npcs(grid: Array) -> void:
	var sidewalks: Array[Vector2i] = []
	for y in grid.size():
		for x in grid[y].size():
			if grid[y][x] == T_SIDEWALK:
				sidewalks.append(Vector2i(x, y))
	sidewalks.shuffle()
	for i in mini(NPC_COUNT, sidewalks.size()):
		var tile := sidewalks[i]
		var npc: Node = _npc_scene.instantiate()
		add_child(npc)
		npc.global_position = $TileMap.tile_center_world(tile.x, tile.y)
		npc.proximity_entered.connect(_on_npc_proximity_entered)
		npc.proximity_exited.connect(_on_npc_proximity_exited)

func _process(_delta: float) -> void:
	# Re-evaluate nearest when multiple NPCs are in range
	if _nearby_npcs.size() > 1:
		_update_card()

func _on_npc_proximity_entered(npc: Node) -> void:
	if not _nearby_npcs.has(npc):
		_nearby_npcs.append(npc)
	_update_card()

func _on_npc_proximity_exited(npc: Node) -> void:
	_nearby_npcs.erase(npc)
	_declined_npcs.erase(npc)
	_update_card()

func _update_card() -> void:
	var nearest := _get_nearest_npc()
	if nearest == _active_npc:
		return
	_active_npc = nearest
	if nearest:
		$HUD/PassengerCard.show_for(nearest)
	else:
		$HUD/PassengerCard.hide_card()

func _get_nearest_npc() -> Node:
	var best: Node = null
	var best_d := INF
	for npc in _nearby_npcs:
		if _declined_npcs.has(npc):
			continue
		var d: float = $Auto.global_position.distance_squared_to(npc.global_position)
		if d < best_d:
			best_d = d
			best = npc
	return best

func _on_card_accepted() -> void:
	if not _active_npc:
		return
	print("Route to: ", _active_npc.destination)
	_nearby_npcs.erase(_active_npc)
	_active_npc.queue_free()
	_active_npc = null
	$HUD/PassengerCard.hide_card()

func _on_card_declined() -> void:
	if not _active_npc:
		return
	_declined_npcs.append(_active_npc)
	_active_npc = null
	$HUD/PassengerCard.hide_card()
