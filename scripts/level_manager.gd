extends Node

signal level_started(level_number)
signal level_completed(level_number)
signal level_failed(level_number)
signal location_unlocked(location_name)
signal time_limit_reached(level_number)
signal victory_achieved(final_morale)

# Level configuration
const LEVEL_DURATION_SECONDS = 30 # 30 seconds per level/round per user request
const TIME_INCREMENT_PER_LEVEL = 60 # Each level adds 60 minutes (1 hour) of game time

# Level progression order - first location to last
const LOCATION_ORDER = [
	"FloMoArea",
	"TresidderArea",
	"FarrillagaArea",
	"Y2E2Area",
	"CoDaArea",
	"CantorArea",
	"MainQuadArea",
	"GreenLibraryArea",
	"MeyerGreenArea",
	"HooverTowerArea",
	"GSBArea",
	"StadiumArea"
]

# Game state
var current_level: int = 1  # Start at level 1 (Florence Moore Hall)
var max_level: int = 1      # Start with max level at 1
var unlocked_locations: Array = []
var is_timer_running: bool = false
var level_timer: Timer
var level_start_time: int = 0

# References
var game_manager: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set up level timer
	level_timer = Timer.new()
	level_timer.wait_time = LEVEL_DURATION_SECONDS
	level_timer.one_shot = true
	level_timer.timeout.connect(_on_level_timer_timeout)
	add_child(level_timer)
	
	# Initialize with only the first location unlocked
	unlocked_locations.append(LOCATION_ORDER[0])  # Only Florence Moore Hall (FloMoArea)
	print("LEVEL: Starting with only", LOCATION_ORDER[0], "unlocked")

func start_level(level_number: int):
	# Only update current_level if it's different to avoid confusion
	if current_level != level_number:
		print("LEVEL: Updating current level from", current_level, "to", level_number)
		current_level = level_number
	else:
		print("LEVEL: Current level already set to", level_number)
	
	print("LEVEL: Starting level", level_number)
	
	# Start level timer (10 seconds for location visit)
	is_timer_running = true
	level_start_time = Time.get_ticks_msec()
	level_timer.start()
	
	level_started.emit(level_number)

func stop_level_timer():
	print("LEVEL: Stopping level timer")
	is_timer_running = false
	level_timer.stop()

func _on_level_timer_timeout():
	print("LEVEL: Level", current_level, "time limit reached")
	is_timer_running = false
	
	# Check if game is already over (paused) before proceeding
	if get_tree().paused:
		print("LEVEL: Game is paused (likely game over), skipping level completion")
		return
	
	# Check if security dialogue is currently active
	var security_dialogue_manager = get_node_or_null("/root/SecurityDialogueManager")
	if security_dialogue_manager and security_dialogue_manager.is_dialogue_active():
		print("LEVEL: Time limit reached but security dialogue is active, waiting for completion")
		# Connect to the dialogue completion signal and wait
		security_dialogue_manager.dialogue_completed.connect(_on_security_dialogue_completed_for_timeout.bind(current_level), CONNECT_ONE_SHOT)
		return
	
	# Emit signal that time limit was reached
	time_limit_reached.emit(current_level)
	
	# Boot player back to main map and unlock next location
	complete_level(current_level)

func _on_security_dialogue_completed_for_timeout(level_number: int):
	print("LEVEL: Security dialogue completed after timeout, now finishing level", level_number)
	# Emit signal that time limit was reached
	time_limit_reached.emit(level_number)
	# Complete the level
	complete_level(level_number)

func complete_level(level_number: int):
	print("LEVEL: Completing level", level_number)
	
	# Check if game is already over (paused) before proceeding with level completion
	if get_tree().paused:
		print("LEVEL: Game is paused (likely game over), skipping level completion")
		return
	
	# Check if security dialogue is currently active
	var security_dialogue_manager = get_node_or_null("/root/SecurityDialogueManager")
	if security_dialogue_manager and security_dialogue_manager.is_dialogue_active():
		print("LEVEL: Security dialogue is active, waiting for completion before ending level")
		# Connect to the dialogue completion signal and wait
		security_dialogue_manager.dialogue_completed.connect(_on_security_dialogue_completed_for_level_end.bind(level_number), CONNECT_ONE_SHOT)
		return
	
	# If no active dialogue, proceed with normal level completion
	_finish_level_completion(level_number)

func _on_security_dialogue_completed_for_level_end(level_number: int):
	print("LEVEL: Security dialogue completed, now finishing level", level_number)
	_finish_level_completion(level_number)

func _finish_level_completion(level_number: int):
	# Stop the timer
	stop_level_timer()
	
	# Check if this was the final level (Stadium - level 12)
	if level_number >= LOCATION_ORDER.size():
		print("LEVEL: All levels completed! Victory achieved!")
		# Get final morale and emit victory signal
		var final_morale = MoraleManager.get_morale()
		victory_achieved.emit(final_morale)
		return
	
	# Store the next location to unlock (if available)
	var next_location_to_unlock = ""
	if level_number < LOCATION_ORDER.size():
		next_location_to_unlock = LOCATION_ORDER[level_number] # level_number is 1-based, array is 0-based
		unlocked_locations.append(next_location_to_unlock)
		max_level = level_number + 1
		# Update current_level to the next level to keep it in sync
		current_level = level_number + 1
		print("LEVEL: Advanced to next level:", current_level)
		print("LEVEL: Will unlock next location after scene change:", next_location_to_unlock)
	
	level_completed.emit(level_number)
	
	# Return to main map
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")
	
	# Emit the unlock signal after a short delay to ensure the main map scene is ready
	if next_location_to_unlock != "":
		# Use call_deferred to ensure the signal is emitted after the scene is fully loaded
		call_deferred("_emit_delayed_unlock", next_location_to_unlock)

func _emit_delayed_unlock(location_name: String):
	# Add a small delay to ensure the main map scene is fully ready
	await get_tree().create_timer(0.1).timeout
	print("LEVEL: Emitting delayed unlock signal for:", location_name)
	location_unlocked.emit(location_name)

func fail_level(level_number: int):
	print("LEVEL: Failed level", level_number)
	stop_level_timer()
	level_failed.emit(level_number)

func is_location_unlocked(location_name: String) -> bool:
	return location_name in unlocked_locations

func get_current_level() -> int:
	return current_level

func get_max_level() -> int:
	return max_level

func get_unlocked_locations() -> Array:
	return unlocked_locations.duplicate()

func get_level_target_time() -> int:
	# Calculate target time: 9:00 AM + (level * 60 minutes)
	# Level 1: 10:00 AM, Level 2: 11:00 AM, etc.
	return 9 * 60 + (current_level * TIME_INCREMENT_PER_LEVEL) # Return minutes since midnight

func set_game_manager_reference(gm: Node):
	game_manager = gm
	print("LEVEL: Set game manager reference")

func reset_levels():
	current_level = 1
	max_level = 1
	unlocked_locations.clear()
	# Start with only the first location unlocked
	unlocked_locations.append(LOCATION_ORDER[0])
	stop_level_timer()
	print("LEVEL: Reset to level 1 with only", LOCATION_ORDER[0], "unlocked")

func get_location_for_level(level_number: int) -> String:
	if level_number > 0 and level_number <= LOCATION_ORDER.size():
		return LOCATION_ORDER[level_number - 1]
	return ""

# Debug function to get complete level state information
func get_level_debug_info() -> Dictionary:
	return {
		"current_level": current_level,
		"max_level": max_level,
		"current_location": get_location_for_level(current_level),
		"unlocked_locations": unlocked_locations.duplicate(),
		"is_timer_running": is_timer_running
	}

# Function to verify level consistency
func verify_level_consistency() -> bool:
	var is_consistent = true
	var debug_info = get_level_debug_info()
	
	print("LEVEL DEBUG: ", debug_info)
	
	# Check if current level location is unlocked
	var current_location = get_location_for_level(current_level)
	if current_location != "" and not is_location_unlocked(current_location):
		print("LEVEL WARNING: Current level location is not unlocked!")
		is_consistent = false
	
	# Check if max_level matches unlocked locations
	if unlocked_locations.size() != max_level:
		print("LEVEL WARNING: Max level doesn't match unlocked locations count!")
		is_consistent = false
	
	return is_consistent 

# Speedy mode function to jump directly to level 12 (Stadium)
func speedy_mode_to_level_12():
	print("LEVEL: Activating speedy mode - jumping to level 12!")
	
	# Only allow if we're in level 1 or 2
	if current_level > 2:
		print("LEVEL: Speedy mode only available in levels 1-2, current level is:", current_level)
		return false
	
	# Stop any running timer
	stop_level_timer()
	
	# Set current level to 12 (Stadium)
	current_level = 12
	max_level = 12
	
	# Unlock all locations up to Stadium
	unlocked_locations.clear()
	for i in range(LOCATION_ORDER.size()):
		unlocked_locations.append(LOCATION_ORDER[i])
	
	print("LEVEL: Speedy mode activated - jumped to level 12 with all locations unlocked")
	print("LEVEL: Unlocked locations:", unlocked_locations)
	
	# Return to main map to show all unlocked locations
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")
	
	return true 