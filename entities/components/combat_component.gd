class_name CombatComponent
extends Node

const COMBO_ANIMATIONS: Array[String] = [
	"default/sword_attack_1",
	"default/sword_attack_2",
	"default/sword_attack_3"
]

@export var attack_move_speed: float = 2.5
@export var attack_move_duration: float = 0.18
@export_range(0.0, 1.0) var dodge_cancel_threshold: float = 0.75

var attack_move_time: float = 0.0
var attack_direction: Vector3 = Vector3.ZERO

var combo_index: int = 0
var attack_queued: bool = false
var is_attacking: bool = false

var anim: AnimationPlayer
var sword: Sword
var face_mouse_callback: Callable


func setup(animation_player: AnimationPlayer, equipped_sword: Sword, face_callback: Callable) -> void:
	anim = animation_player
	sword = equipped_sword
	face_mouse_callback = face_callback

	anim.animation_finished.connect(_on_animation_finished)

func try_attack() -> void:
	if is_attacking:
		if combo_index < COMBO_ANIMATIONS.size() - 1:
			attack_queued = true
		return

	combo_index = 0
	_start_attack()

func _start_attack() -> void:
	is_attacking = true
	attack_queued = false

	face_mouse_callback.call()
	var player := get_parent() as CharacterBody3D
	var visuals := player.get_node("Visuals") as Node3D

	attack_direction = -visuals.global_transform.basis.z
	attack_direction.y = 0.0
	attack_direction = attack_direction.normalized()

	attack_move_time = attack_move_duration
	anim.play(COMBO_ANIMATIONS[combo_index], 0.1)

func _on_animation_finished(animation_name: StringName) -> void:
	if not is_attacking:
		return

	if animation_name != StringName(COMBO_ANIMATIONS[combo_index]):
		return

	if attack_queued and combo_index < COMBO_ANIMATIONS.size() - 1:
		sword.end_swing()
		combo_index += 1
		_start_attack()
	else:
		is_attacking = false
		attack_queued = false
		combo_index = 0
		sword.end_swing()

func get_attack_velocity(delta: float) -> Vector3:
	if not is_attacking or attack_move_time <= 0.0:
		return Vector3.ZERO

	attack_move_time = maxf(attack_move_time - delta, 0.0)
	return attack_direction * attack_move_speed

func can_dodge_cancel() -> bool:
	if not is_attacking:
		return true

	var animation_length := anim.current_animation_length

	if animation_length <= 0.0:
		return false

	var progress := anim.current_animation_position / animation_length
	return progress >= dodge_cancel_threshold

func cancel_attack() -> void:
	if not is_attacking:
		return

	sword.end_swing()

	is_attacking = false
	attack_queued = false
	combo_index = 0

	# Prevent any leftover attack lunge.
	attack_move_time = 0.0

	anim.stop()
