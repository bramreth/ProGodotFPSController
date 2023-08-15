extends Camera3D

@export var target: Node3D
@export var speed: float = 44.0

func _process(delta: float) -> void:
	global_transform = global_transform.interpolate_with(target.global_transform, clamp(speed * delta, 0.0, 1.0))
	global_position = target.global_position
