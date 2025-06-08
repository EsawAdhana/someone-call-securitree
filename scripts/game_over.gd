extends Control

# UI references
@onready var reason_label = $PanelContainer/MarginContainer/VBoxContainer/ReasonLabel
@onready var stats_label = $PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton

# Game state
var locations_reached = 1

# Location names mapping (same order as LevelManager.LOCATION_ORDER)
var location_names = [
	"FloMo",           # 1
	"Tresidder",       # 2  
	"Farrillaga",      # 3
	"Y2E2",            # 4
	"CoDa",            # 5
	"Cantor",          # 6
	"Main Quad",       # 7
	"Green Library",   # 8
	"Meyer Green",     # 9
	"Hoover Tower",    # 10
	"GSB",             # 11
	"Stadium"          # 12
]

func _ready():
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Set process mode to work when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Initially hide the screen
	visible = false

# Set the locations reached and update the stats label
func set_locations_reached(location_number):
	locations_reached = location_number
	
	# Create the stats text based on how many locations were reached
	var stats_text = ""
	if locations_reached <= 1:
		stats_text = "You didn't even make it past the first location (FloMo)!"
	elif locations_reached >= location_names.size():
		stats_text = "A tragedy! You lost on the final location"
	else:
		var location_name = location_names[locations_reached - 1] if locations_reached <= location_names.size() else "Location " + str(locations_reached)
		stats_text = "You reached " + str(locations_reached) + " locations and made it to " + location_name + "."
	
	stats_label.text = stats_text

# Show the game over screen with different messages based on reason
func show_game_over(location_number: int, morale_depleted: bool = false):
	print("GAME OVER SCREEN DEBUG: show_game_over called - Location:", location_number, "Morale depleted:", morale_depleted)
	
	set_locations_reached(location_number)
	
	# Set different messages based on the reason for game over
	if morale_depleted:
		reason_label.text = "Student morale has hit 0.\nAll hope is lost.\nAll hail the Berkeley bear."
	else:
		reason_label.text = "The workday has ended.\nTime to head home and try again tomorrow."
	
	# Don't reset morale here - keep it at 0% to show the player they lost
	# Morale will be reset when restart button is pressed
	
	visible = true
	print("GAME OVER SCREEN DEBUG: Game over screen should now be visible. Visible:", visible)

func _on_restart_button_pressed():
	# Unpause the game before restarting
	get_tree().paused = false
	
	# Reset all game managers to initial state
	# Reset morale to 100
	MoraleManager.reset_morale()
	
	# Reset morale bar state so it will be hidden until main map is entered again
	var global_ui = get_node("/root/GlobalUI")
	if global_ui:
		global_ui.reset_morale_bar_state()
	
	# Reset level progression (back to level 1, only FloMo unlocked)
	LevelManager.reset_levels()
	
	# Clear all spawned characters from all locations
	GlobalCharacterManager.clear_all()
	
	# Note: Character interaction states are reset when characters are recreated
	# This ensures exclamation marks are visible again on fresh spawns
	
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
		game_manager.berkeley_people_cleared = 0
		game_manager.berkeley_people_accepted = 0
		game_manager.total_characters_in_location = 0
		game_manager.characters_interacted_with = 0
		game_manager.planned_characters_for_round = 0
		game_manager.all_planned_characters_spawned = false
		
		# Reset all player statistics
		game_manager.reset_all_stats()
		
		# Stop any running timers
		if game_manager.time_timer:
			game_manager.time_timer.stop()
	
	# Go to the main map scene specifically (not just reload current scene)
	# This ensures we always start from the map regardless of where game over occurred
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")

func _on_quit_button_pressed():
	# Unpause the game before quitting
	get_tree().paused = false
	
	# Quit the game
	get_tree().quit() 
