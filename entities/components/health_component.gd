
class_name HealthComponent
extends Node

# SIGNALS: the emitter announces that something happened; it doesn't know or
# care who is listening. Other nodes subscribe with `signal.connect(function)`
# (once, usually in _ready), and that function then runs every time the signal
# is emitted with `signal.emit(args)`.
## Emitted after health changes. Use it to update UI.
signal health_changed(current: float, max_value: float)
## Emitted when damage is actually applied (not when it's ignored).
signal damaged(amount: float, damage_type: DamageType)
## Emitted once, when health reaches 0. Always emitted last.
signal died

@export var max_health: float = 100.0
var current_health: float

enum DamageType {
	DIRECT,
	DAMAGE_OVER_TIME
}

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float, damage_type: DamageType = DamageType.DIRECT) -> void:
	if current_health <= 0.0 or amount <= 0.0:
			return

	var actual_damage := minf(amount, current_health)
	current_health = maxf(current_health - actual_damage, 0.0)

	health_changed.emit(current_health, max_health)
	damaged.emit(actual_damage, damage_type)

	if current_health == 0.0:
		died.emit()
