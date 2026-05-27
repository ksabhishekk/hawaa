extends CharacterBody3D
## 3D auto-rickshaw — proper vehicle controls:
##   W/Up    = accelerate forward
##   S/Down  = brake / reverse
##   A/Left  = steer left
##   D/Right = steer right
## Camera always follows behind the auto based on heading.

const MAX_SPEED     := 22.0   # m/s forward
const REVERSE_SPEED := 8.0    # m/s reverse
const ACCEL         := 14.0
const BRAKE_FORCE   := 28.0
const FRICTION      := 10.0
const STEER_SPEED   := 2.5    # rad/s
const TILT_MAX      := deg_to_rad(6.0)
const TILT_SPEED    := 6.0

# Chase camera
const CAM_DIST      := 14.0
const CAM_HEIGHT    := 7.5
const CAM_SMOOTH    := 5.0
const CAM_LOOK_AHEAD := 6.0   # look ahead of the auto, not at it

var _cur_speed  := 0.0
var _heading    := 0.0   # radians — 0 = +Z direction
var _tilt       := 0.0
var _map_bounds := AABB()

@onready var _camera: Camera3D = $ChaseCamera

func _ready() -> void:
	add_to_group("auto")

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer    := 0.0

	# ── Input ────────────────────────────────────────────────────────────────
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle = 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0   # allows W+S = cancel

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer = 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer = -1.0

	# ── Steering (only when moving) ──────────────────────────────────────────
	if absf(_cur_speed) > 0.5:
		var speed_ratio := clampf(absf(_cur_speed) / MAX_SPEED, 0.25, 1.0)
		var dir_sign := signf(_cur_speed)  # reverse inverts steering
		_heading += steer * STEER_SPEED * speed_ratio * dir_sign * delta

	# ── Throttle / brake / friction ──────────────────────────────────────────
	if throttle > 0.0:
		# If currently reversing, brake first
		if _cur_speed < -0.5:
			_cur_speed = move_toward(_cur_speed, 0.0, BRAKE_FORCE * delta)
		else:
			_cur_speed = move_toward(_cur_speed, MAX_SPEED, ACCEL * delta)
	elif throttle < 0.0:
		# If currently moving forward, brake first
		if _cur_speed > 0.5:
			_cur_speed = move_toward(_cur_speed, 0.0, BRAKE_FORCE * delta)
		else:
			_cur_speed = move_toward(_cur_speed, -REVERSE_SPEED, ACCEL * 0.5 * delta)
	else:
		_cur_speed = move_toward(_cur_speed, 0.0, FRICTION * delta)

	# ── Apply velocity ───────────────────────────────────────────────────────
	var forward := Vector3(sin(_heading), 0.0, cos(_heading))
	velocity = forward * _cur_speed
	velocity.y = -5.0   # keep grounded

	move_and_slide()
	_clamp_to_world()

	# ── Visuals ──────────────────────────────────────────────────────────────
	rotation.y = -_heading

	# Body tilt when steering
	var tilt_target := 0.0
	if absf(_cur_speed) > 1.0:
		tilt_target = steer * TILT_MAX * clampf(absf(_cur_speed) / MAX_SPEED, 0.0, 1.0)
	_tilt = lerpf(_tilt, tilt_target, TILT_SPEED * delta)
	$RickshawModel.rotation.z = _tilt

	# ── Camera ───────────────────────────────────────────────────────────────
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var cam_dir := Vector3(sin(_heading), 0.0, cos(_heading))
	var behind  := -cam_dir * CAM_DIST
	var target_pos := global_position + behind + Vector3(0.0, CAM_HEIGHT, 0.0)
	_camera.global_position = _camera.global_position.lerp(target_pos, CAM_SMOOTH * delta)
	# Look ahead of the auto, not directly at it
	var look_target := global_position + cam_dir * CAM_LOOK_AHEAD + Vector3(0.0, 1.2, 0.0)
	_camera.look_at(look_target)

func _clamp_to_world() -> void:
	if _map_bounds.size.length() < 1.0:
		return
	var p := global_position
	p.x = clampf(p.x, _map_bounds.position.x, _map_bounds.end.x)
	p.z = clampf(p.z, _map_bounds.position.z, _map_bounds.end.z)
	if p.x != global_position.x:
		velocity.x = 0.0
		_cur_speed *= 0.5
	if p.z != global_position.z:
		velocity.z = 0.0
		_cur_speed *= 0.5
	global_position = p

func set_world_bounds(bounds: AABB) -> void:
	_map_bounds = bounds
