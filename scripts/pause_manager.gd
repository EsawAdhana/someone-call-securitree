extends Node

# Signal for when pause state changes
signal pause_state_changed(is_paused: bool)

# Track if the game is paused
var is_paused: bool = false

func _ready():
	# Make sure we're in the right process mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize pause state
	is_paused = false
	get_tree().paused = false
	
	# Connect to tree to handle scene changes
	get_tree().root.ready.connect(_on_tree_ready)

func _on_tree_ready():
	# Ensure we're unpaused when a new scene loads
	if is_paused:
		unpause()

func toggle_pause():
	if is_paused:
		unpause()
	else:
		pause()

func pause():
	if not is_paused:
		print("PauseManager: Pausing game")
		is_paused = true
		get_tree().paused = true
		pause_state_changed.emit(true)

func unpause():
	if is_paused:
		print("PauseManager: Unpausing game")
		is_paused = false
		get_tree().paused = false
		pause_state_changed.emit(false)

# Handle input to catch the ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause() 