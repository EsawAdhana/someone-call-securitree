extends Node

# Audio players for different types of sounds
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var pop_player: AudioStreamPlayer # Separate player for pop sound
var game_over_player: AudioStreamPlayer # Player for game over sound

# Master mute control
var is_muted: bool = false

# Preload audio resources
var game_loop = preload("res://audio/game_loop.mp3")
var funny_swish = preload("res://audio/funny-swish.mp3")
var ui_click = preload("res://audio/ui-click.mp3")
var pop = preload("res://audio/pop.mp3")
var game_over_sound = preload("res://audio/game_over.mp3")

# Volume settings in decibels (dB)
var music_volume: float = -3.0 # Normal volume
var sfx_volume: float = 0.0 # Normal volume
var ui_volume: float = 0.0 # Normal volume for UI click
var pop_volume: float = -6.0 # Reduced volume for pop sound
var game_over_volume: float = 0.0 # Normal volume for game over sound

func _ready():
	# Initialize audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	ui_player = AudioStreamPlayer.new()
	pop_player = AudioStreamPlayer.new()
	game_over_player = AudioStreamPlayer.new()
	
	# Add them as children of the AudioManager
	add_child(music_player)
	add_child(sfx_player)
	add_child(ui_player)
	add_child(pop_player)
	add_child(game_over_player)
	
	# Set up background music
	music_player.stream = game_loop
	music_player.volume_db = music_volume
	music_player.finished.connect(_on_music_finished)
	
	# Set volumes for other players
	sfx_player.volume_db = sfx_volume
	ui_player.volume_db = ui_volume
	pop_player.volume_db = pop_volume
	game_over_player.volume_db = game_over_volume
	
	# MUTED: Background music disabled for now
	# play_background_music()
	print("AudioManager: Background music is muted")
	
	# Set initial mute state - MUTING ALL AUDIO FOR NOW
	mute_all_audio()

# Master mute/unmute functions
func mute_all_audio():
	is_muted = true
	stop_all_audio()
	print("AudioManager: All audio muted")

func unmute_all_audio():
	is_muted = false
	print("AudioManager: All audio unmuted")

func toggle_mute():
	if is_muted:
		unmute_all_audio()
	else:
		mute_all_audio()

func play_background_music():
	if not is_muted and not music_player.playing:
		music_player.play()

func stop_background_music():
	if music_player.playing:
		music_player.stop()

func stop_all_audio():
	music_player.stop()
	sfx_player.stop()
	ui_player.stop()
	pop_player.stop()
	game_over_player.stop()

func _on_music_finished():
	# Loop the background music only if not muted
	if not is_muted:
		music_player.play()

func play_npc_click():
	if not is_muted:
		sfx_player.stream = funny_swish
		sfx_player.play()

func play_ui_click():
	if not is_muted:
		ui_player.stream = ui_click
		ui_player.play()

func play_pop():
	if not is_muted:
		pop_player.stream = pop
		pop_player.play()

func play_game_over():
	if not is_muted:
		game_over_player.stream = game_over_sound
		game_over_player.play()
		print("AudioManager: Playing game over sound")

# Volume control functions
func set_music_volume(db: float):
	music_volume = db
	music_player.volume_db = db

func set_sfx_volume(db: float):
	sfx_volume = db
	sfx_player.volume_db = db

func set_ui_volume(db: float):
	ui_volume = db
	ui_player.volume_db = db

func set_pop_volume(db: float):
	pop_volume = db
	pop_player.volume_db = db

func set_game_over_volume(db: float):
	game_over_volume = db
	game_over_player.volume_db = db

func stop_background_audio():
	# Stop all audio except game over sound
	music_player.stop()
	sfx_player.stop()
	ui_player.stop()
	pop_player.stop() 
