extends CharacterBody2D

const SPEED      := 200.0
const ACCEL      := 600.0
const FRICTION   := 800.0
var _map_bounds := Rect2(-1600.0, -1200.0, 3200.0, 2400.0)
const TILT_MAX   := deg_to_rad(10.0)
const TILT_SPEED := 8.0

var _tilt := 0.0

func _ready() -> void:
	add_to_group("auto")
	_build_placeholder_sprite()

func _build_placeholder_sprite() -> void:
	var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	$Sprite2D.texture = ImageTexture.create_from_image(img)
	$Sprite2D.scale   = Vector2(32.0, 48.0)
	$Sprite2D.modulate = Color(1.0, 0.85, 0.0)  # rickshaw yellow

func _physics_process(delta: float) -> void:
	var input_dir := _get_input()

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir.normalized() * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
	_clamp_to_world()

	if velocity.length_squared() > 100.0:
		# +PI/2 because sprite is drawn facing up (−Y) at rotation 0
		rotation = lerp_angle(rotation, velocity.angle() + PI * 0.5, 10.0 * delta)

	var tilt_target := 0.0
	if velocity.length_squared() > 100.0:
		tilt_target = input_dir.x * TILT_MAX
	_tilt = lerpf(_tilt, tilt_target, TILT_SPEED * delta)
	$Sprite2D.rotation = _tilt

func _clamp_to_world() -> void:
	var cx: float = clampf(global_position.x, _map_bounds.position.x, _map_bounds.end.x)
	var cy: float = clampf(global_position.y, _map_bounds.position.y, _map_bounds.end.y)
	if cx != global_position.x:
		velocity.x = 0.0
	if cy != global_position.y:
		velocity.y = 0.0
	global_position = Vector2(cx, cy)

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	var cam: Camera2D = $Camera2D
	cam.limit_left   = left
	cam.limit_top    = top
	cam.limit_right  = right
	cam.limit_bottom = bottom
	_map_bounds = Rect2(left, top, right - left, bottom - top)

func _get_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	return dir
