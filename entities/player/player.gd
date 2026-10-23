extends CharacterBody3D

@export var speed: float = 2.0
@export var run_speed: float = 4.0
@export var turn_speed: float = 12.0
@export var camera_yaw_degrees: float = 45.0

@onready var visuals: Node3D = $Visuals
@onready var anim: AnimationPlayer = visuals.find_child(
	"AnimationPlayer", true, false
)

@onready var sword: Sword = visuals.find_child(
	"SM_Wep_Sword_04", true, false
)

const COMBO_ANIMATIONS: Array[String] = [
	"default/sword_attack_1",
	"default/sword_attack_2",
    "default/sword_attack_3"
]
var combo_index: int = 0
var attack_queued: bool = false
var is_attacking: bool = false


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	sword.hit.connect(_on_sword_hit)


#region Movements
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
	
	if is_attacking: 
		velocity.x = 0
		velocity.z = 0
	else:
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

func _get_mouse_ground_point() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var plane := Plane(Vector3.UP, global_position.y)
	return plane.intersects_ray(origin, dir)  # Vector3, or null

func _face_mouse() -> void:
	var point = _get_mouse_ground_point()
	if point == null:
		return
	var dir: Vector3 = point - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return   # cursor on top of the player, angle would be unstable
	visuals.rotation.y = atan2(-dir.x, -dir.z)

#endregion

#region Attacks

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack(get_viewport().get_mouse_position())


func _try_attack(screen_pos: Vector2) -> void:
	if is_attacking:
		if combo_index < COMBO_ANIMATIONS.size() - 1:
			attack_queued = true
		return

	combo_index = 0
	_start_attack()


func _start_attack() -> void:
	is_attacking = true
	attack_queued = false
	_face_mouse()
	sword.start_swing()
	anim.play(COMBO_ANIMATIONS[combo_index], 0.1)

func _on_sword_hit(hurtbox: Hurtbox) -> void:
	hurtbox.receive_hit(25.0)


#endregion

#region Animations

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


#endregion


	
