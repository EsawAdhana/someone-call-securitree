extends CanvasLayer

@onready var pause_button = $PauseButton
@onready var pause_menu = $PauseMenu
@onready var morale_bar = $TopMoraleBar

var has_entered_main_map = false

func _ready():
	# Set process mode to handle input while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure all nodes exist
	if not pause_button:
		push_error("GlobalUI: Missing pause button!")
		return
	
	if not pause_menu:
		push_error("GlobalUI: Missing pause menu!")
		return
		
	if not morale_bar:
		push_error("GlobalUI: Missing morale bar!")
		return
	
	print("GlobalUI: Found pause button, menu, and morale bar")
	
	# Hide the morale bar initially - it should only show after entering main map
	morale_bar.hide()
	print("GlobalUI: Morale bar hidden initially")
	
	# Make sure the pause menu starts hidden
	pause_menu.hide()
	print("GlobalUI: Pause menu hidden initially")
	
	# Check if we should show morale bar (only on main map and after first visit)
	call_deferred("check_and_show_morale_bar")
	
	# The pause button script handles the pause functionality through PauseManager
	# The pause menu responds to PauseManager.pause_state_changed signal
	
	print("GlobalUI: UI system initialized")

func check_and_show_morale_bar():
	# Check if we're currently in the main map scene
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "MainMap":
		if not has_entered_main_map:
			has_entered_main_map = true
			print("GlobalUI: Entered main map for first time - showing morale bar")
		morale_bar.show()

func show_morale_bar():
	# Public method to force show the morale bar (if needed)
	if morale_bar:
		has_entered_main_map = true
		morale_bar.show()
		print("GlobalUI: Morale bar shown")

func hide_morale_bar():
	# Public method to hide the morale bar (if needed)
	if morale_bar:
		morale_bar.hide()
		print("GlobalUI: Morale bar hidden")

func reset_morale_bar_state():
	# Reset the state when restarting the game
	has_entered_main_map = false
	if morale_bar:
		morale_bar.hide()
		print("GlobalUI: Morale bar state reset") 
