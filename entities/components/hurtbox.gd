extends Area3D

@export var health: HealthComponent

func _ready() -> void:
	assert(health != null, "Hurtbox needs a HealthComponent assigned")

func receive_hit(amount: float) -> void:
	health.take_damage(amount)
