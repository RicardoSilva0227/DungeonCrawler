extends CharacterBody3D

@export var speed: float = 5.0
@export var turn_speed: float = 12.0
@export var camera_yaw_degrees: float = 45.0  # must match your camera's yaw

@onready var visuals: Node3D = $Visuals


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
