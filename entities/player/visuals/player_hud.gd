class_name PlayerHUD
extends CanvasLayer

@onready var health_progress: ProgressBar = $HealthContainer/HealthProgressBar
@onready var health_label: Label = $HealthContainer/HealthLabel

var health: HealthComponent


func setup(player_health: HealthComponent) -> void:
	health = player_health

	health.health_changed.connect(_update_health)

	# Initialize immediately because the HealthComponent
	# may have emitted its initial signal before the HUD connected.
	_update_health(health.current_health, health.max_health)


func _update_health(current: float, maximum: float) -> void:
	health_progress.max_value = maximum
	health_progress.value = current

	health_label.text = "%d / %d" % [
		roundi(current),
		roundi(maximum)
	]
