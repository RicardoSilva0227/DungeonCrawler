class_name ElementalReactionResolver
extends RefCounted

#region Reaction Resolution
static func resolve(
	elemental: Node,
	element: ElementTypes.Element
) -> void:
	match element:
		ElementTypes.Element.FIRE:
			_resolve_fire(elemental)

		ElementTypes.Element.OIL:
			elemental.add_condition(
				ElementTypes.Condition.OILED,
				10.0
			)


static func _resolve_fire(elemental: Node) -> void:
	if elemental.has_condition(ElementTypes.Condition.OILED):
		elemental.remove_condition(ElementTypes.Condition.OILED)

		elemental.add_condition(
			ElementTypes.Condition.BURNING,
			5.0
		)
		
		
#endregion
