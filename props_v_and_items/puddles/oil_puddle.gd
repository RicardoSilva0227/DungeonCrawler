class_name OilPuddle
extends Area3D

#region Lifecycle
func _ready() -> void:
	body_entered.connect(_on_body_entered)
#endregion

#region Detection
func _on_body_entered(body: Node3D) -> void:
	var elemental := body.get_node_or_null("ElementalComponent") as ElementalComponent
	
	print('oiled')
	if elemental == null:
		return

	elemental.apply_element(ElementTypes.Element.OIL)
#endregion
