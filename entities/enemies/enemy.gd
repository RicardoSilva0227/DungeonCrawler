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
@onready var elemental: ElementalComponent = $ElementalComponent
@onready var status_label: Label3D = $StatusLabel
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
var is_dead: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_attack_animation_finished)
	elemental.condition_added.connect(_update_status_label.unbind(1))
	elemental.condition_removed.connect(_update_status_label.unbind(1))

	_update_status_label()
	#var elemental: ElementalComponent = $ElementalComponent
	#
	#elemental.apply_element(ElementTypes.Element.OIL)
#
	#print("Oiled: ", elemental.has_condition(ElementTypes.Condition.OILED))
#
	#elemental.apply_element(ElementTypes.Element.FIRE)
#
	#print("Oiled: ", elemental.has_condition(ElementTypes.Condition.OILED))
	#print("Burning: ", elemental.has_condition(ElementTypes.Condition.BURNING))
#
	#elemental.condition_removed.connect(
	#func(condition: int):
		#print(name, " lost condition: ", condition)
	#)

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

#region Damage and Health
func _on_damaged(_amount: float, damage_type: HealthComponent.DamageType) -> void:
	if is_dead or health.current_health <= 0.0:
		return

	if damage_type == HealthComponent.DamageType.DAMAGE_OVER_TIME:
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
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_hurt = false

	sword.end_swing()

	velocity.x = 0.0
	velocity.z = 0.0

	anim.play("default/death_01", 0.1)
#endregion

#region Movement
func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

	if is_attacking or is_hurt or is_dead:
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
	if target == null or is_hurt or is_dead:
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
	if anim == null or is_attacking or is_hurt or is_dead:
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
	if is_dead or is_hurt or is_attacking or attack_cooldown_remaining > 0.0:
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
	
	if animation_name == "default/death_01" and is_dead:
		queue_free()
		return

	if not is_attacking:
		return

	if animation_name != StringName(attack_animation):
		return

	sword.end_swing()
	is_attacking = false
	attack_cooldown_remaining = attack_cooldown
#endregion

#region Status
func _update_status_label() -> void:
	var labels: Array[String] = []

	if elemental.has_condition(ElementTypes.Condition.OILED):
		labels.append("OILED")

	if elemental.has_condition(ElementTypes.Condition.BURNING):
		labels.append("BURNING")

	if elemental.has_condition(ElementTypes.Condition.WET):
		labels.append("WET")

	if elemental.has_condition(ElementTypes.Condition.SHOCKED):
		labels.append("SHOCKED")

	status_label.text = " | ".join(labels)
	status_label.visible = not labels.is_empty()
#endregion
