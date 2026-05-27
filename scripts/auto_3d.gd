extends CharacterBody3D
## 3D auto-rickshaw — bicycle-model vehicle physics for realistic handling.
##   W / Up    = accelerate
##   S / Down  = brake / reverse
##   A / Left  = steer left
##   D / Right = steer right
## The front-wheel angle determines turning radius via the bicycle model:
##   turn_rate = speed × tan(steer_angle) / wheelbase

signal destination_reached

# ── Vehicle geometry ─────────────────────────────────────────────────────────
const WHEELBASE       := 2.0     # front-to-rear axle distance (metres)

# ── Speed limits ─────────────────────────────────────────────────────────────
const MAX_SPEED       := 18.0    # m/s forward  (~65 km/h)
const REVERSE_SPEED   := 5.0     # m/s reverse  (~18 km/h)

# ── Forces ───────────────────────────────────────────────────────────────────
const ENGINE_ACCEL    := 10.0    # forward acceleration  (m/s²)
const BRAKE_DECEL     := 24.0    # braking deceleration  (m/s²)
const COAST_DRAG      := 1.5     # constant rolling drag when coasting
const SPEED_DRAG      := 0.08    # additional speed-proportional drag

# ── Steering ─────────────────────────────────────────────────────────────────
const MAX_STEER_ANGLE := deg_to_rad(38.0)   # max front-wheel deflection
const STEER_SPEED     := 2.8                 # how fast wheel turns   (rad/s)
const STEER_RETURN    := 4.5                 # auto-center rate       (rad/s)

# ── Body tilt (3-wheeler lean) ───────────────────────────────────────────────
const TILT_MAX        := deg_to_rad(7.0)
const TILT_LERP       := 5.0

# ── Chase camera ─────────────────────────────────────────────────────────────
const CAM_DIST        := 14.0
const CAM_HEIGHT      := 7.5
const CAM_SMOOTH      := 4.5
const CAM_LOOK_AHEAD  := 5.0

# ── State ────────────────────────────────────────────────────────────────────
var _speed       := 0.0    # signed forward speed (m/s)
var _steer_angle := 0.0    # current front-wheel angle (radians)
var _heading     := 0.0    # vehicle heading (radians, 0 = +Z)
var _tilt        := 0.0    # visual body roll
var _map_bounds  := AABB()

var is_automated := false
var current_path: Array[Vector3] = []
var _path_idx := 0

@onready var _camera: Camera3D = $ChaseCamera

func _ready() -> void:
	add_to_group("auto")

func _physics_process(delta: float) -> void:
	var throttle    := 0.0
	var steer_input := 0.0

	# ── Gather input ─────────────────────────────────────────────────────
	if is_automated:
		if _path_idx < current_path.size():
			var target: Vector3 = current_path[_path_idx]
			var to_target := target - global_position
			to_target.y = 0.0
			var dist := to_target.length()
			
			if dist < 4.5:
				_path_idx += 1
			else:
				var target_heading := atan2(to_target.x, to_target.z)
				var heading_diff := wrapf(target_heading - _heading, -PI, PI)
				steer_input = clampf(heading_diff * 2.5, -1.0, 1.0)
				
				var distance_to_final := dist
				for i in range(_path_idx, current_path.size() - 1):
					distance_to_final += current_path[i].distance_to(current_path[i+1])
				
				if distance_to_final < 12.0:
					throttle = clampf((distance_to_final - 2.0) / 10.0, -1.0, 0.5)
					if _speed > distance_to_final:
						throttle = -1.0
				else:
					throttle = 1.0
					if absf(heading_diff) > 0.4:
						throttle = 0.2
		else:
			throttle = -1.0
			steer_input = 0.0
			if absf(_speed) < 0.5:
				_speed = 0.0
				is_automated = false
				current_path.clear()
				destination_reached.emit()
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			throttle = 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			throttle -= 1.0
	
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer_input = 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer_input = -1.0

	# ── Front-wheel angle ────────────────────────────────────────────────
	# Limit max steer at high speed for stability (like real power steering)
	var speed_pct     := clampf(absf(_speed) / MAX_SPEED, 0.0, 1.0)
	var eff_max_steer := MAX_STEER_ANGLE * (1.0 - speed_pct * 0.6)

	if absf(steer_input) > 0.01:
		_steer_angle = move_toward(
			_steer_angle,
			steer_input * eff_max_steer,
			STEER_SPEED * delta
		)
	else:
		# Self-centering is faster at speed (castor effect)
		var ret := STEER_RETURN * (1.0 + speed_pct * 2.0)
		_steer_angle = move_toward(_steer_angle, 0.0, ret * delta)

	# ── Throttle / brake / coast ─────────────────────────────────────────
	if throttle > 0.0:
		if _speed < -0.3:
			# Braking out of reverse
			_speed = move_toward(_speed, 0.0, BRAKE_DECEL * delta)
		else:
			# Torque curve: acceleration tapers toward top speed
			var accel := ENGINE_ACCEL * (1.0 - speed_pct * 0.4)
			_speed = minf(_speed + accel * delta, MAX_SPEED)

	elif throttle < 0.0:
		if _speed > 0.3:
			# Braking from forward
			_speed = move_toward(_speed, 0.0, BRAKE_DECEL * delta)
		else:
			_speed = maxf(_speed - ENGINE_ACCEL * 0.35 * delta, -REVERSE_SPEED)

	else:
		# Coasting — rolling resistance + proportional drag
		var drag := COAST_DRAG + SPEED_DRAG * absf(_speed)
		_speed = move_toward(_speed, 0.0, drag * delta)

	# ── Bicycle-model heading update ─────────────────────────────────────
	# turn_rate = v · tan(δ) / L   where δ = steer angle, L = wheelbase
	if absf(_speed) > 0.05:
		var turn_rate := _speed * tan(_steer_angle) / WHEELBASE
		_heading += turn_rate * delta

	# ── Apply movement ───────────────────────────────────────────────────
	var forward := Vector3(sin(_heading), 0.0, cos(_heading))
	
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1

	move_and_slide()
	
	# Re-sync speed in case we hit a wall
	var actual_hz := Vector2(velocity.x, velocity.z)
	var forward_hz := Vector2(forward.x, forward.z)
	_speed = actual_hz.dot(forward_hz)

	_clamp_to_world()

	# ── Visuals ──────────────────────────────────────────────────────────
	rotation.y = _heading

	# Body tilt driven by lateral (centripetal) acceleration
	var tilt_target := 0.0
	if absf(_speed) > 0.5:
		var lat_accel := _speed * _speed * tan(_steer_angle) / WHEELBASE
		tilt_target = clampf(lat_accel * 0.012, -1.0, 1.0) * TILT_MAX
	_tilt = lerpf(_tilt, tilt_target, TILT_LERP * delta)
	$RickshawModel.rotation.z = _tilt

	# ── Camera ───────────────────────────────────────────────────────────
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var cam_dir := Vector3(sin(_heading), 0.0, cos(_heading))
	var behind  := -cam_dir * CAM_DIST
	var target  := global_position + behind + Vector3(0.0, CAM_HEIGHT, 0.0)
	_camera.global_position = _camera.global_position.lerp(target, CAM_SMOOTH * delta)
	var look_at_pos := global_position + cam_dir * CAM_LOOK_AHEAD + Vector3(0.0, 1.2, 0.0)
	_camera.look_at(look_at_pos)

func _clamp_to_world() -> void:
	if _map_bounds.size.length() < 1.0:
		return
	var p := global_position
	p.x = clampf(p.x, _map_bounds.position.x, _map_bounds.end.x)
	p.z = clampf(p.z, _map_bounds.position.z, _map_bounds.end.z)
	if p.x != global_position.x:
		velocity.x = 0.0
		_speed *= 0.5
	if p.z != global_position.z:
		velocity.z = 0.0
		_speed *= 0.5
	global_position = p

func set_world_bounds(bounds: AABB) -> void:
	_map_bounds = bounds

func start_automated_trip(path: Array[Vector3]) -> void:
	current_path = path
	_path_idx = 0
	if current_path.size() > 1:
		_path_idx = 1
	if current_path.size() > 0:
		is_automated = true
