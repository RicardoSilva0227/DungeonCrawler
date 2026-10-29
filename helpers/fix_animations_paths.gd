@tool
extends EditorScript

func _run() -> void:
	var path := "res://assets/Animations/Exported_Animations/death_01.res"
	var animation := load(path) as Animation

	if animation == null:
		push_error("Could not load animation.")
		return

	for i in range(animation.get_track_count()):
		var old_path := str(animation.track_get_path(i))

		if old_path.begins_with("Null/Skeleton3D"):
			var new_path := old_path.trim_prefix("Null/")
			animation.track_set_path(i, NodePath(new_path))
			print(old_path, " -> ", new_path)

	var error := ResourceSaver.save(animation, path)

	if error == OK:
		print("Animation paths updated successfully.")
	else:
		push_error("Failed to save animation: " + str(error))
