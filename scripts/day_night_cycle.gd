extends Node
## Day/Night cycle — gradually shifts sky, fog, ambient, and sun over time.
## Attach to the Main3D node. References WorldEnvironment and MoonLight siblings.

# Full cycle duration in seconds (6 min = 360 sec for fast demo, increase for realism)
@export var cycle_duration: float = 360.0

# Current time of day: 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
var time_of_day: float = 0.0

# References (set in _ready)
var _env: Environment
var _sun: DirectionalLight3D
var _sky_mat: ProceduralSkyMaterial

# Precomputed color keyframes
const TIMES: Array = [0.0, 0.2, 0.3, 0.5, 0.7, 0.8, 1.0]

# Sky top colors
const SKY_TOP: Array = [
	Color(0.02, 0.01, 0.06),  # midnight
	Color(0.05, 0.03, 0.15),  # pre-dawn
	Color(0.35, 0.55, 0.85),  # sunrise
	Color(0.25, 0.55, 0.95),  # noon
	Color(0.85, 0.45, 0.20),  # sunset
	Color(0.10, 0.05, 0.18),  # dusk
	Color(0.02, 0.01, 0.06),  # midnight
]

const SKY_HORIZON: Array = [
	Color(0.06, 0.03, 0.10),
	Color(0.25, 0.15, 0.30),
	Color(0.90, 0.65, 0.40),
	Color(0.70, 0.80, 0.95),
	Color(0.95, 0.55, 0.25),
	Color(0.15, 0.08, 0.20),
	Color(0.06, 0.03, 0.10),
]

const SUN_COLOR: Array = [
	Color(0.3, 0.35, 0.6),    # moon blue
	Color(0.7, 0.5, 0.3),     # dawn warm
	Color(1.0, 0.85, 0.6),    # sunrise
	Color(1.0, 0.98, 0.92),   # noon white
	Color(1.0, 0.65, 0.3),    # sunset
	Color(0.5, 0.3, 0.5),     # dusk purple
	Color(0.3, 0.35, 0.6),    # moon blue
]

const SUN_ENERGY: Array = [0.15, 0.4, 0.9, 1.2, 0.8, 0.3, 0.15]
const AMBIENT_ENERGY: Array = [0.08, 0.15, 0.35, 0.5, 0.3, 0.12, 0.08]

const FOG_DENSITY: Array = [0.008, 0.004, 0.001, 0.0005, 0.002, 0.006, 0.008]

const AMBIENT_COLOR: Array = [
	Color(0.10, 0.07, 0.05),
	Color(0.20, 0.15, 0.10),
	Color(0.40, 0.40, 0.45),
	Color(0.50, 0.50, 0.55),
	Color(0.35, 0.25, 0.15),
	Color(0.12, 0.08, 0.10),
	Color(0.10, 0.07, 0.05),
]

func _ready() -> void:
	# Start at early evening for atmospheric first impression
	time_of_day = 0.85

	# Find environment and sun
	var we := get_parent().get_node_or_null("WorldEnvironment")
	if we and we is WorldEnvironment:
		_env = (we as WorldEnvironment).environment

	_sun = get_parent().get_node_or_null("MoonLight") as DirectionalLight3D

	if _env and _env.sky:
		_sky_mat = _env.sky.sky_material as ProceduralSkyMaterial

func _process(delta: float) -> void:
	time_of_day += delta / cycle_duration
	if time_of_day >= 1.0:
		time_of_day -= 1.0

	_update_environment()
	_update_sun()

func _update_environment() -> void:
	if not _env:
		return

	var t := time_of_day

	# Sky colors
	if _sky_mat:
		_sky_mat.sky_top_color      = _sample_color(SKY_TOP, t)
		_sky_mat.sky_horizon_color  = _sample_color(SKY_HORIZON, t)
		_sky_mat.ground_bottom_color = _sample_color(SKY_TOP, t) * 0.3
		_sky_mat.ground_horizon_color = _sample_color(SKY_HORIZON, t) * 0.5

	# Ambient
	_env.ambient_light_color   = _sample_color(AMBIENT_COLOR, t)
	_env.ambient_light_energy  = _sample_float(AMBIENT_ENERGY, t)

	# Fog
	_env.fog_density = _sample_float(FOG_DENSITY, t)
	_env.fog_light_color = _sample_color(SKY_HORIZON, t) * 0.5

	# Volumetric fog adjusts too
	if _env.volumetric_fog_enabled:
		var night_factor := 1.0 - clampf((sin(t * TAU - PI * 0.5) + 1.0) * 0.5, 0.0, 1.0)
		_env.volumetric_fog_density = lerpf(0.005, 0.025, night_factor)

func _update_sun() -> void:
	if not _sun:
		return

	var t := time_of_day

	# Rotate sun through the sky (angle based on time)
	var sun_angle := (t - 0.25) * TAU  # 0.25 = sunrise at horizon
	_sun.rotation_degrees = Vector3(-30.0 + sin(sun_angle) * 60.0, 45.0, 0.0)

	_sun.light_color  = _sample_color(SUN_COLOR, t)
	_sun.light_energy = _sample_float(SUN_ENERGY, t)

	# Shadows only during day
	_sun.shadow_enabled = t > 0.22 and t < 0.82

# ── Interpolation helpers ────────────────────────────────────────────────────

func _sample_color(colors: Array, t: float) -> Color:
	for i in range(TIMES.size() - 1):
		if t >= TIMES[i] and t <= TIMES[i + 1]:
			var local_t: float = (t - TIMES[i]) / (TIMES[i + 1] - TIMES[i])
			return (colors[i] as Color).lerp(colors[i + 1] as Color, local_t)
	return colors[0] as Color

func _sample_float(values: Array, t: float) -> float:
	for i in range(TIMES.size() - 1):
		if t >= TIMES[i] and t <= TIMES[i + 1]:
			var local_t: float = (t - TIMES[i]) / (TIMES[i + 1] - TIMES[i])
			return lerpf(values[i] as float, values[i + 1] as float, local_t)
	return values[0] as float
