extends Button

func _ready():
	print("PAUSE_BUTTON: Pause button _ready() called")
	print("PAUSE_BUTTON: Position:", position, "Size:", size)
	print("PAUSE_BUTTON: Anchors - Left:", anchor_left, "Right:", anchor_right, "Top:", anchor_top, "Bottom:", anchor_bottom)
	print("PAUSE_BUTTON: Offsets - Left:", offset_left, "Right:", offset_right, "Top:", offset_top, "Bottom:", offset_bottom)
	
	# Set mouse filter to pass through
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect the button's pressed signal
	pressed.connect(_on_pressed)
	
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make sure it's visible
	visible = true
	print("PAUSE_BUTTON: Visible:", visible)

func _on_pressed():
	print("PAUSE_BUTTON: Pause button pressed!")
	# Tell PauseManager to toggle pause state
	PauseManager.toggle_pause() 