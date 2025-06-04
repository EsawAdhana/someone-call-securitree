extends Node

# Singleton for managing security dialogue system
# This replaces the envelope system with Persona 5-style character dialogues

signal dialogue_completed

# Track dialogue state
var dialogue_shown_for_level = false
var current_dialogue_instance = null
var tutorial_feedback_instances: Array = [] # Track tutorial feedback instances

# Locations that should show security dialogue (same as envelope system)
const DIALOGUE_LOCATIONS = ["FloMoArea", "Y2E2Area", "GreenLibraryArea", "StadiumArea", "HooverTowerArea", "MainQuadArea", "GSBArea", "MeyerGreenArea", "TresidderArea", "FarrillagaArea", "CoDaArea", "CantorArea"]

func _ready():
	# Connect to level manager signals to reset dialogue state
	LevelManager.level_started.connect(_on_level_started)
	LevelManager.location_unlocked.connect(_on_location_unlocked)

func should_show_dialogue(location_name: String) -> bool:
	# Show dialogue for all dialogue locations when entering
	return DIALOGUE_LOCATIONS.has(location_name) and not dialogue_shown_for_level

func should_require_dialogue_completion(location_name: String) -> bool:
	# Require dialogue completion before entering location (same as envelope system)
	return DIALOGUE_LOCATIONS.has(location_name) and not dialogue_shown_for_level

func show_security_dialogue(location_name: String, ui_canvas_layer: CanvasLayer):
	"""Show security dialogue for the given location"""
	if dialogue_shown_for_level:
		print("SECURITY DIALOGUE MANAGER: Dialogue already shown for this level")
		return
	
	print("SECURITY DIALOGUE MANAGER: Showing dialogue for location:", location_name)
	
	# Load and instance the security dialogue scene
	var dialogue_scene = load("res://scenes/security_dialogue.tscn")
	if dialogue_scene:
		current_dialogue_instance = dialogue_scene.instantiate()
		ui_canvas_layer.add_child(current_dialogue_instance)
		
		# Connect to completion signal
		current_dialogue_instance.dialogue_completed.connect(_on_dialogue_completed)
		
		# Show dialogue for this location
		current_dialogue_instance.show_dialogue_for_location(location_name)
		
		print("SECURITY DIALOGUE MANAGER: Dialogue instance created and shown")
	else:
		print("SECURITY DIALOGUE MANAGER: ERROR - Could not load dialogue scene")

func _on_dialogue_completed():
	"""Handle when dialogue is completed"""
	print("SECURITY DIALOGUE MANAGER: Dialogue completed")
	dialogue_shown_for_level = true
	
	# Clean up the dialogue instance
	if current_dialogue_instance:
		current_dialogue_instance.queue_free()
		current_dialogue_instance = null
	
	# Emit completion signal
	dialogue_completed.emit()

func _on_level_started(level_number: int):
	"""Reset dialogue state when a new level starts"""
	print("SECURITY DIALOGUE MANAGER: Level", level_number, "started, resetting dialogue state")
	dialogue_shown_for_level = false
	
	# Clean up any remaining tutorial feedback instances
	for instance in tutorial_feedback_instances:
		if instance != null and is_instance_valid(instance):
			instance.queue_free()
	tutorial_feedback_instances.clear()
	print("SECURITY DIALOGUE MANAGER: Cleared tutorial feedback instances")

func _on_location_unlocked(location_name: String):
	"""Called when a new location is unlocked"""
	print("SECURITY DIALOGUE MANAGER: Location unlocked:", location_name)

func is_dialogue_active() -> bool:
	"""Check if dialogue is currently active"""
	# Check main dialogue instance
	var main_dialogue_active = current_dialogue_instance != null and current_dialogue_instance.is_dialogue_active()
	
	# Check tutorial feedback instances
	var tutorial_feedback_active = false
	for instance in tutorial_feedback_instances:
		if instance != null and is_instance_valid(instance) and instance.is_dialogue_active():
			tutorial_feedback_active = true
			break
	
	return main_dialogue_active or tutorial_feedback_active

func mark_dialogue_as_completed():
	"""Mark dialogue as completed (for external calls)"""
	dialogue_shown_for_level = true

# Function to register a tutorial feedback instance
func register_tutorial_feedback_instance(instance):
	"""Register a tutorial feedback dialogue instance for tracking"""
	tutorial_feedback_instances.append(instance)
	print("SECURITY DIALOGUE MANAGER: Registered tutorial feedback instance, total:", tutorial_feedback_instances.size())
	
	# Connect to its completion signal to clean up
	if instance.has_signal("dialogue_completed"):
		instance.dialogue_completed.connect(_on_tutorial_feedback_completed.bind(instance))

func _on_tutorial_feedback_completed(instance):
	"""Clean up tutorial feedback instance when completed"""
	print("SECURITY DIALOGUE MANAGER: Tutorial feedback instance completed")
	tutorial_feedback_instances.erase(instance)
	print("SECURITY DIALOGUE MANAGER: Remaining tutorial feedback instances:", tutorial_feedback_instances.size())
	
	# If this was the last dialogue, emit our completion signal
	if not is_dialogue_active():
		dialogue_completed.emit() 