class_name DodgeComponent
extends Node

signal dodge_started
signal dodge_finished

@export var dodge_speed: float = 4.5
@export var dodge_duration: float = 0.8
@export var dodge_cooldown: float = 0.5

@export var iframe_start: float = 0.10
@export var iframe_end: float = 0.45

var is_dodging: bool = false
var is_invincible: bool = false

var dodge_direction: Vector3 = Vector3.ZERO
var dodge_elapsed: float = 0.0
var cooldown_remaining: float = 0.0


func can_dodge() -> bool:
	return not is_dodging and cooldown_remaining <= 0.0

func try_dodge(direction: Vector3) -> bool:
	if not can_dodge():
		return false

	if direction.length_squared() < 0.001:
		return false

	# Direction is captured once and cannot change mid-roll.
	dodge_direction = direction.normalized()

	dodge_elapsed = 0.0
	is_dodging = true
	is_invincible = false

	dodge_started.emit()
	return true

func update_dodge(delta: float) -> Vector3:
	if not is_dodging:
		return Vector3.ZERO

	dodge_elapsed += delta

	is_invincible = (
		dodge_elapsed >= iframe_start
		and dodge_elapsed < iframe_end
	)

	var result := dodge_direction * dodge_speed

	if dodge_elapsed >= dodge_duration:
		is_dodging = false
		is_invincible = false
		cooldown_remaining = dodge_cooldown
		dodge_finished.emit()

	return result

func update_cooldown(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(
			cooldown_remaining - delta,
			0.0
		)
