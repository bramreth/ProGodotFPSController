extends Node3D

@export var recoil := 0.15 # meters
@export var weapon_range := 22.0 # meters
@export var automatic := true
@export var cooldown := 0.1
@export var hit_marker: PackedScene

@onready var spark: GPUParticles3D = $Spark
@onready var muzzle_flash: GPUParticles3D = $MuzzleFlash
@onready var timer: Timer = $Timer

func _ready() -> void:
	spark.global_transform = Transform3D()


func shoot(collider, point: Vector3, normal: Vector3) -> void:
	muzzle_flash.restart()
	
	if collider:
		var particle_transform = Transform3D()
		particle_transform.origin = point
		if abs(Vector3.UP.dot(normal)) > 0.5:
			particle_transform = particle_transform.looking_at(
				point + normal, Vector3.RIGHT, false
				)
		else:
			particle_transform = particle_transform.looking_at(
				point + normal, Vector3.UP, false
				)
#		spark.emit_particle(particle_transform, normal * 0.1, Color.BLACK, Color.BLACK, 7)
		var hit = hit_marker.instantiate()
		add_child(hit)
		hit.global_transform = particle_transform
	timer.start(cooldown)
	
	

func can_shoot() -> bool:
	return timer.is_stopped()
