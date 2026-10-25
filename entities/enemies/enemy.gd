class_name Enemy
extends CharacterBody3D

#region Node References
@onready var health: HealthComponent = $HealthComponent
@onready var detection_area: Area3D = $DetectionArea
@onready var visuals: Node3D = $Visuals
@onready var anim: AnimationPlayer = visuals.find_child(
	"AnimationPlayer", true, false
)
@onready var sword: Sword = visuals.find_child(
	"SM_Wep_Sword_04", true, false
)
#endregion

#region Exports
@export var movement_speed: float = 2.0
@export var stopping_distance: float = 1.2
@export var turn_speed: float = 8.0

@export var attack_cooldown: float = 1.0
@export var attack_animation: String = "default/sword_outward_swing_combat_duplicated"
#endregion

#region State
var target: CharacterBody3D = null
var is_hurt: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_attack_animation_finished)
#endregion

#region Detection
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = body as CharacterBody3D
		print("Enemy detected player!")


func _on_body_exited(body: Node3D) -> void:
	if body == target:
		target = null
		print("Player left detection range.")
#endregion

#region Health
func _on_health_changed(current: float, max_value: float) -> void:
	if current <= 0.0:
		return

	if not anim.has_animation("default/hit_reaction"):
		push_warning("Enemy hit reaction animation not found.")
		return

	is_hurt = true
	is_attacking = false
	attack_cooldown_remaining = attack_cooldown

	sword.end_swing()

	velocity.x = 0.0
	velocity.z = 0.0

	anim.play("default/hit_reaction", 0.1)


func _on_died() -> void:
	queue_free()
#endregion

#region Movement
func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

	if is_attacking or is_hurt:
		velocity.x = 0.0
		velocity.z = 0.0
	elif target == null:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var direction := target.global_position - global_position
		direction.y = 0.0

		if direction.length() > stopping_distance:
			direction = direction.normalized()
			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			_try_attack()

	if not is_on_floor():
		velocity += get_gravity() * delta

	_face_target(delta)
	move_and_slide()
	_animations()

func _face_target(delta: float) -> void:
	if target == null or is_hurt:
		return

	var direction := target.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	var target_angle := atan2(-direction.x, -direction.z)

	visuals.global_rotation.y = lerp_angle(
		visuals.global_rotation.y,
		target_angle,
		turn_speed * delta
	)
#endregion

#region Animations
func _animations() -> void:
	if anim == null or is_attacking or is_hurt:
		return

	var is_moving := Vector2(velocity.x, velocity.z).length_squared() > 0.01
	var target_animation := "default/walk" if is_moving else "default/idle"

	if anim.current_animation != target_animation:
		anim.play(target_animation, 0.2)
#endregion

#region Combat
var is_attacking: bool = false
var attack_cooldown_remaining: float = 0.0


func _try_attack() -> void:
	if is_attacking or attack_cooldown_remaining > 0.0:
		return

	if not anim.has_animation(attack_animation):
		push_warning("Enemy attack animation not found: " + attack_animation)
		return

	is_attacking = true
	velocity.x = 0.0
	velocity.z = 0.0

	anim.play(attack_animation, 0.1)


func _on_attack_animation_finished(animation_name: StringName) -> void:
	if animation_name == "default/hit_reaction":
		is_hurt = false
		return

	if not is_attacking:
		return

	if animation_name != StringName(attack_animation):
		return

	sword.end_swing()
	is_attacking = false
	attack_cooldown_remaining = attack_cooldown
#endregion
