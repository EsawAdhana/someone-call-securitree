extends Control

# Get the nodes
@onready var resume_button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeSlider
@onready var volume_down = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeDown
@onready var volume_up = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeUp
@onready var volume_percent = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumePercent
@onready var shortcuts_list = $PanelContainer/MarginContainer/VBoxContainer/ShortcutsContainer/ShortcutsList

const VOLUME_STEP = 0.05  # 5% volume change for button/key presses

func _ready():
	# Add to pause_menu group for easy access
	add_to_group("pause_menu")
	
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect the resume button's pressed signal
	resume_button.pressed.connect(_on_resume_button_pressed)
	
	# Connect volume controls
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_down.pressed.connect(_on_volume_down_pressed)
	volume_up.pressed.connect(_on_volume_up_pressed)
	
	# Connect to PauseManager signals
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	
	# Set initial volume
	_update_volume(db_to_linear(AudioServer.get_bus_volume_db(0)))
	
	# Hide the pause menu initially
	hide()

func _input(event):
	# Only handle volume controls when visible
	if visible:
		if event.is_action_pressed("ui_left"):  # Left arrow
			_on_volume_down_pressed()
		elif event.is_action_pressed("ui_right"):  # Right arrow
			_on_volume_up_pressed()

func _on_pause_state_changed(is_paused: bool):
	# Update visibility based on pause state
	visible = is_paused

func _on_resume_button_pressed():
	# Tell PauseManager to unpause
	PauseManager.unpause()

func _on_volume_changed(value: float):
	_update_volume(value)

func _on_volume_down_pressed():
	_update_volume(volume_slider.value - VOLUME_STEP)
	AudioManager.play_ui_click()

func _on_volume_up_pressed():
	_update_volume(volume_slider.value + VOLUME_STEP)
	AudioManager.play_ui_click()

func _update_volume(value: float):
	# Clamp value between 0 and 1
	value = clamp(value, 0.0, 1.0)
	
	# Update slider
	volume_slider.value = value
	
	# Update percentage label
	volume_percent.text = str(round(value * 100)) + "%"
	
	# Convert linear volume (0-1) to decibels and set it
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
