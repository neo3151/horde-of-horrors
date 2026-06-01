# PowerUpData.gd
extends Resource
class_name PowerUpData

enum PowerUpType { 
	HEAL, 
	SPEED_BOOST, 
	DAMAGE_BOOST, 
	SHIELD, 
	VAMPIRE_KISS,
	HOLY_NOVA, 
	TIME_SLOW, 
	DOUBLE_SHOT, 
	BLOOD_MOON_RAGE, 
	GHOST_FORM 
}

@export var name: String = "Power Up"
@export var type: PowerUpType = PowerUpType.HEAL
@export var value: float = 10.0
@export var duration: float = 0.0 # 0 means instant / one-time
@export var icon: Texture2D
