extends Area2D

@export var heal_amount: int = 25

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        var player = body as CharacterBody2D
        if player.has_method("heal"):
            player.heal(heal_amount)
            queue_free() # Remove power-up after collection
