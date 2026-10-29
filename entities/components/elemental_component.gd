class_name ElementalComponent
extends Node

#region Exports
@onready var health: HealthComponent = $"../HealthComponent"
#endregion

#region Signals
signal element_applied(element: ElementTypes.Element)
signal condition_added(condition: ElementTypes.Condition)
signal condition_removed(condition: ElementTypes.Condition)
#endregion

#region Configuration
const CONDITION_TICK_INTERVAL: float = 0.1

const BURNING_DAMAGE: float = 5.0
const BURNING_TICK_INTERVAL: float = 1.0
#endregion

#region State
var active_conditions: Dictionary[int, float] = {}
var condition_tick_elapsed: Dictionary[int, float] = {}
#endregion

#region Node References
var condition_timer: Timer
#endregion

#region Lifecycle
func _ready() -> void:
	condition_timer = Timer.new()
	condition_timer.wait_time = CONDITION_TICK_INTERVAL
	condition_timer.one_shot = false
	condition_timer.timeout.connect(_on_condition_timer_timeout)

	add_child(condition_timer)
#endregion

#region Elemental Application
func apply_element(element: ElementTypes.Element) -> void:
	ElementalReactionResolver.resolve(self, element)
	element_applied.emit(element)
#endregion

#region Conditions
func has_condition(condition: ElementTypes.Condition) -> bool:
	return active_conditions.has(condition)


func add_condition(condition: ElementTypes.Condition, duration: float) -> void:
	if duration <= 0.0:
		return

	var already_active := has_condition(condition)

	active_conditions[condition] = duration
	if not already_active:
		condition_tick_elapsed[condition] = 0.0
		condition_added.emit(condition)

	if condition_timer.is_stopped():
		condition_timer.start()


func remove_condition(condition: ElementTypes.Condition) -> void:
	if not has_condition(condition):
		return

	active_conditions.erase(condition)
	condition_tick_elapsed.erase(condition)
	condition_removed.emit(condition)

	if active_conditions.is_empty():
		condition_timer.stop()
#endregion

#region Condition Processing
func _on_condition_timer_timeout() -> void:
	var expired_conditions: Array[int] = []

	for condition in active_conditions:
		active_conditions[condition] -= CONDITION_TICK_INTERVAL

		match condition:
			ElementTypes.Condition.BURNING:
				var elapsed: float = condition_tick_elapsed.get(condition, 0.0)
				elapsed += CONDITION_TICK_INTERVAL

				if elapsed >= BURNING_TICK_INTERVAL - 0.0001:
					elapsed -= BURNING_TICK_INTERVAL

					if health != null:
						health.take_damage(
							BURNING_DAMAGE,
							HealthComponent.DamageType.DAMAGE_OVER_TIME
						)

				condition_tick_elapsed[condition] = elapsed

		if active_conditions[condition] <= 0.0:
			expired_conditions.append(condition)

	for condition in expired_conditions:
		remove_condition(condition)
#endregion
