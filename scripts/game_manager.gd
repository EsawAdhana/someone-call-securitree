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
var is_in_location = false # Track if player is in a location

# Level integration
var berkeley_people_in_location: int = 0
var berkeley_people_cleared: int = 0

signal time_updated(time_data)
signal workday_ended

func _ready():
	# Set up the time timer (15 real seconds = 15 game minutes, so 1 real second = 1 game minute)
	time_timer.wait_time = 1.0
	time_timer.timeout.connect(_on_time_timer_timeout)
	time_timer.name = "time_timer"
	add_child(time_timer)
	
	# Don't start timer immediately - only runs in locations
	print("Game Manager: Timer created (only runs in locations)")
	
	# Find the UI nodes
	call_deferred("setup_ui_references")
	
	# Connect to morale manager signals
	MoraleManager.morale_depleted.connect(_on_morale_depleted)
	
	# Connect to level manager signals
	LevelManager.time_limit_reached.connect(_on_level_time_limit_reached)
	LevelManager.level_started.connect(_on_level_started)
	LevelManager.level_completed.connect(_on_level_completed)
	
	# Emit initial time to ensure UI displays 9:00 AM at start
	call_deferred("emit_initial_time")

func setup_ui_references():
	# This is called deferred to ensure all nodes are ready
	print("Game Manager: Setting up UI references...")
	
	# Try to find inspection panel in all locations
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	
	# Look for inspection panel in UI layer
	var ui_layer = current_scene.get_node_or_null("UI")
	if ui_layer:
		inspection_panel = ui_layer.get_node_or_null("InspectionPanel")
		if inspection_panel:
			print("Game Manager: Found inspection panel in UI layer")
		
		# Look for game over screen
		game_over_screen = ui_layer.get_node_or_null("GameOver")
		if game_over_screen:
			print("Game Manager: Found game over screen in UI layer")

func _on_level_started(level_number: int):
	print("Game Manager: Level", level_number, "started")
	
	# Reset berkeley people counters
	berkeley_people_in_location = 0
	berkeley_people_cleared = 0
	
	# Set the time based on level progression
	# Level 1: Start at 9:00, ends at 9:15
	# Level 2: Start at 9:15, ends at 9:30, etc.
	set_time_for_level(level_number)
	
	# Mark that we're in a location and start the timer
	is_in_location = true
	time_timer.start()
	print("Game Manager: Timer started for location visit")
	
	# Emit initial time
	time_updated.emit({
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"am_pm": am_pm
	})

func _on_level_completed(level_number: int):
	print("Game Manager: Level", level_number, "completed")
	
	# Stop the timer and mark that we're no longer in a location
	time_timer.stop()
	is_in_location = false
	
	print("Game Manager: Timer paused on main map at", get_time_string())

func set_time_for_level(level_number: int):
	# Calculate starting time for this level
	# Level 1: 9:00 AM
	# Level 2: 9:15 AM  
	# Level 3: 9:30 AM, etc.
	var total_minutes = (level_number - 1) * 15
	current_hour = WORKDAY_START_HOUR
	current_minute = total_minutes % 60
	
	# Handle hour overflow
	if total_minutes >= 60:
		current_hour += total_minutes / 60
	
	# Handle AM/PM conversion
	if current_hour >= 12:
		if current_hour == 12:
			am_pm = "PM"
		else:
			current_hour = current_hour % 12
			if current_hour == 0:
				current_hour = 12
			am_pm = "PM"
	else:
		am_pm = "AM"

func _on_level_time_limit_reached(level_number: int):
	print("Game Manager: Time limit reached for level", level_number)
	
	# Check if there are uncleared Berkeley people
	var uncleared_berkeley = berkeley_people_in_location - berkeley_people_cleared
	if uncleared_berkeley > 0:
		print("Game Manager:", uncleared_berkeley, "Berkeley people not cleared, decreasing morale")
		for i in range(uncleared_berkeley):
			MoraleManager.decrease_morale()

func _on_character_approved(character):
	# Handle character approval logic
	print("Game Manager: Character approved:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	
	# If it's a Stanford student being approved, that's correct
	if character.character_type == 0:
		print("Game Manager: Correctly approved Stanford student")
	else:
		# Berkeley student being approved - incorrect but no morale penalty
		print("Game Manager: Incorrectly approved Berkeley student - no morale penalty")
	
	# Don't advance time automatically - time is managed by level system
	# advance_time(1)

func _on_character_rejected(character):
	# Handle character rejection logic
	print("Game Manager: Character rejected:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	
	# If it's a Berkeley student being rejected, that's correct
	if character.character_type == 1:
		print("Game Manager: Correctly rejected Berkeley student")
		berkeley_people_cleared += 1
	else:
		# If it's a Stanford student being rejected, that's wrong - decrease morale
		print("Game Manager: Incorrectly rejected Stanford student - decreasing morale")
		MoraleManager.decrease_morale()
	
	# Don't advance time automatically - time is managed by level system
	# advance_time(1)

func _on_exit_pressed():
	# Handle exit button press
	print("Game Manager: Exit button pressed")

func _on_remove_npc_pressed(character):
	# Handle remove NPC button press
	print("Game Manager: Remove NPC button pressed for", character.variant_name)
	
	# Don't advance time automatically - time is managed by level system
	# advance_time(1)

func _on_time_timer_timeout():
	# Only advance time if we're in a location
	if is_in_location:
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

# Functions to track Berkeley people in location
func register_berkeley_person():
	berkeley_people_in_location += 1
	print("Game Manager: Berkeley person registered. Total:", berkeley_people_in_location)

func get_berkeley_stats():
	return {
		"total": berkeley_people_in_location,
		"cleared": berkeley_people_cleared,
		"remaining": berkeley_people_in_location - berkeley_people_cleared
	}

func get_time_string() -> String:
	var minutes_str = str(current_minute).pad_zeros(2)
	return "%d:%s %s" % [current_hour, minutes_str, am_pm]

func emit_initial_time():
	# Emit the initial game time (9:00 AM) for the UI
	time_updated.emit({
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"am_pm": am_pm
	})
