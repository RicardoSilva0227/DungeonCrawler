class_name Sword
extends Node3D

signal hit(hurtbox: Hurtbox)

@export var damage: float = 25.0
@onready var hitbox: Area3D = $Area3D

var _already_hit: Array[Hurtbox] = []

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_area_entered)

func start_swing() -> void:
	print("Sword hitbox ON")
	_already_hit.clear()
	hitbox.set_deferred("monitoring", true)

func end_swing() -> void:
	print("Sword hitbox OFF")
	hitbox.set_deferred("monitoring", false)

func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as Hurtbox

	if hurtbox == null or hurtbox in _already_hit:
		return

	_already_hit.append(hurtbox)
	hurtbox.receive_hit(damage)
	hit.emit(hurtbox)
