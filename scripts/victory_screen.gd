extends Control

# UI references
@onready var victory_image = $PanelContainer/MarginContainer/VBoxContainer/VictoryImage
@onready var message_label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel
@onready var stats_label = $PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var play_again_button = $PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton
@onready var quit_button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton

# Preload victory images
var berkeley_dominates = preload("res://assets/endscreens/caldominates.png")
var berkeley_wins = preload("res://assets/endscreens/calwins.png")
var stanford_wins = preload("res://assets/endscreens/stanfordwins.png")

func _ready():
	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Set process mode to work when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Initially hide the screen
	visible = false

func show_victory(final_morale: float):
	print("VICTORY: Showing victory screen with final morale:", final_morale)
	
	# Determine which image and message to show based on morale
	var victory_texture: Texture2D
	var victory_message: String
	
	if final_morale <= 30:  # 30% or less morale (Berkeley dominates)
		victory_texture = berkeley_dominates
		victory_message = "Victory... at what cost?\nBerkeley dominates in the end."
		stats_label.text = "You won with only " + str(int(final_morale)) + "% morale remaining!\nStanford's security barely held together."
	elif final_morale < 60:  # Between 31-59% morale (Berkeley wins)
		victory_texture = berkeley_wins
		victory_message = "A close battle... but Berkeley wins."
		stats_label.text = "Try better next time."
	else:  # 60% or more morale (Stanford wins)
		victory_texture = stanford_wins
		victory_message = "Outstanding work!\nStanford stands strong and secure!"
		stats_label.text = "You won with " + str(int(final_morale)) + "% morale remaining.\nStanford's security is unbreachable!"
	
	# Apply the image and message
	victory_image.texture = victory_texture
	message_label.text = victory_message
	
	# Show the screen
	visible = true
	
	# Stop background music and play appropriate victory sound
	AudioManager.stop_background_audio()
	AudioManager.play_victory_sound(final_morale)

func _on_play_again_button_pressed():
	print("VICTORY: Play again button pressed")
	
	# Unpause the game before restarting
	get_tree().paused = false
	
	# Reset all game managers to initial state
	# Reset morale to 100
	MoraleManager.reset_morale()
	
	# Reset level progression (back to level 1, only FloMo unlocked)
	LevelManager.reset_levels()
	
	# Clear all spawned characters from all locations
	GlobalCharacterManager.clear_all()
	
	# Reset game manager time state to initial values
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Reset time to starting values
		game_manager.current_day = 1
		game_manager.current_hour = 9  # 9:00 AM
		game_manager.current_minute = 0
		game_manager.am_pm = "AM"
		game_manager.is_in_location = false
		
		# Reset character tracking
		game_manager.berkeley_people_in_location = 0
		game_manager.berkeley_people_rejected = 0
		game_manager.berkeley_people_processed = 0
		game_manager.total_characters_in_location = 0
		game_manager.characters_interacted_with = 0
		game_manager.planned_characters_for_round = 0
		game_manager.all_planned_characters_spawned = false
		
		# Stop any running timers
		if game_manager.time_timer:
			game_manager.time_timer.stop()
	
	# Go to the main map scene
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")

func _on_quit_button_pressed():
	print("VICTORY: Quit button pressed")
	
	# Unpause the game before quitting
	get_tree().paused = false
	
	# Quit the game
	get_tree().quit() 