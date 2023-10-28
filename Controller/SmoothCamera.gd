extends Camera3D

@export var target: Node3D
@export var speed: float = 22.0

@onready var player_ray: RayCast3D = $PlayerRay

func _ready() -> void:
	player_ray.add_exception(get_parent())
	
func fire_ray(distance: float) -> Array:
	player_ray.target_position.z = - distance
	player_ray.force_raycast_update()
	return [player_ray.get_collider(), player_ray.get_collision_point(), player_ray.get_collision_normal()]
	
func _process(delta: float) -> void:
	global_transform = global_transform.interpolate_with(
		target.global_transform, 
		clamp(speed * delta, 0.0, 1.0)
		)
	global_position = target.global_position
