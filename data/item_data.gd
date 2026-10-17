class_name ItemData
extends Resource

@export var name: String
@export var rarity: Rarity = Rarity.common
@export var damage: int
@export var icon: Texture2D


enum Rarity { common, rare, legendary }
