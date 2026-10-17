class_name HealthComponent
extends Node

signal damaged(amount: int)
signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return	 
	
	current_health = current_health - amount
	current_health = maxi(current_health, 0)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount)
	
	if(current_health == 0):
		died.emit()
	
