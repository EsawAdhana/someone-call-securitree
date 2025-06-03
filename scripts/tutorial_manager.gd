extends Node

# Tutorial state tracking
var is_tutorial_active: bool = false
var tutorial_characters_spawned: int = 0
var tutorial_stanford_identified: bool = false
var tutorial_berkeley_identified: bool = false
var tutorial_round_complete: bool = false
var tutorial_timer_paused: bool = false

# Tutorial target time (9:30 AM)
const TUTORIAL_PAUSE_MINUTE: int = 30
const TUTORIAL_PAUSE_HOUR: int = 9

# References
var game_manager: Node = null
var level_manager: Node = null

# Tutorial feedback messages
const TUTORIAL_FEEDBACK = {
	"stanford_correct": "Great! You correctly identified a Stanford student.",
	"berkeley_correct": "Excellent! You successfully caught a Berkeley infiltrator.",
	"stanford_wrong": "Wait! This is a legitimate Stanford student. Let them through.",
	"berkeley_wrong": "Be careful! This person seems suspicious. Check their ID more carefully.",
	"tutorial_complete": "Tutorial complete! You've successfully identified both characters."
}

signal tutorial_feedback(message: String)
signal tutorial_completed()

func _ready():
	# Connect to level manager signals
	if LevelManager:
		level_manager = LevelManager
		level_manager.level_started.connect(_on_level_started)
	
	# Connect to game manager signals
	if get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

func _on_level_started(level_number: int):
	print("TUTORIAL: Level started:", level_number)
	
	# Check if this is the first level (FloMo)
	if level_number == 1:
		start_tutorial()
	else:
		is_tutorial_active = false

func start_tutorial():
	print("TUTORIAL: Starting tutorial mode for FloMo")
	is_tutorial_active = true
	tutorial_characters_spawned = 0
	tutorial_stanford_identified = false
	tutorial_berkeley_identified = false
	tutorial_round_complete = false
	tutorial_timer_paused = false
	
	# Emit tutorial feedback
	tutorial_feedback.emit("Welcome to SecuriTree! This is your first assignment. Check each person's ID carefully and decide whether to let them in or turn them away.")

func check_tutorial_timer():
	"""Check if we should pause the timer at 9:30 during tutorial"""
	if not is_tutorial_active or tutorial_timer_paused:
		return
	
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
		if not game_manager:
			return
	
	# Check if we've reached 9:30 AM
	if game_manager.current_hour == TUTORIAL_PAUSE_HOUR and game_manager.current_minute >= TUTORIAL_PAUSE_MINUTE:
		pause_tutorial_timer()

func pause_tutorial_timer():
	"""Pause the timer during tutorial at 9:30"""
	if tutorial_timer_paused:
		return
		
	print("TUTORIAL: Pausing timer at 9:30 AM for tutorial")
	tutorial_timer_paused = true
	
	if game_manager and game_manager.time_timer:
		game_manager.time_timer.stop()
	
	tutorial_feedback.emit("Time paused for tutorial. Take your time to examine each person carefully.")

func resume_tutorial_timer():
	"""Resume the timer after tutorial is complete"""
	if not tutorial_timer_paused:
		return
		
	print("TUTORIAL: Resuming timer after tutorial completion")
	tutorial_timer_paused = false
	
	if game_manager and game_manager.time_timer:
		game_manager.time_timer.start()

func handle_character_decision(character, is_approved: bool):
	"""Handle character approval/rejection during tutorial"""
	if not is_tutorial_active:
		return true  # Normal processing
	
	print("TUTORIAL: Handling character decision for:", character.variant_name)
	print("TUTORIAL: Character type:", "Stanford" if character.character_type == 0 else "Berkeley")
	print("TUTORIAL: Decision:", "Approved" if is_approved else "Rejected")
	
	var is_stanford = character.character_type == 0
	var correct_decision = false
	var feedback_message = ""
	
	if is_stanford and is_approved:
		# Correctly approved Stanford student
		correct_decision = true
		tutorial_stanford_identified = true
		feedback_message = TUTORIAL_FEEDBACK["stanford_correct"]
	elif not is_stanford and not is_approved:
		# Correctly rejected Berkeley student
		correct_decision = true
		tutorial_berkeley_identified = true
		feedback_message = TUTORIAL_FEEDBACK["berkeley_correct"]
	elif is_stanford and not is_approved:
		# Incorrectly rejected Stanford student
		correct_decision = false
		feedback_message = TUTORIAL_FEEDBACK["stanford_wrong"]
	elif not is_stanford and is_approved:
		# Incorrectly approved Berkeley student
		correct_decision = false
		feedback_message = TUTORIAL_FEEDBACK["berkeley_wrong"]
	
	# Always emit feedback during tutorial
	tutorial_feedback.emit(feedback_message)
	
	# If decision was incorrect, prevent it from processing
	if not correct_decision:
		print("TUTORIAL: Preventing incorrect decision")
		return false  # Block the decision
	
	# Check if tutorial is complete
	if tutorial_stanford_identified and tutorial_berkeley_identified:
		complete_tutorial()
	
	return true  # Allow correct decisions

func complete_tutorial():
	"""Complete the tutorial and end the round"""
	if tutorial_round_complete:
		return
		
	print("TUTORIAL: Tutorial complete!")
	tutorial_round_complete = true
	
	# Emit completion feedback
	tutorial_feedback.emit(TUTORIAL_FEEDBACK["tutorial_complete"])
	
	# Resume timer if it was paused
	resume_tutorial_timer()
	
	# Complete the level
	await get_tree().create_timer(2.0).timeout  # Give time to read feedback
	
	if level_manager:
		level_manager.complete_current_level()
	
	tutorial_completed.emit()

func is_tutorial_round_complete() -> bool:
	"""Check if the tutorial round should end"""
	if not is_tutorial_active:
		return false
	
	return tutorial_round_complete

func get_tutorial_status() -> Dictionary:
	"""Get current tutorial status for UI display"""
	return {
		"is_active": is_tutorial_active,
		"stanford_identified": tutorial_stanford_identified,
		"berkeley_identified": tutorial_berkeley_identified,
		"timer_paused": tutorial_timer_paused,
		"complete": tutorial_round_complete
	} 