extends Node

# Time constants
const WORKDAY_START_HOUR = 9 # 9:00 AM
const WORKDAY_END_HOUR = 17 # 5:00 PM in 24-hour format

# UI node references
@onready var inspection_panel = null
@onready var game_over_screen = null
@onready var time_timer = Timer.new()

# Game state
var current_day = 1
var current_hour = WORKDAY_START_HOUR
var current_minute = 0
var am_pm = "AM"

signal time_updated(time_data)
signal workday_ended

func _ready():
	# Set up the time timer (1 real second = 1 game minute)
	time_timer.wait_time = 1.0
	time_timer.timeout.connect(_on_time_timer_timeout)
	add_child(time_timer)
	time_timer.start()
	
	# Find the UI nodes
	call_deferred("setup_ui_references")
	
	# Connect to morale manager signals
	MoraleManager.morale_depleted.connect(_on_morale_depleted)

func setup_ui_references():
	# This is called deferred to ensure all nodes are ready
	print("Game Manager: Setting up UI references...")
	
	# Try to find inspection panel in all locations
	var root = get_tree().get_root()
	for child in root.get_children():
		# Check all UI layers in the scene
		var ui_layer = child.get_node_or_null("UI")
		if ui_layer:
			# Try to find the inspection panel
			inspection_panel = ui_layer.get_node_or_null("InspectionPanel")
			if inspection_panel:
				print("Game Manager: Found InspectionPanel at path:", inspection_panel.get_path())
				break
	
	# Try to find game over screen in all locations
	for child in root.get_children():
		# Check all UI layers in the scene
		var ui_layer = child.get_node_or_null("UI")
		if ui_layer:
			# Try to find the game over screen
			game_over_screen = ui_layer.get_node_or_null("GameOver")
			if game_over_screen:
				print("Game Manager: Found GameOver at path:", game_over_screen.get_path())
				break
	
	# Connect signals
	if inspection_panel:
		inspection_panel.character_approved.connect(_on_character_approved)
		inspection_panel.character_rejected.connect(_on_character_rejected)
		inspection_panel.exit_pressed.connect(_on_exit_pressed)
		inspection_panel.remove_npc_pressed.connect(_on_remove_npc_pressed)
		print("Game Manager: Connected all inspection panel signals")
	else:
		push_error("Game Manager: Could not find InspectionPanel node")

# Helper function to print the scene tree for debugging
func print_scene_tree(node = null, indent = 0):
	if node == null:
		node = get_tree().get_root()
	
	var indent_str = ""
	for i in range(indent):
		indent_str += "  "
	
	print(indent_str + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		print_scene_tree(child, indent + 1)

func _on_character_approved(character):
	# Handle character approval logic
	print("Game Manager: Character approved:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	
	# Advance time
	advance_time(1)

func _on_character_rejected(character):
	# Handle character rejection logic
	print("Game Manager: Character rejected:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	
	# Advance time
	advance_time(1)

func _on_exit_pressed():
	# Handle exit button press
	print("Game Manager: Exit button pressed")

func _on_remove_npc_pressed(character):
	# Handle remove NPC button press
	print("Game Manager: Remove NPC button pressed for", character.variant_name)
	
	# Advance time
	advance_time(1)

func _on_time_timer_timeout():
	advance_time(1) # Advance one minute every real second

func advance_time(minutes):
	current_minute += minutes
	
	# Handle minute rollover
	if current_minute >= 60:
		current_hour += current_minute / 60
		current_minute = current_minute % 60
	
	# Handle hour rollover and AM/PM
	if current_hour >= 12:
		if current_hour == 12:
			am_pm = "PM"
		else:
			current_hour = current_hour % 12
			if current_hour == 0:
				current_hour = 12
			am_pm = "PM"
	
	# Check for workday end (5:00 PM)
	var time_in_24hr = current_hour
	if am_pm == "PM" and current_hour != 12:
		time_in_24hr += 12
	
	if time_in_24hr >= WORKDAY_END_HOUR:
		_on_workday_ended()
		time_timer.stop() # Stop the timer when workday ends
	
	# Emit signal with updated time
	time_updated.emit({
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"am_pm": am_pm
	})

func _on_workday_ended():
	if game_over_screen:
		game_over_screen.show_game_over(current_day, false)
	workday_ended.emit()

func _on_morale_depleted():
	# Show the game over screen with morale depleted reason
	if game_over_screen:
		game_over_screen.show_game_over(current_day, true)
	time_timer.stop() # Stop the timer when game ends

func get_current_time():
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"am_pm": am_pm
	}

func get_current_day():
	return current_day
