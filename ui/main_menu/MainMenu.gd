extends Control

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_load_test_area_button_pressed() -> void:
	get_tree().change_scene_to_file("res://world/rooms/TestArea.tscn")
