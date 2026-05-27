extends Node3D
## Main 3D scene controller — wires world, auto, NPCs, HUD.

const NPC_COUNT := 8

var _npc_scene := preload("res://scenes/npc_3d.tscn")

var _nearby_npcs:   Array[Node] = []
var _declined_npcs: Array[Node] = []
var _active_npc:    Node = null
var _world_ready := false

func _ready() -> void:
	$World3D.map_ready.connect(_on_map_ready)
	$HUD/PassengerCard.accepted.connect(_on_card_accepted)
	$HUD/PassengerCard.declined.connect(_on_card_declined)
	# World3D._ready() fires before Main3D._ready() (bottom-up order),
	# so the map_ready signal was already emitted. Initialize manually.
	if not $World3D.grid.is_empty():
		_on_map_ready($World3D.grid)

func _on_map_ready(grid: Array) -> void:
	if _world_ready:
		return
	_world_ready = true
	var bounds: AABB = $World3D.get_world_bounds()
	$Auto3D.set_world_bounds(bounds)
	$HUD/Minimap.setup(grid, $Auto3D)
	_spawn_npcs()

func _spawn_npcs() -> void:
	var positions: Array[Vector3] = $World3D.get_sidewalk_positions()
	positions.shuffle()
	for i in mini(NPC_COUNT, positions.size()):
		var npc: Node = _npc_scene.instantiate()
		add_child(npc)
		npc.global_position = positions[i] + Vector3(0.0, 0.15, 0.0)
		npc.proximity_entered.connect(_on_npc_proximity_entered)
		npc.proximity_exited.connect(_on_npc_proximity_exited)

func _process(_delta: float) -> void:
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
		var d: float = $Auto3D.global_position.distance_squared_to(npc.global_position)
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
