extends Resource
class_name PowerUpData

@export var power_up_name: String = "Default Power-up"
@export var texture_path: String = ""
@export var duration: float = 0.0 # Duration in seconds, 0 for instant effect
@export var effect_amount: float = 0.0
@export var rarity: String = "Common" # Common, Uncommon, Rare, Epic
@export var bio: String = ""
