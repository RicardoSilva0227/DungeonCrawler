extends StaticBody3D

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	
func _on_health_changed(current, max_value) -> void:
	pass
	
func _on_died() -> void:
	queue_free()
