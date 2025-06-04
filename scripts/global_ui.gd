extends CanvasLayer

@onready var pause_button = $PauseButton
@onready var pause_menu = $PauseMenu

func _ready():
	# Set process mode to handle input while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure both nodes exist
	if not pause_button:
		push_error("GlobalUI: Missing pause button!")
		return
	
	if not pause_menu:
		push_error("GlobalUI: Missing pause menu!")
		return
	
	print("GlobalUI: Found pause button and menu")
	
	# Make sure the pause menu starts hidden
	pause_menu.hide()
	print("GlobalUI: Pause menu hidden initially")
	
	# The pause button script handles the pause functionality through PauseManager
	# The pause menu responds to PauseManager.pause_state_changed signal
	
	print("GlobalUI: Pause system initialized") 
