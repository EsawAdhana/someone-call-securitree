extends Node

# Time constants
const WORKDAY_START_HOUR = 9 # 9:00 AM
const WORKDAY_END_HOUR = 21 # 9:00 PM (12 hours from start)

# Time scaling: 1 minute every 0.5 real seconds = 2 game minutes per real second
# So 30 real seconds = 60 game minutes (1 hour)
const TIME_SCALE_MINUTES_PER_TICK = 1

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
var berkeley_people_accepted: int = 0  # Track Berkeley students that were incorrectly accepted

# Auto-skip tracking
var total_characters_in_location: int = 0
var characters_interacted_with: int = 0
var planned_characters_for_round: int = 0  # Total characters planned to spawn this round
var all_planned_characters_spawned: bool = false  # Whether all planned characters have spawned

signal time_updated(time_data)
signal workday_ended

func _ready():
	# Set up the time timer (0.5 real seconds = 1 game minute)
	time_timer.wait_time = 0.5
	time_timer.timeout.connect(_on_time_timer_timeout)
	time_timer.name = "time_timer"
	add_child(time_timer)
	
	# Don't start timer immediately - only runs in locations
	print("Game Manager: Timer created (1 game minute every 0.5 real seconds)")
	
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
	berkeley_people_accepted = 0
	
	# Reset character interaction tracking
	total_characters_in_location = 0
	characters_interacted_with = 0
	planned_characters_for_round = 0
	all_planned_characters_spawned = false
	
	# Set the time based on level progression
	# Level 1: 9:00-10:00 AM, Level 2: 10:00-11:00 AM, Level 3: 11:00-12:00 PM, etc.
	# Each level represents 60 game minutes (1 hour)
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
	# Level 1 always starts at 9:00 AM (beginning of game)
	if level_number == 1:
		current_hour = WORKDAY_START_HOUR
		current_minute = 0
		am_pm = "AM"
		print("Game Manager: Starting first location at 9:00 AM")
		return
	
	# For subsequent levels, calculate target time and handle early exits
	# Level 1: 9:00-10:00 AM, Level 2: 10:00-11:00 AM, Level 3: 11:00-12:00 PM, etc.
	# Each level represents 60 game minutes (1 hour)
	var target_hour = WORKDAY_START_HOUR + (level_number - 1)
	var target_minute = 0
	
	# If we're ahead of the target time (early exit), jump to the target time
	# If we're at or past the target time (natural progression), keep current time
	var current_time_in_minutes = (current_hour - WORKDAY_START_HOUR) * 60 + current_minute
	var target_time_in_minutes = (level_number - 1) * 60  # Each level is 1 hour = 60 minutes
	
	if current_time_in_minutes < target_time_in_minutes:
		# Early exit - jump to next hour mark
		current_hour = target_hour
		current_minute = target_minute
		print("Game Manager: Jumped time to next hour mark:", get_time_string())
	else:
		# Natural progression or already past target - keep current time
		print("Game Manager: Keeping current time (natural progression):", get_time_string())
	
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
	
	# Check if game is already over (paused) before proceeding
	if get_tree().paused:
		print("Game Manager: Game is already paused (game over), skipping Berkeley morale decrease")
		return
	
	# Apply morale penalties for Berkeley students that were accepted instead of rejected
	if berkeley_people_accepted > 0:
		print("Game Manager: Applying morale penalties for", berkeley_people_accepted, "Berkeley students that were accepted")
		for i in range(berkeley_people_accepted):
			MoraleManager.decrease_morale()
			print("Game Manager: Decreased morale for accepted Berkeley student", i + 1, "/", berkeley_people_accepted)
	
	# Apply morale penalties for unprocessed Berkeley students (those that were never interacted with)
	var unprocessed_berkeley = berkeley_people_in_location - berkeley_people_cleared
	if unprocessed_berkeley > 0:
		print("Game Manager: Applying morale penalties for", unprocessed_berkeley, "unprocessed Berkeley students")
		for i in range(unprocessed_berkeley):
			MoraleManager.decrease_morale()
			print("Game Manager: Decreased morale for unprocessed Berkeley student", i + 1, "/", unprocessed_berkeley)

func _on_character_approved(character):
	# Handle character approval logic
	print("Game Manager: Character approved:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	
	# If it's a Stanford student being approved, that's correct
	if character.character_type == 0:
		print("Game Manager: Correctly approved Stanford student")
	else:
		# Berkeley student being approved - incorrect but no morale penalty here
		# Morale penalty will be applied when round ends for unrejected Berkeley students
		print("Game Manager: Incorrectly approved Berkeley student - morale penalty will be applied at round end")
		
		# Track that this Berkeley student was accepted
		berkeley_people_accepted += 1
		print("Game Manager: Berkeley accepted count incremented to:", berkeley_people_accepted)
		
		# Mark them as "cleared" so round can end
		berkeley_people_cleared += 1
		print("Game Manager: Berkeley cleared count incremented to:", berkeley_people_cleared)
	
	# Character handles increment_interacted_characters() call
	# Don't advance time automatically - time is managed by level system
	# advance_time(1)

func _on_character_rejected(character):
	# Handle character rejection logic
	print("========= GAME MANAGER: CHARACTER REJECTED =========")
	print("Game Manager: Character rejected:", character.variant_name)
	print("Game Manager: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	print("Game Manager: Berkeley stats BEFORE rejection:")
	print("  - berkeley_people_in_location:", berkeley_people_in_location)
	print("  - berkeley_people_cleared:", berkeley_people_cleared)
	print("  - Remaining:", berkeley_people_in_location - berkeley_people_cleared)
	
	# If it's a Berkeley student being rejected, that's correct
	if character.character_type == 1:
		print("Game Manager: ✅ Correctly rejected Berkeley student")
		berkeley_people_cleared += 1
		print("Game Manager: ✅ Berkeley cleared count incremented to:", berkeley_people_cleared)
		print("Game Manager: Berkeley stats AFTER rejection:")
		print("  - berkeley_people_in_location:", berkeley_people_in_location)
		print("  - berkeley_people_cleared:", berkeley_people_cleared)
		print("  - Remaining:", berkeley_people_in_location - berkeley_people_cleared)
	else:
		# If it's a Stanford student being rejected, that's wrong - decrease morale
		print("Game Manager: ❌ Incorrectly rejected Stanford student - decreasing morale")
		print("Game Manager: Current morale before decrease:", MoraleManager.get_morale())
		MoraleManager.decrease_morale()
		print("Game Manager: Current morale after decrease:", MoraleManager.get_morale())
	
	print("=====================================================")
	
	# Character handles increment_interacted_characters() call
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
		advance_time(TIME_SCALE_MINUTES_PER_TICK) # Advance 1 minute every half second

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
	
	# Check for workday end (9:00 PM)
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
	# Hide inspection panel if it exists and is visible
	var inspection_panel = find_inspection_panel()
	if inspection_panel and inspection_panel.visible:
		inspection_panel.visible = false
		print("GAME MANAGER: Closed inspection panel due to workday end")
	
	# Play game over sound and stop background audio
	AudioManager.play_game_over()
	AudioManager.stop_background_audio()
	
	# Stop all timers
	time_timer.stop()
	LevelManager.stop_level_timer()
	
	# Pause the scene tree (this freezes all animations, movement, etc.)
	get_tree().paused = true
	
	# Show the game over screen for time-based game over
	if game_over_screen:
		# Set the game over screen to process even when paused
		game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		# Pass current location number instead of days
		var current_location = LevelManager.get_current_level()
		game_over_screen.show_game_over(current_location, false)
	
	workday_ended.emit()
	print("Game Manager: Workday ended - everything frozen, game over sound playing")

func _on_morale_depleted():
	print("GAME MANAGER DEBUG: ⚠️ RECEIVED morale_depleted signal - starting game over process")
	
	# Hide inspection panel if it exists and is visible
	var inspection_panel = find_inspection_panel()
	if inspection_panel and inspection_panel.visible:
		inspection_panel.visible = false
		print("GAME MANAGER DEBUG: Closed inspection panel due to morale depletion")
	
	# Stop background music immediately
	AudioManager.stop_background_audio()
	print("GAME MANAGER DEBUG: Stopped background audio")
	
	# Stop all timers
	time_timer.stop()
	LevelManager.stop_level_timer()
	print("GAME MANAGER DEBUG: Stopped all timers")
	
	# Find game over screen immediately, don't rely on cached reference
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	var ui_layer = current_scene.get_node_or_null("UI")
	var found_game_over_screen = null
	
	if ui_layer:
		found_game_over_screen = ui_layer.get_node_or_null("GameOver")
		print("GAME MANAGER DEBUG: Found game over screen:", found_game_over_screen != null)
	
	# If we can't find it in the current scene, try the main map
	if not found_game_over_screen:
		var main_map = get_tree().get_first_node_in_group("main_map")
		if main_map:
			var main_ui = main_map.get_node_or_null("UI")
			if main_ui:
				found_game_over_screen = main_ui.get_node_or_null("GameOver")
				print("GAME MANAGER DEBUG: Found game over screen in main map:", found_game_over_screen != null)
	
	# Pause the scene tree immediately
	get_tree().paused = true
	print("GAME MANAGER DEBUG: Game paused")
	
	# Show the game over screen with morale depleted reason
	if found_game_over_screen:
		print("GAME MANAGER DEBUG: Found game over screen, showing it...")
		# Set the game over screen to process even when paused
		found_game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		# Pass current location number instead of days
		var current_location = LevelManager.get_current_level()
		found_game_over_screen.show_game_over(current_location, true)
		print("GAME MANAGER DEBUG: ✅ Game over screen should now be visible")
	else:
		print("GAME MANAGER DEBUG: ❌ ERROR - Could not find game over screen anywhere!")
	
	# Play game over sound AFTER the screen appears
	AudioManager.play_game_over()
	print("GAME MANAGER DEBUG: Playing game over sound")
	
	print("Game Manager: Game over - everything frozen, game over sound playing")

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
	print("========= BERKELEY PERSON REGISTERED =========")
	print("Game Manager: Berkeley person registered. Total:", berkeley_people_in_location)
	print("Game Manager: Current Berkeley stats:")
	print("  - berkeley_people_in_location:", berkeley_people_in_location)
	print("  - berkeley_people_cleared:", berkeley_people_cleared)
	print("  - Remaining:", berkeley_people_in_location - berkeley_people_cleared)
	print("===============================================")

# Functions to track total characters in location
func register_character():
	total_characters_in_location += 1
	print("Game Manager: Character registered. Total:", total_characters_in_location)

func increment_interacted_characters():
	characters_interacted_with += 1
	print("Game Manager: Character interaction count:", characters_interacted_with, "/", total_characters_in_location)
	
	# Check if we should auto-skip
	check_auto_skip_conditions()

func check_auto_skip_conditions():
	# Check if all characters have been interacted with (approved or rejected)
	var all_characters_processed = (characters_interacted_with >= total_characters_in_location)
	
	# Check if all Berkeley students have been rejected (cleared)
	var all_berkeley_rejected = (berkeley_people_in_location - berkeley_people_cleared) <= 0
	
	print("=== AUTO-SKIP CHECK DEBUG ===")
	print("Game Manager: Characters processed:", characters_interacted_with, "/", total_characters_in_location)
	print("Game Manager: Berkeley in location:", berkeley_people_in_location)
	print("Game Manager: Berkeley cleared:", berkeley_people_cleared)
	print("Game Manager: Berkeley remaining:", berkeley_people_in_location - berkeley_people_cleared)
	print("Game Manager: Planned characters for round:", planned_characters_for_round)
	print("Game Manager: All planned characters spawned:", all_planned_characters_spawned)
	print("Game Manager: All characters processed:", all_characters_processed)
	print("Game Manager: All Berkeley rejected:", all_berkeley_rejected)
	print("Game Manager: Total characters > 0:", total_characters_in_location > 0)
	print("============================")
	
	# End round early ONLY if ALL three conditions are met:
	# 1. All characters have been processed (approved/rejected)
	# 2. All Berkeley students have been handled (rejected OR approved - both count as "cleared")
	# 3. All planned characters for the round have actually spawned
	if all_characters_processed and all_berkeley_rejected and all_planned_characters_spawned and total_characters_in_location > 0:
		print("Game Manager: ✅ Early round completion conditions met! All Berkeley students handled, all characters processed, and all planned characters spawned.")
		
		# Apply morale penalties for Berkeley students that were accepted instead of rejected
		if berkeley_people_accepted > 0:
			print("Game Manager: Applying morale penalties for", berkeley_people_accepted, "Berkeley students that were accepted")
			for i in range(berkeley_people_accepted):
				MoraleManager.decrease_morale()
				print("Game Manager: Decreased morale for accepted Berkeley student", i + 1, "/", berkeley_people_accepted)
		
		# Complete the level immediately - don't advance time since we're ending early
		await get_tree().create_timer(0.5).timeout
		var current_level = LevelManager.get_current_level()
		LevelManager.complete_level(current_level)
	else:
		print("Game Manager: ❌ Early completion conditions NOT met:")
		if not all_characters_processed:
			print("  - Not all characters processed")
		if not all_berkeley_rejected:
			print("  - Berkeley students still remaining")
		if not all_planned_characters_spawned:
			print("  - Not all planned characters have spawned yet")
		if total_characters_in_location <= 0:
			print("  - No characters in location")

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

func set_planned_characters_for_round(count: int):
	planned_characters_for_round = count
	all_planned_characters_spawned = false
	print("Game Manager: Set planned characters for round:", count)

func mark_all_planned_characters_spawned():
	all_planned_characters_spawned = true
	print("Game Manager: All planned characters have spawned")
	# Check auto-skip conditions when all characters are spawned
	check_auto_skip_conditions()

func find_inspection_panel():
	# Try to find the inspection panel in the current scene
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	
	# First try the UI layer
	var ui_layer = current_scene.get_node_or_null("UI")
	if ui_layer:
		var panel = ui_layer.get_node_or_null("InspectionPanel")
		if panel:
			return panel
	
	# Try the CanvasLayer/Control structure (location template style)
	var canvas_layer = current_scene.get_node_or_null("CanvasLayer")
	if canvas_layer:
		var control = canvas_layer.get_node_or_null("Control")
		if control:
			var panel = control.get_node_or_null("InspectionPanel")
			if panel:
				return panel
	
	# Last resort: search recursively
	return find_inspection_panel_recursive(current_scene)

func find_inspection_panel_recursive(node: Node) -> Node:
	if node.name == "InspectionPanel":
		return node
	
	for child in node.get_children():
		var result = find_inspection_panel_recursive(child)
		if result:
			return result
	
	return null
