extends Control

# Get the nodes
@onready var resume_button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeSlider
@onready var volume_down = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeDown
@onready var volume_up = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumeHBox/VolumeUp
@onready var volume_percent = $PanelContainer/MarginContainer/VBoxContainer/VolumeControl/VolumePercent
@onready var shortcuts_list = $PanelContainer/MarginContainer/VBoxContainer/ShortcutsContainer/ShortcutsList
@onready var easy_mode_toggle = $PanelContainer/MarginContainer/VBoxContainer/EasyModeControl/EasyModeHBox/EasyModeToggle
@onready var speedy_mode_button = $PanelContainer/MarginContainer/VBoxContainer/SpeedyModeControl/SpeedyModeHBox/SpeedyModeButton

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
	
	# Connect easy mode toggle
	easy_mode_toggle.toggled.connect(_on_easy_mode_toggled)
	
	# Connect speedy mode button
	speedy_mode_button.pressed.connect(_on_speedy_mode_pressed)
	
	# Connect to PauseManager signals
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	
	# Set initial volume
	_update_volume(db_to_linear(AudioServer.get_bus_volume_db(0)))
	
	# Set initial easy mode state
	easy_mode_toggle.button_pressed = GameManager.is_easy_mode_enabled()
	
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
	
	# Update speedy mode button availability when pause menu opens
	if is_paused:
		_update_speedy_mode_button()

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

func _on_easy_mode_toggled(button_pressed: bool):
	# Update the easy mode setting in GameManager
	GameManager.set_easy_mode(button_pressed)
	AudioManager.play_ui_click()

func _on_speedy_mode_pressed():
	# Check if speedy mode is available (only in levels 1-2)
	var current_level = LevelManager.get_current_level()
	if current_level > 2:
		print("PAUSE MENU: Speedy mode not available in level", current_level)
		AudioManager.play_ui_click()
		return
	
	# Activate speedy mode
	print("PAUSE MENU: Activating speedy mode!")
	var success = LevelManager.speedy_mode_to_level_12()
	
	if success:
		# Unpause the game since we're returning to main map
		PauseManager.unpause()
	
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

func _update_speedy_mode_button():
	var current_level = LevelManager.get_current_level()
	var is_available = current_level <= 2
	
	speedy_mode_button.disabled = not is_available
	
	if is_available:
		speedy_mode_button.modulate = Color.WHITE
		speedy_mode_button.text = "Jump to Level 12 (Available)"
	else:
		speedy_mode_button.modulate = Color.GRAY
		speedy_mode_button.text = "Jump to Level 12 (Only in Levels 1-2)"
