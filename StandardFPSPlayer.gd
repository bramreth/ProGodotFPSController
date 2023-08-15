extends CharacterBody3D

@export_category("Player")
@export var sprint_speed: float = 6.0
@export var move_speed: float = 4.0
@export var rotation_speed: float = 0.02
@export var speed_change_rate: float = 10.0
@export var jump_height: float = 1.2

@export var bottom_clamp: float = -90.0
@export var top_clamp: float = 90.0

@export var mouse_sensitivity: float = 0.001
@export var stick_sensitivity: float = 6.0

const JUMP_TIMEOUT := 0.1
const TERMINAL_VELOCITY := 53.0
const THRESHOLD := 0.0001
const GROUNDED_OFFSET := -0.64
const GROUNDED_RADIUS := 0.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _target_speed: float
var _speed: float

var _look: Vector2
var _grounded := false

var _vertical_velocity := 0.0

var _fall_timeout := 0.0
var _jump_timeout := 0.0
	
@onready var camera_direction: Node3D = $CameraDirection

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var analog_input := Vector2.ZERO
		analog_input.x = Input.get_axis("look_right", "look_left")
		analog_input.y = Input.get_axis("look_down", "look_up")
		if not analog_input.is_zero_approx():
			_look = analog_input * delta * stick_sensitivity
		
func _physics_process(delta: float) -> void:
	jump_and_gravity(delta)
	grounded_check()
	horizontal_movement(delta)
	camera_rotation()
	_look = Vector2.ZERO

func jump_and_gravity(delta: float) -> void:
	if _grounded:
		_fall_timeout = 0.0
		
		if _vertical_velocity < 0.0:
			_vertical_velocity = -2.0
			
		if Input.is_action_pressed("jump") and _jump_timeout <= 0.0:
			# the square root of H * -2 * G = how much velocity needed to reach desired height
			_vertical_velocity = -sqrt(jump_height * 2.0 * gravity)
		
		if _jump_timeout >= 0.0:
			_jump_timeout -= delta
		
	else:
		_jump_timeout = JUMP_TIMEOUT
		
		if _fall_timeout >= 0.0:
			_fall_timeout -= delta

		if _vertical_velocity < TERMINAL_VELOCITY:
			_vertical_velocity += gravity * delta
	
func grounded_check() -> void:
	var shape_rid = PhysicsServer3D.sphere_shape_create()
	PhysicsServer3D.shape_set_data(shape_rid, GROUNDED_RADIUS)

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape_rid
	var sphere_transform: Transform3D = global_transform
	sphere_transform.origin.y += GROUNDED_OFFSET
	params.transform = sphere_transform
	
	# Ignore player
	params.exclude = [get_rid()]
	
	var collisions = get_world_3d().direct_space_state.intersect_shape(
		params
	)
	# Release the shape when done with physics queries.
	PhysicsServer3D.free_rid(shape_rid)
	
	_grounded = not collisions.is_empty()

	
func horizontal_movement(delta: float) -> void:
	_target_speed = sprint_speed if is_sprinting() else move_speed
	var movement_input := Vector2.ZERO
	movement_input.x = Input.get_axis("move_left", "move_right")
	movement_input.y = Input.get_axis("move_forward", "move_back")
	
	var magnitude = min(movement_input.length(), 1.0)
	if movement_input.is_zero_approx(): _target_speed = 0.0
	
	var horizontal_speed := Vector3(velocity.x, 0, velocity.z).length()
	
	var speed_offset := 0.01
	if horizontal_speed < _target_speed - speed_offset or horizontal_speed > _target_speed + speed_offset:
		_speed = lerpf(horizontal_speed, _target_speed * magnitude, delta * speed_change_rate)
		_speed = min(_speed, _target_speed)
		_speed = round(_speed * 1000.0) / 1000.0;
	else:
		_speed = _target_speed
		
	movement_input = movement_input.normalized()
	var input_direction = Vector3(movement_input.x, 0, movement_input.y).normalized()
	
	if not movement_input.is_zero_approx():
		input_direction = basis * input_direction
		
#	// move the player
	velocity = (input_direction.normalized() * _speed) + (Vector3.DOWN * _vertical_velocity)
	move_and_slide()
	
func camera_rotation() -> void:
	if _look.length_squared() >= THRESHOLD:
		rotate_y(_look.x)
		camera_direction.rotate_x(_look.y )#* rotation_speed)
		camera_direction.rotation.x = clamp(camera_direction.rotation.x, 
			deg_to_rad(bottom_clamp), 
			deg_to_rad(top_clamp)
		)

func is_sprinting() -> bool:
	return Input.is_action_pressed("sprint")
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_look = -event.relative * mouse_sensitivity
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event.is_action_pressed("click") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
