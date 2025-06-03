extends Control

# Get the resume button node
@onready var resume_button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton

func _ready():
	# Add to pause_menu group for easy access
	add_to_group("pause_menu")
	
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect the resume button's pressed signal
	resume_button.pressed.connect(_on_resume_button_pressed)
	
	# Connect to PauseManager signals
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	
	# Hide the pause menu initially
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key
		toggle_pause()

func toggle_pause():
	if visible:
		# If we're already visible, unpause
		PauseManager.unpause()
	else:
		# If we're not visible, pause
		PauseManager.pause()

func _on_pause_state_changed(is_paused: bool):
	# Update visibility based on pause state
	visible = is_paused
	
	if visible:
		# Play UI sound when pausing
		AudioManager.play_ui_click()

func _on_resume_button_pressed():
	# Play UI sound
	AudioManager.play_ui_click()
	
	# Unpause the game
	PauseManager.unpause()