extends Node

# Audio players for different types of sounds
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var pop_player: AudioStreamPlayer # Separate player for pop sound

# Preload audio resources
var game_loop = preload("res://audio/game_loop.mp3")
var funny_swish = preload("res://audio/funny-swish.mp3")
var ui_click = preload("res://audio/ui-click.mp3")
var pop = preload("res://audio/pop.mp3")

# Volume settings in decibels (dB)
var music_volume: float = -3.0 # Normal volume
var sfx_volume: float = 0.0 # Normal volume
var ui_volume: float = 0.0 # Normal volume for UI click
var pop_volume: float = -6.0 # Reduced volume for pop sound

func _ready():
	# Initialize audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	ui_player = AudioStreamPlayer.new()
	pop_player = AudioStreamPlayer.new()
	
	# Add them as children of the AudioManager
	add_child(music_player)
	add_child(sfx_player)
	add_child(ui_player)
	add_child(pop_player)
	
	# Set up background music
	music_player.stream = game_loop
	music_player.volume_db = music_volume
	music_player.finished.connect(_on_music_finished)
	
	# Set volumes for other players
	sfx_player.volume_db = sfx_volume
	ui_player.volume_db = ui_volume
	pop_player.volume_db = pop_volume
	
	# Start playing background music
	play_background_music()

func play_background_music():
	if not music_player.playing:
		music_player.play()

func _on_music_finished():
	# Loop the background music
	music_player.play()

func play_npc_click():
	sfx_player.stream = funny_swish
	sfx_player.play()

func play_ui_click():
	ui_player.stream = ui_click
	ui_player.play()

func play_pop():
	pop_player.stream = pop
	pop_player.play()

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
