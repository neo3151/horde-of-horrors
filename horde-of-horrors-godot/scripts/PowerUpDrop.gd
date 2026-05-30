# PowerUpDrop.gd
extends Area2D

@export var data: PowerUpData

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if data:
		setup(data)

func setup(p_data: PowerUpData) -> void:
	data = p_data
	if sprite:
		if data.icon:
			sprite.texture = data.icon
		else:
			# Tint default visual based on type
			match data.type:
				PowerUpData.PowerUpType.HEAL:
					sprite.modulate = Color(0.15, 0.85, 0.15) # Green
				PowerUpData.PowerUpType.SPEED_BOOST:
					sprite.modulate = Color(0.9, 0.9, 0.1) # Yellow
				PowerUpData.PowerUpType.DAMAGE_BOOST:
					sprite.modulate = Color(0.95, 0.1, 0.1) # Red
				PowerUpData.PowerUpType.SHIELD:
					sprite.modulate = Color(0.1, 0.6, 0.95) # Blue

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("apply_powerup"):
			body.apply_powerup(data)
			# Spawn collection indicator or play sound if needed
			queue_free()
