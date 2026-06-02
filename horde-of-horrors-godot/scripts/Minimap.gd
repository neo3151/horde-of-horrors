extends SubViewportContainer

@onready var minimap_camera: Camera2D = $SubViewport/MinimapCamera

var player: Node

func _ready() -> void:
    # Defer until the viewport is ready, then share the main 2D world
    await get_tree().process_frame
    $SubViewport.world_2d = get_viewport().world_2d
    player = GameManager.player

func _process(delta: float) -> void:
    if is_instance_valid(player) and minimap_camera:
        if player is Node2D:
            minimap_camera.global_position = player.global_position
        elif player is Node3D:
            minimap_camera.global_position = Vector2(player.global_position.x, player.global_position.z)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M or event.keycode == KEY_TAB:
            set_minimap_visible(not visible)

func set_minimap_visible(is_visible: bool) -> void:
    visible = is_visible
