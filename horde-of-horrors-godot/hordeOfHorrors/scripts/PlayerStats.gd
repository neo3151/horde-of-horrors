extends Resource
class_name PlayerStats

@export var char_name: String = "Default"
@export var texture_path: String = ""
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var speed: float = 300.0
@export var damage: float = 10.0
@export var fire_rate: float = 0.5 # Seconds between shots
@export var bio: String = ""
@export var ability: String = ""
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
