
class_name Hurtbox
extends Area3D

@export var health: HealthComponent

var is_invincible: bool = false


func _ready() -> void:
	assert(health != null, "Hurtbox needs a HealthComponent assigned")


func receive_hit(amount: float) -> void:
	if is_invincible:
		print('Iframe')
		return

	health.take_damage(amount)
