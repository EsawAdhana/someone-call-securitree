extends Button

func _ready():
	# Set mouse filter to pass through
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect the button's pressed signal
	pressed.connect(_on_pressed)
	
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pressed():
	# Tell PauseManager to toggle pause state
	PauseManager.toggle_pause() 