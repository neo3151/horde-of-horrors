# PowerUpDrop.gd
extends Area2D

@export var data: PowerUpData

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if data:
		setup(data)

const ICONS = {
	PowerUpData.PowerUpType.HEAL: preload("res://assets/sprites/ui/powerup_icons/health_pack.svg"),
	PowerUpData.PowerUpType.SPEED_BOOST: preload("res://assets/sprites/ui/powerup_icons/blood_rush.svg"),
	PowerUpData.PowerUpType.DAMAGE_BOOST: preload("res://assets/sprites/ui/powerup_icons/fury.svg"),
	PowerUpData.PowerUpType.SHIELD: preload("res://assets/sprites/ui/powerup_icons/iron_skin.svg"),
	PowerUpData.PowerUpType.VAMPIRE_KISS: preload("res://assets/sprites/ui/powerup_icons/vampires_kiss.svg"),
	PowerUpData.PowerUpType.HOLY_NOVA: preload("res://assets/sprites/ui/powerup_icons/holy_nova.svg"),
	PowerUpData.PowerUpType.TIME_SLOW: preload("res://assets/sprites/ui/powerup_icons/time_slow.svg"),
	PowerUpData.PowerUpType.DOUBLE_SHOT: preload("res://assets/sprites/ui/powerup_icons/double_shot.svg"),
	PowerUpData.PowerUpType.BLOOD_MOON_RAGE: preload("res://assets/sprites/ui/powerup_icons/blood_moon_rage.svg"),
	PowerUpData.PowerUpType.GHOST_FORM: preload("res://assets/sprites/ui/powerup_icons/ghost_form.svg"),
}

func setup(p_data: PowerUpData) -> void:
	data = p_data
	if sprite:
		if data.icon:
			sprite.texture = data.icon
			sprite.scale = Vector2(0.2, 0.2) # Adjust scale for icons
		elif ICONS.has(data.type):
			sprite.texture = ICONS[data.type]
			sprite.scale = Vector2(0.3, 0.3)
		else:
			# Fallback tinting
			match data.type:
				PowerUpData.PowerUpType.HEAL:
					sprite.modulate = Color(0.15, 0.85, 0.15)
				PowerUpData.PowerUpType.SPEED_BOOST:
					sprite.modulate = Color(0.9, 0.9, 0.1)
				PowerUpData.PowerUpType.DAMAGE_BOOST:
					sprite.modulate = Color(0.95, 0.1, 0.1)
				PowerUpData.PowerUpType.SHIELD:
					sprite.modulate = Color(0.1, 0.6, 0.95)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("apply_powerup"):
			body.apply_powerup(data)
			# Spawn collection indicator or play sound if needed
			queue_free()
