extends CharacterBody3D

@export var speed: float = 2.0
@export var run_speed: float = 4.0
@export var turn_speed: float = 12.0
@export var camera_yaw_degrees: float = 45.0

@onready var visuals: Node3D = $Visuals
@onready var anim: AnimationPlayer = visuals.find_child(
	"AnimationPlayer", true, false
)

const ENEMY_HURTBOX_LAYER := 4
const ATTACK_ANIMATION := "default/sword_outward_swing"

var is_attacking: bool = false


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	# 1. Read movement input
	var input := Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)

	var direction := Vector3(input.x, 0.0, input.y).rotated(
		Vector3.UP,
		deg_to_rad(camera_yaw_degrees)
	)

	# 2. Determine movement state
	var is_moving := direction.length() > 0.1
	var is_sprinting := is_moving and Input.is_action_pressed("sprint")

	var current_speed := run_speed if is_sprinting else speed

	# 3. Apply movement
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity += get_gravity() * delta

	# 4. Rotate visuals toward movement
	if is_moving:
		var target_angle := atan2(-direction.x, -direction.z)

		visuals.rotation.y = lerp_angle(
			visuals.rotation.y,
			target_angle,
			turn_speed * delta
		)

	move_and_slide()

	# 5. Handle animations
	_animations(is_moving, is_sprinting)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack(get_viewport().get_mouse_position())


func _try_attack(screen_pos: Vector2) -> void:
	# Prevent attacking while already attacking
	if is_attacking:
		return

	is_attacking = true

	# Start attack animation
	anim.play(ATTACK_ANIMATION, 0.2)

	# Raycast toward mouse position
	var camera := get_viewport().get_camera_3d()
	var origin := camera.project_ray_origin(screen_pos)
	var end := origin + camera.project_ray_normal(screen_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, end)

	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1 << (ENEMY_HURTBOX_LAYER - 1)

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return

	var hit_object = result["collider"]

	if hit_object is Hurtbox:
		hit_object.receive_hit(25.0)


func _animations(is_moving: bool, is_sprinting: bool) -> void:
	# Never interrupt an attack
	if is_attacking:
		return

	var target_animation := "default/idle"

	if is_moving:
		if is_sprinting:
			target_animation = "default/running_empty_handed"
		else:
			target_animation = "default/walk"

	if anim.current_animation != target_animation:
		anim.play(target_animation, 0.2)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == ATTACK_ANIMATION:
		is_attacking = false
