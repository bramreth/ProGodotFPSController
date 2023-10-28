extends CharacterBody3D
class_name Player

## How fast the player moves on the ground
@export var base_speed := 6.5
## How high the player can jump in meters
@export var jump_height := 1.0
## How fast the player falls after reaching max jump height
@export var fall_multiplier := 2.5

@export_category("Camera")
@export var mouse_sensitivity: float = 0.001
@export var bottom_clamp: float = -90.0
@export var top_clamp: float = 90.0

@export_category("Stats")
@export var max_health: float = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _look := Vector2.ZERO

var can_double_jump := false

@onready var camera: Camera3D = $SmoothCamera
@onready var camera_target: Node3D = $CameraTarget
@onready var camera_origin = camera_target.position
@onready var weapons: Node3D = %Weapons
@onready var weapons_origin = weapons.position

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	juice_animations(delta)
	frame_camera_rotation()
	
	# Add the gravity.
	if not is_on_floor():
		if is_floaty():
			velocity.y -= gravity * delta
		else:
			# Double fall speed, after peak of jump
			velocity.y -= gravity * delta * fall_multiplier
	else:
		can_double_jump = true
		
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept"):
		var force = sqrt(jump_height * 2.0 * gravity)
		if is_on_floor():
			velocity.y = force
#		elif can_double_jump == true:
#			velocity.y = force
#			can_double_jump = false
	
	# handle Movement.
	var direction = get_movement_direction()
	if direction:
		velocity.x = direction.x * base_speed
		velocity.z = direction.z * base_speed
	else:
		velocity.x = move_toward(velocity.x, 0, base_speed)
		velocity.z = move_toward(velocity.z, 0, base_speed)
	
	handle_shooting()
		
	move_and_slide()
	
func get_movement_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
func frame_camera_rotation() -> void:
	rotate_y(_look.x)
	camera_target.rotate_x(_look.y)
	camera_target.rotation.x = clamp(camera_target.rotation.x, 
		deg_to_rad(bottom_clamp), 
		deg_to_rad(top_clamp)
	)
	_look = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_look = -event.relative * mouse_sensitivity
	if event.is_action_pressed("click") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_shooting() -> void:
	if Input.is_action_pressed("click"):
		var weapon = weapons.get_children().front()
		if weapon.can_shoot():
			weapons.position.z += weapon.recoil
			var collision_data = camera.fire_ray(weapon.weapon_range)
			var collider = collision_data[0]
			var point = collision_data[1]
			var normal = collision_data[2]
			
			weapon.shoot(collider, point, normal)

func juice_animations(delta: float) -> void:
	var weapon_sway = weapons_origin
	# moving weapon sway
	weapon_sway -= (basis.inverse() * velocity * 0.02).limit_length(0.25)
	# aiming weapon sway
	weapon_sway += (Vector3(_look.x, _look.y, 0.0) * 0.5).limit_length(0.25)
	weapons.position = weapons.position.lerp(weapon_sway, delta * 8)
		
func death() -> void:
	get_tree().reload_current_scene()

func is_floaty() -> bool:
	# if holding jump and ascending be floaty
	return (velocity.y >= 0 and Input.is_action_pressed("ui_accept"))
