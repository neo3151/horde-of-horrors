extends Node

var num_players = 12
var bus_sfx = "SFX"
var bus_music = "Music"

var available_players = []
var music_player: AudioStreamPlayer

# Preloaded Sounds
var sounds = {
	"shoot": preload("res://assets/sounds/shoot.ogg"),
	"hit": preload("res://assets/sounds/hit.ogg"),
	"die": preload("res://assets/sounds/die.ogg"),
	"player_hurt": preload("res://assets/sounds/player_hurt.ogg"),
}

var music_tracks = {
	"battle_theme": preload("res://assets/sounds/battle_theme.ogg")
}

func _ready():
	# Restore standard bus configuration
	bus_sfx = "SFX"
	bus_music = "Music"
	
	# Create pool for SFX
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(num_players):
		var p = AudioStreamPlayer.new()
		p.bus = bus_sfx
		add_child(p)
		available_players.append(p)
		p.finished.connect(_on_stream_finished.bind(p))
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = bus_music
	music_player.volume_db = -12.0 # Standard comfortable volume

func _on_stream_finished(stream):
	available_players.append(stream)

func play_sfx(sound_name: String, pitch_variance: float = 0.1):
	if not sounds.has(sound_name):
		push_warning("Sound not found: " + sound_name)
		return
		
	# Ensure we are in the tree
	if not is_inside_tree(): return

	if available_players.is_empty():
		push_warning("Audio pool exhausted! Consider increasing num_players.")
		return
		
	var p = available_players.pop_front()
	p.stream = sounds[sound_name]
	p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	p.play()

var active_music_tween: Tween

func play_music(track_name: String, fade_duration: float = 1.0, force_restart: bool = false):
	# Wait a frame to ensure audio hardware is initialized
	if not is_inside_tree(): return
	await get_tree().process_frame
	
	if not music_tracks.has(track_name):
		printerr("AudioManager: Music not found: " + track_name)
		return
		
	var new_stream = music_tracks[track_name]
	if is_instance_valid(new_stream):
		if new_stream is AudioStreamWAV:
			new_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif new_stream is AudioStreamOggVorbis:
			new_stream.loop = true
		
	if not force_restart and music_player.stream == new_stream and music_player.playing:
		return # Already playing this track
		
	printerr("AudioManager: Starting music track: ", track_name)
	
	if active_music_tween:
		active_music_tween.kill()
		
	if music_player.playing:
		# Crossfade: fade out current, then switch and fade in
		active_music_tween = create_tween()
		active_music_tween.tween_property(music_player, "volume_db", -80.0, fade_duration / 2.0)
		active_music_tween.tween_callback(func():
			music_player.stream = new_stream
			music_player.play()
		)
		active_music_tween.tween_property(music_player, "volume_db", -12.0, fade_duration / 2.0)
	else:
		music_player.stream = new_stream
		music_player.volume_db = -12.0
		music_player.play()
		print("AudioManager: Music player started at -12dB")

func stop_music():
	music_player.stop()
