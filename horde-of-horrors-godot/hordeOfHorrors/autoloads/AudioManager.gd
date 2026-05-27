extends Node

@onready var music_player = $MusicPlayer
@onready var sfx_player = $SfxPlayer

func _ready() -> void:
	# Initialize audio players (AudioStreamPlayer nodes assumed as children)
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)

func play_music(music_path: String, volume_db: float = 0.0) -> void:
	if music_player and not music_player.playing:
		music_player.stream = load(music_path)
		music_player.volume_db = volume_db
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if sfx_player:
		sfx_player.stream = load(sfx_path)
		sfx_player.volume_db = volume_db
		sfx_player.play()
