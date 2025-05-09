# Game.gd - Simplified debugging version
extends Node

var current_location = "map"
var locations = ["stadium", "golfcourse", "oval"]
var score = 0
var lives = 3  # Track lives behind the scenes
var button_location = null
var button_timer = null
var button_spawn_timer = null
var game_over = false
var debug_label = null  # To show game state on screen

signal game_over_triggered  # Signal name

func _ready():
	# Seed the random number generator
	randomize()
	
	# Create a timer for checking if we should spawn a new button
	button_spawn_timer = Timer.new()
	button_spawn_timer.wait_time = 3  # Check every 5 seconds
	button_spawn_timer.connect("timeout", Callable(self, "try_spawn_button"))
	add_child(button_spawn_timer)
	button_spawn_timer.start()
	
	# Create a debug label to show game state
	create_debug_label()
	
	print("Game autoload initialized")
	print("Starting location: ", current_location)

func create_debug_label():
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(10, 10)
	debug_label.size = Vector2(300, 100)
	debug_label.text = "Lives: " + str(lives) + "\nScore: " + str(score)
	add_child(debug_label)

func _process(_delta):
	# Update debug label
	if debug_label:
		debug_label.text = "Lives: " + str(lives) + "\nScore: " + str(score)
		if game_over:
			debug_label.text += "\nGAME OVER!"

func change_location(new_location):
	print("Changing location from ", current_location, " to ", new_location)
	
	# Update the current location
	current_location = new_location
	
	# Check if there's a button at this location
	check_for_button()

func try_spawn_button():
	print("Checking if we should spawn a button...")
	
	# Don't spawn buttons if game is over
	if game_over:
		print("Game is over, not spawning button")
		return
		
	# Only spawn if no button is currently active
	if button_location != null:
		print("A button is already active at: ", button_location)
		return
	
	# Choose a random location that's not the current location
	var available_locations = locations.duplicate()
	
	# If player is at one of our locations, remove it from options
	if locations.has(current_location):
		available_locations.erase(current_location)
	
	# Choose a random location from available options
	if available_locations.size() > 0:
		button_location = available_locations[randi() % available_locations.size()]
		print("Spawning button at: ", button_location)
		
		# Start button timer (3 seconds)
		if button_timer != null:
			button_timer.queue_free()
		
		button_timer = Timer.new()
		button_timer.wait_time = 3
		button_timer.one_shot = true
		button_timer.connect("timeout", Callable(self, "on_button_timeout"))
		add_child(button_timer)
		button_timer.start()
	else:
		print("No available locations to spawn a button")

func check_for_button():
	# If we entered a location with an active button, show it
	if current_location == button_location:
		print("Found button at current location!")
		
		# Get current scene and tell it to spawn button
		var current_scene = get_tree().current_scene
		if current_scene.has_method("spawn_button"):
			current_scene.spawn_button()
		else:
			print("Current scene does not have spawn_button method!")

func on_button_clicked():
	print("Button clicked! +1 point")
	score += 1
	button_location = null
	
	if button_timer != null:
		button_timer.queue_free()
		button_timer = null

func on_button_timeout():
	print("Button timed out!")
	button_location = null
	button_timer = null
	
	# Decrease lives (behind the scenes)
	lives -= 1
	print("Lives remaining: ", lives)
	
	# Check for game over
	if lives <= 0:
		game_over = true
		print("GAME OVER TRIGGERED! Final score: " + str(score))
		
		# Stop the button spawn timer
		if button_spawn_timer != null:
			button_spawn_timer.stop()
		
		# Emit signal
		emit_signal("game_over_triggered")
		
		# Force show the game over screen
		call_deferred("create_game_over_overlay")

func reset_game():
	score = 0
	lives = 3
	game_over = false
	button_location = null
	
	if button_timer != null:
		button_timer.queue_free()
		button_timer = null
	
	# Restart the button spawn timer
	if button_spawn_timer != null:
		button_spawn_timer.start()
	
	print("Game reset")
	
	# Remove any game over overlay
	var root = get_tree().root
	if root.has_node("GameOverOverlay"):
		root.get_node("GameOverOverlay").queue_free()

func create_game_over_overlay():
	print("Creating game over overlay")
	
	# First, remove any existing overlay to avoid duplicates
	var root = get_tree().root
	if root.has_node("GameOverOverlay"):
		root.get_node("GameOverOverlay").queue_free()
	
	# Pause the game
	get_tree().paused = true
	
	# Create a completely new scene for the game over overlay
	var overlay_scene = Node2D.new()
	overlay_scene.name = "GameOverOverlay"
	overlay_scene.z_index = 100  # Ensure it's on top
	overlay_scene.process_mode = Node.PROCESS_MODE_ALWAYS  # Make it process even when game is paused
	root.add_child(overlay_scene)
	
	# Create a CanvasLayer to ensure our UI is above everything else
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	overlay_scene.add_child(canvas_layer)
	
	# Create full-screen Panel that covers everything
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	
	# Set custom style for panel to ensure it's dark and opaque
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.9)  # Very dark, almost opaque
	style_box.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style_box)
	canvas_layer.add_child(panel)
	
	# Create a CenterContainer to properly center everything
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.size_flags_horizontal = Control.SIZE_FILL
	center_container.size_flags_vertical = Control.SIZE_FILL
	panel.add_child(center_container)
	
	# Create a VBoxContainer for our centered content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 30)
	center_container.add_child(vbox)
	
	# Create a PanelContainer with a visible background for our content
	var panel_container = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)  # Dark gray
	panel_style.set_corner_radius_all(10)  # Rounded corners
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.7, 0.2, 0.2)  # Reddish border
	panel_container.add_theme_stylebox_override("panel", panel_style)
	panel_container.add_theme_constant_override("margin_left", 40)
	panel_container.add_theme_constant_override("margin_right", 40)
	panel_container.add_theme_constant_override("margin_top", 40)
	panel_container.add_theme_constant_override("margin_bottom", 40)
	vbox.add_child(panel_container)
	
	# Create a VBoxContainer inside the panel for our content
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 30)
	panel_container.add_child(content_vbox)
	
	# Game over text
	var game_over_text = Label.new()
	game_over_text.text = "GAME OVER"
	game_over_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_text.add_theme_font_size_override("font_size", 64)
	game_over_text.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Reddish
	content_vbox.add_child(game_over_text)
	
	# Score text
	var score_text = Label.new()
	score_text.text = "Final Score: " + str(score)
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.add_theme_font_size_override("font_size", 36)
	content_vbox.add_child(score_text)
	
	# Buttons container
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.size_flags_horizontal = Control.SIZE_FILL
	content_vbox.add_child(button_container)
	
	# Restart button
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.size_flags_horizontal = Control.SIZE_FILL
	restart_button.custom_minimum_size = Vector2(300, 60)
	restart_button.connect("pressed", Callable(self, "on_restart_pressed"))
	button_container.add_child(restart_button)
	
	# Back to map button
	var map_button = Button.new()
	map_button.text = "Back to Map"
	map_button.size_flags_horizontal = Control.SIZE_FILL
	map_button.custom_minimum_size = Vector2(300, 60)
	map_button.connect("pressed", Callable(self, "on_back_to_map_pressed"))
	button_container.add_child(map_button)
	
	print("Game over overlay created successfully")

# Update these button handler functions
func on_restart_pressed():
	get_tree().paused = false
	if get_tree().root.has_node("GameOverOverlay"):
		get_tree().root.get_node("GameOverOverlay").queue_free()
	# Your existing restart logic here
	reset_game()

func on_back_to_map_pressed():
	get_tree().paused = false
	if get_tree().root.has_node("GameOverOverlay"):
		get_tree().root.get_node("GameOverOverlay").queue_free()
	# Change scene to the map scene
	get_tree().change_scene_to_file("res://map.gd")
	# Alternatively, if you have a specific function to handle this:
	# change_to_map_scene()
