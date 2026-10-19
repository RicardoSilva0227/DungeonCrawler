extends CharacterBody3D

@export var speed: float = 5.0
@export var turn_speed: float = 12.0
@export var camera_yaw_degrees: float = 45.0  # must match your camera's yaw

@onready var visuals: Node3D = $Visuals
@onready var anim: AnimationPlayer = $Visuals.find_child("AnimationPlayer", true, false)


func _physics_process(delta: float) -> void:
	# 1. Read input and rotate it into the camera's frame
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y).rotated(
		Vector3.UP, deg_to_rad(camera_yaw_degrees))
	
	# 2. Horizontal velocity only; vertical comes from gravity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. Turn the visuals (not the body) toward the movement direction
	if direction.length() > 0.1:
		var target_angle := atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, turn_speed * delta)

	move_and_slide()
	
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1
	var target := "default/walk" if moving else "default/idle"
	if anim.current_animation != target:
		anim.play(target, 0.2)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack(get_viewport().get_mouse_position())


func _try_attack(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	var origin := camera.project_ray_origin(screen_pos)
	var end := origin + camera.project_ray_normal(screen_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true    # hurtboxes are Area3D
	query.collide_with_bodies = false  # we don't want walls or bodies here
	query.collision_mask = 1 << 3      # layer 4 only (layer N = bit N-1)

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	
	if (result.is_empty()):
		return
	
	
