class_name Sword
extends Node3D

signal hit(hurtbox: Hurtbox)

@onready var hitbox: Area3D = $Area3D

var _already_hit: Array[Hurtbox] = []

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_area_entered)

func start_swing() -> void:
	_already_hit.clear()
	hitbox.set_deferred("monitoring", true)

func end_swing() -> void:
	hitbox.set_deferred("monitoring", false)

func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	_already_hit.append(hurtbox)
	hit.emit(hurtbox)
