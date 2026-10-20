class_name HealthBar
extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@export var follow_target: Node3D
@export var health: HealthComponent

func _ready() -> void:
	progress_bar.max_value = health.max_health
	progress_bar.value = health.current_health
	health.health_changed.connect(_update_health_bar)
	
func _update_health_bar(current_health: float, max_health: float) -> void:
	progress_bar.value = current_health
	progress_bar.max_value = max_health
	
func _process(_delta: float) -> void:
	if follow_target == null: return
	
	var camera = get_viewport().get_camera_3d()
	var screen_pos = camera.unproject_position(follow_target.global_position)
	progress_bar.position = screen_pos - Vector2(progress_bar.size.x / 2.0, progress_bar.size.y)
	
	
func setup(health: HealthComponent, follow_target: Node3D = null) -> void:
	pass
	# store the references, set the starting values, connect the signal
