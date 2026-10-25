
extends CharacterBody3D

#region Exports
@export var speed: float = 2.0
@export var run_speed: float = 4.0
@export var turn_speed: float = 12.0
@export var camera_yaw_degrees: float = 80.0
#endregion

#region Node References
@onready var visuals: Node3D = $Visuals
@onready var anim: AnimationPlayer = visuals.find_child(
	"AnimationPlayer", true, false
)
@onready var sword: Sword = visuals.find_child(
	"SM_Wep_Sword_04", true, false
)

@onready var combat: CombatComponent = $CombatComponent
@onready var dodge: DodgeComponent = $DodgeComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hud: PlayerHUD = $PlayerHud
@onready var hurtbox: Hurtbox = $Hurtbox
#endregion

#region Lifecycle
func _ready() -> void:
	combat.setup(anim, sword, _face_mouse)
	hud.setup(health)


func _physics_process(delta: float) -> void:
	var direction := _get_movement_direction()
	var is_moving := direction.length_squared() > 0.01
	var is_sprinting := is_moving and Input.is_action_pressed("sprint")
	var current_speed := run_speed if is_sprinting else speed

	dodge.update_cooldown(delta)

	var was_dodging := dodge.is_dodging

	if was_dodging:
		var dodge_velocity := dodge.update_dodge(delta)
		velocity.x = dodge_velocity.x
		velocity.z = dodge_velocity.z

	elif combat.is_attacking:
		var attack_velocity := combat.get_attack_velocity(delta)
		velocity.x = attack_velocity.x
		velocity.z = attack_velocity.z

	else:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	
	# Update damage immunity after advancing the dodge timer.
	hurtbox.is_invincible = dodge.is_invincible

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Preserve movement-based rotation during attacks.
	# Lock rotation while dodging.
	if is_moving and not was_dodging:
		var target_angle := atan2(-direction.x, -direction.z)

		visuals.rotation.y = lerp_angle(
			visuals.rotation.y,
			target_angle,
			turn_speed * delta
		)

	move_and_slide()

	if not was_dodging:
		_animations(is_moving, is_sprinting)
#endregion

#region Input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if not dodge.is_dodging:
			combat.try_attack()

	elif event.is_action_pressed("dodge"):
		_try_dodge()
	
	elif event.is_action_pressed("debug_damage"):
		hurtbox.receive_hit(10.0)

func _get_movement_direction() -> Vector3:
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	return Vector3(input.x, 0.0, input.y).rotated(
		Vector3.UP,
		deg_to_rad(camera_yaw_degrees)
	)
#endregion

#region Combat
func _get_mouse_ground_point() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var mouse := get_viewport().get_mouse_position()

	var origin := camera.project_ray_origin(mouse)
	var ray_direction := camera.project_ray_normal(mouse)

	var plane := Plane(Vector3.UP, global_position.y)
	return plane.intersects_ray(origin, ray_direction)


func _face_mouse() -> void:
	var point = _get_mouse_ground_point()

	if point == null:
		return

	var direction: Vector3 = point - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.01:
		return

	visuals.rotation.y = atan2(-direction.x, -direction.z)
#endregion

#region Dodge
func _try_dodge() -> void:
	if not combat.can_dodge_cancel():
		return

	if not dodge.can_dodge():
		return

	# WASD determines the dodge direction.
	var direction := _get_movement_direction()

	# No movement input: dodge in the facing direction.
	if direction.length_squared() < 0.01:
		direction = -visuals.global_transform.basis.z

	direction.y = 0.0
	direction = direction.normalized()

	if dodge.try_dodge(direction):
		combat.cancel_attack()

		# Face the direction of the roll.
		visuals.rotation.y = atan2(
			-direction.x,
			-direction.z
		)

		var roll_animation := "default/dodge_roll"
		var roll_length := anim.get_animation(roll_animation).length
		var roll_speed := roll_length / dodge.dodge_duration

		anim.play(roll_animation, 0.05, roll_speed)
#endregion

#region Animations
func _animations(is_moving: bool, is_sprinting: bool) -> void:
	if combat.is_attacking or dodge.is_dodging:
		return

	var target_animation := "default/idle"

	if is_moving:
		if is_sprinting:
			target_animation = "default/running_empty_handed"
		else:
			target_animation = "default/walk"

	if anim.current_animation != target_animation:
		anim.play(target_animation, 0.2)
#endregion
