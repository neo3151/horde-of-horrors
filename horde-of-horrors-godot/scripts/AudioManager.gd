extends Node

var num_players = 12
var bus_sfx = "SFX"
var bus_music = "Music"

var available_players = []
var music_player: AudioStreamPlayer

# Preloaded Sounds
var sounds = {
	"shoot": preload("res://assets/sounds/shoot.wav"),
	"hit": preload("res://assets/sounds/hit.wav"),
	"die": preload("res://assets/sounds/die.wav"),
	"player_hurt": preload("res://assets/sounds/player_hurt.wav"),
}

var music_tracks = {
	"battle_theme": preload("res://assets/sounds/battle_theme.ogg")
}

func _ready():
	# Create pool for SFX
	for i in range(num_players):
		var p = AudioStreamPlayer.new()
		p.bus = bus_sfx
		add_child(p)
		available_players.append(p)
		p.finished.connect(_on_stream_finished.bind(p))
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = bus_music
	music_player.volume_db = -80.0 # DEV: muted for now
	add_child(music_player)

func _on_stream_finished(stream):
	available_players.append(stream)

func play_sfx(sound_name: String, pitch_variance: float = 0.1):
	if not sounds.has(sound_name):
		push_warning("Sound not found: " + sound_name)
		return
		
	if available_players.is_empty():
		push_warning("Audio pool exhausted! Consider increasing num_players.")
		return
		
	var p = available_players.pop_front()
	p.stream = sounds[sound_name]
	p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	p.play()

func play_music(track_name: String):
	if not music_tracks.has(track_name):
		push_warning("Music not found: " + track_name)
		return
		
	if music_player.stream == music_tracks[track_name] and music_player.playing:
		return # Already playing this track
		
	music_player.stream = music_tracks[track_name]
	music_player.play()

func stop_music():
	music_player.stop()
