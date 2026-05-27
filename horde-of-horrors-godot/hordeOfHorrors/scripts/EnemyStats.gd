extends Resource
class_name EnemyStats

@export var enemy_name: String = "Default Enemy"
@export var texture_path: String = ""
@export var health: float = 50.0
@export var speed: float = 100.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var score_value: int = 10
@export var enemy_type: String = "normal"
@export var bio: String = ""
@export var abilities: Array[String] = []
