class_name LootTier
extends Resource

@export var tier_name: StringName
@export_range(0.0, 1.0) var chance: float = 0.0
@export var items: Array[ItemData] = []
