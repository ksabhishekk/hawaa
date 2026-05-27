extends CharacterBody3D
## 3D NPC — simple CSG humanoid standing on sidewalks.

signal proximity_entered(npc: Node)
signal proximity_exited(npc: Node)

const NAMES := [
	"Priya", "Rahul", "Anjali", "Suresh", "Meena",
	"Vikram", "Kavita", "Arun", "Deepa", "Mahesh"
]
const DESTINATIONS := [
	"Seawoods Station", "Nexus Mall", "Nerul Station",
	"DY Patil Stadium", "Belapur Station", "Sanpada Station",
	"CBD Belapur", "Palm Beach Galleria"
]

var passenger_name: String = ""
var destination: String = ""
var fare: int = 0

var _pulse_t := 0.0

func _ready() -> void:
	passenger_name = NAMES[randi() % NAMES.size()]
	destination    = DESTINATIONS[randi() % DESTINATIONS.size()]
	fare           = randi_range(40, 150)

	collision_layer = 2
	collision_mask  = 0

	$ProximityArea.collision_layer = 0
	$ProximityArea.collision_mask  = 1

	$ProximityArea.body_entered.connect(_on_body_entered)
	$ProximityArea.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_pulse_t += delta * 3.0
	# Gentle bob animation
	$Model.position.y = 0.9 + sin(_pulse_t) * 0.05
	# Glow pulsates
	$GlowLight.light_energy = 0.5 + sin(_pulse_t * 2.0) * 0.3

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("auto"):
		proximity_entered.emit(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("auto"):
		proximity_exited.emit(self)
