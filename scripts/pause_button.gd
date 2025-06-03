extends Button

func _ready():
	# Set mouse filter to pass through
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect the button's pressed signal
	pressed.connect(_on_pressed)
	
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pressed():
	# Play UI click sound
	AudioManager.play_ui_click()
	
	# Find the pause menu in the scene tree
	var pause_menu = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu:
		pause_menu.toggle_pause()
	else:
		# If we can't find the pause menu, use PauseManager directly
		PauseManager.toggle_pause() 