extends CanvasLayer

@onready var joystick = $Joystick

func _ready() -> void:
	# Show joystick only if on mobile or if configured
	# For this project, we'll keep it visible if the user wants mobile controls
	joystick.visible = true
