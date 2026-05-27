extends CharacterBody2D

signal proximity_entered(npc: Node)
signal proximity_exited(npc: Node)

const NAMES := [
	"Priya", "Rahul", "Anjali", "Suresh", "Meena",
	"Vikram", "Kavita", "Arun", "Deepa", "Mahesh"
]
const DESTINATIONS := [
	"Seawoods Station", "Nexus Mall", "Seawoods Lake",
	"Nerul Station", "Sector 44 Bus Stop", "Palm Beach Road End"
]

var passenger_name: String = ""
var destination: String = ""
var fare: int = 0

var _pulse_t := 0.0

func _ready() -> void:
	passenger_name = NAMES[randi() % NAMES.size()]
	destination    = DESTINATIONS[randi() % DESTINATIONS.size()]
	fare           = randi_range(40, 150)

	# NPC body doesn't block the auto — sits on sidewalk, different layer
	collision_layer = 2
	collision_mask  = 0

	# Proximity area watches for auto (layer 1)
	$ProximityArea.collision_layer = 0
	$ProximityArea.collision_mask  = 1

	_build_sprite()
	_style_label()

	$ProximityArea.body_entered.connect(_on_body_entered)
	$ProximityArea.body_exited.connect(_on_body_exited)

func _build_sprite() -> void:
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("#4a90d9"))
	$Sprite2D.texture = ImageTexture.create_from_image(img)

func _style_label() -> void:
	$ExclLabel.add_theme_font_size_override("font_size", 20)
	$ExclLabel.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))

func _process(delta: float) -> void:
	_pulse_t += delta * 4.0
	$ExclLabel.modulate.a = 0.55 + sin(_pulse_t) * 0.45

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("auto"):
		proximity_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("auto"):
		proximity_exited.emit(self)
