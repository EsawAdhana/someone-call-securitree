extends Node2D

# Reference to the location name
@export var location_name = "Generic Location"
@export var inspection_panel_scene: PackedScene

# Book variables
var book_open = false
var current_page = 0
var total_pages = 3  # Total number of placeholder pages

# Variable to keep track of the inspection panel instance
var inspection_panel = null
var direct_spawner = null
var game_camera = null
var current_selected_character = null  # Track the currently selected character
var game_manager = null  # Reference to the game manager

# References to scroll textures
var closed_scroll_texture
var open_scroll_texture
var scroll_sprite

func _ready():
	print("LOCATION: Location template initializing...")
	
	# Set up the camera if it doesn't exist
	setup_camera()
	
	# Set up the game manager
	setup_game_manager()
	
	# Set up UI elements
	setup_ui_elements()
	
	# Set up the background to fill the screen
	var background = $Background
	if background:
		# Resize the background to fill the viewport
		var viewport_size = get_viewport_rect().size
		
		# Calculate scale to cover the viewport while maintaining aspect ratio
		var texture_size = background.texture.get_size()
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		var scale_factor = max(scale_x, scale_y)
		
		background.scale = Vector2(scale_factor, scale_factor)
		
		# Center the background
		background.position = viewport_size / 2
	
	# Initialize the direct spawner with a slight delay
	await get_tree().create_timer(0.2).timeout
	setup_direct_spawner()

func setup_camera():
	# Check if we already have a camera
	game_camera = get_node_or_null("GameCamera")
	
	if not game_camera:
		# Create a new camera
		game_camera = Camera2D.new()
		game_camera.name = "GameCamera"
		
		# Position it at the center of the viewport
		var viewport_size = get_viewport_rect().size
		game_camera.position = viewport_size / 2
		
		# Add it to the scene first
		add_child(game_camera)
		
		# Now make it current after it's in the scene tree
		game_camera.make_current()
		
		print("LOCATION: Created new game camera")

func setup_game_manager():
	# Check if we have a game manager in this scene
	game_manager = get_node_or_null("GameManager")
	
	if not game_manager:
		# Check if the game manager already exists in the root
		game_manager = get_node_or_null("/root/GameManager")
		
		if not game_manager:
			# Try to find the game manager in this scene
			game_manager = $GameManager
			if not game_manager:
				push_error("LOCATION: Game manager not found!")
			else:
				print("LOCATION: Using existing game manager in this scene")
		else:
			print("LOCATION: Using existing game manager from root")

func setup_ui_elements():
	# Set up the inspection panel
	setup_inspection_panel()
	
	# Set up the scroll button and book interface
	setup_scroll_button_and_book()
	
	# Set up the minimap button
	setup_minimap_button()

func setup_inspection_panel():
	print("LOCATION: Setting up inspection panel...")
	
	# First try to find if the inspection panel is already in the scene
	var ui_layer = get_node_or_null("UI")
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UI"
		ui_layer.layer = 10
		add_child(ui_layer)
		print("LOCATION: Created new UI layer")
	
	# Check for existing inspection panel in the UI layer
	inspection_panel = ui_layer.get_node_or_null("InspectionPanel")
	
	# There's a bug in Godot where the node might be named "UI#InspectionPanel"
	# Try to find it in the main scene if not in UI
	if not inspection_panel:
		var possible_panel = get_node_or_null("UI#InspectionPanel")
		if possible_panel:
			# Remove it from current parent and add it to UI with correct name
			possible_panel.get_parent().remove_child(possible_panel)
			possible_panel.name = "InspectionPanel"
			ui_layer.add_child(possible_panel)
			inspection_panel = possible_panel
			print("LOCATION: Fixed panel location from UI#InspectionPanel to UI/InspectionPanel")
	
	if inspection_panel:
		print("LOCATION: Found existing inspection panel at", inspection_panel.get_path())
	else:
		# Try to load the inspection panel scene if not specified in the Inspector
		if not inspection_panel_scene:
			inspection_panel_scene = load("res://scenes/inspection_panel.tscn")
			if not inspection_panel_scene:
				push_error("Failed to load inspection_panel.tscn. Please check the path.")
				return

		# Instantiate the inspection panel
		inspection_panel = inspection_panel_scene.instantiate()
		if not inspection_panel:
			push_error("Failed to instantiate inspection panel scene.")
			return

		# Make sure the name is correct
		inspection_panel.name = "InspectionPanel"
		
		# Add it to the UI layer
		ui_layer.add_child(inspection_panel)
		print("LOCATION: Inspection panel added to UI layer at path:", inspection_panel.get_path())
	
	# Hide it initially
	inspection_panel.visible = false
	
	# Connect the approve and reject signals from the inspection panel
	if inspection_panel.has_signal("character_approved"):
		if inspection_panel.character_approved.is_connected(_on_character_approved):
			inspection_panel.character_approved.disconnect(_on_character_approved)
		inspection_panel.character_approved.connect(_on_character_approved)
		print("LOCATION: character_approved signal connected")
	
	if inspection_panel.has_signal("character_rejected"):
		if inspection_panel.character_rejected.is_connected(_on_character_rejected):
			inspection_panel.character_rejected.disconnect(_on_character_rejected)
		inspection_panel.character_rejected.connect(_on_character_rejected)
		print("LOCATION: character_rejected signal connected")
		
	if inspection_panel.has_signal("exit_pressed"):
		if inspection_panel.exit_pressed.is_connected(_on_exit_pressed):
			inspection_panel.exit_pressed.disconnect(_on_exit_pressed)
		inspection_panel.exit_pressed.connect(_on_exit_pressed)
		print("LOCATION: exit_pressed signal connected")
		
	if inspection_panel.has_signal("remove_npc_pressed"):
		if inspection_panel.remove_npc_pressed.is_connected(_on_remove_npc_pressed):
			inspection_panel.remove_npc_pressed.disconnect(_on_remove_npc_pressed)
		inspection_panel.remove_npc_pressed.connect(_on_remove_npc_pressed)
		print("LOCATION: remove_npc_pressed signal connected")

func setup_scroll_button_and_book():
	print("LOCATION: Setting up scroll button and book interface...")
	
	# Get references to the scroll textures and sprite
	closed_scroll_texture = preload("res://assets/closed_scroll.png")
	open_scroll_texture = preload("res://assets/open_scroll.png")
	scroll_sprite = $CanvasLayer/Control/ScrollButton/ScrollSprite
	
	# Connect the scroll button pressed signal
	var scroll_button = $CanvasLayer/Control/ScrollButton
	if scroll_button:
		scroll_button.pressed.connect(_on_scroll_button_pressed)
		scroll_button.mouse_entered.connect(_on_scroll_button_mouse_entered)
		scroll_button.mouse_exited.connect(_on_scroll_button_mouse_exited)
		print("LOCATION: Scroll button connected")
	
	# Connect book interface buttons
	var close_button = $CanvasLayer/Control/BookInterface/CloseButton
	if close_button:
		close_button.pressed.connect(_on_book_close_button_pressed)
		print("LOCATION: Book close button connected")
	
	var next_button = $CanvasLayer/Control/BookInterface/NextButton
	if next_button:
		next_button.pressed.connect(_on_book_next_button_pressed)
		print("LOCATION: Book next button connected")
	
	var prev_button = $CanvasLayer/Control/BookInterface/PrevButton
	if prev_button:
		prev_button.pressed.connect(_on_book_prev_button_pressed)
		print("LOCATION: Book previous button connected")
	
	# Hide book interface initially
	var book_interface = $CanvasLayer/Control/BookInterface
	if book_interface:
		book_interface.visible = false
		print("LOCATION: Book interface hidden initially")

func _on_scroll_button_pressed():
	# Show the book interface
	book_open = true
	$CanvasLayer/Control/BookInterface.visible = true
	current_page = 0
	update_book_content()
	print("LOCATION: Book interface opened")

func _on_book_close_button_pressed():
	# Hide the book interface
	book_open = false
	$CanvasLayer/Control/BookInterface.visible = false
	print("LOCATION: Book interface closed")

func _on_book_next_button_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		update_book_content()
		print("LOCATION: Book page turned to next page")

func _on_book_prev_button_pressed():
	if current_page > 0:
		current_page -= 1
		update_book_content()
		print("LOCATION: Book page turned to previous page")

func update_book_content():
	var content = $CanvasLayer/Control/BookInterface/Content
	var page_label = $CanvasLayer/Control/BookInterface/PageLabel
	
	if not content or not page_label:
		push_error("LOCATION: Book content or page label not found")
		return
	
	# Update page number display
	page_label.text = "Page " + str(current_page + 1) + " of " + str(total_pages)
	
	# Set placeholder content based on current page
	match current_page:
		0:
			content.text = "Welcome to StanfordTree's Guide to Campus!\n\nThis book contains important information about Stanford University and the mysterious events unfolding on campus."
		1:
			content.text = "As you explore the campus, be on the lookout for clues and talk to various characters to uncover the mystery."
		2:
			content.text = "Remember, time is passing and events may occur at specific times and locations. Keep track of the time and visit locations accordingly."
		_:
			content.text = "Page content not available."

func setup_direct_spawner():
	print("LOCATION: Setting up direct spawner...")
	
	# Create the spawner directly in the scene, not in CanvasLayer
	# First, remove any existing DirectSpawner
	var existing_spawner = get_node_or_null("DirectSpawner")
	if existing_spawner:
		existing_spawner.queue_free()
	
	# Create a new direct spawner
	direct_spawner = Node2D.new()
	direct_spawner.name = "DirectSpawner"
	
	# Try to load the script
	var script = load("res://scripts/direct_spawner.gd")
	if not script:
		push_error("Cannot load direct_spawner.gd script")
		return
	
	direct_spawner.set_script(script)
	
	# Important: Add it DIRECTLY to the scene root, not inside CanvasLayer
	add_child(direct_spawner)
	print("LOCATION: Created new DirectSpawner node directly in scene")
	
	# Connect to the character_clicked signal
	if direct_spawner.character_clicked.is_connected(_on_character_clicked):
		direct_spawner.character_clicked.disconnect(_on_character_clicked)
	
	direct_spawner.character_clicked.connect(_on_character_clicked)
	print("LOCATION: Connected to DirectSpawner's character_clicked signal")
	
	# Load character scene if not already set
	if not direct_spawner.character_scene:
		var character_scene = load("res://scenes/character.tscn")
		if character_scene:
			direct_spawner.character_scene = character_scene
			print("LOCATION: Character scene loaded for DirectSpawner")
		else:
			push_error("Failed to load character scene!")
	
	# Start spawning
	direct_spawner.start_spawning()
	print("LOCATION: DirectSpawner started spawning characters")

# Move the camera to center on a character
func center_camera_on_character(character):
	if not game_camera:
		push_error("LOCATION: Cannot center camera, no camera found")
		return
	
	print("LOCATION: Centering camera on character:", character.variant_name)
	
	# Get the character's position
	var character_pos = character.global_position
	
	# Get viewport size
	var viewport_size = get_viewport_rect().size
	
	# Calculate the zoom factor and its effect on the viewable area
	var zoom_factor = 1.5  # Our target zoom
	var scaled_viewport = viewport_size / zoom_factor
	
	# Calculate the maximum allowed camera position to keep everything in view
	var max_x = viewport_size.x - (scaled_viewport.x / 2)
	var max_y = viewport_size.y - (scaled_viewport.y / 2)
	var min_x = scaled_viewport.x / 2
	var min_y = scaled_viewport.y / 2
	
	# Clamp the target position to keep the camera within bounds
	var target_pos = Vector2(
		clamp(character_pos.x, min_x, max_x),
		clamp(character_pos.y, min_y, max_y)
	)
	
	# Create a tween to smoothly move the camera and zoom
	var tween = create_tween()
	tween.tween_property(game_camera, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(game_camera, "zoom", Vector2(zoom_factor, zoom_factor), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# After centering, position the inspection panel to not overlap
	await tween.finished
	if inspection_panel and inspection_panel.has_method("position_panel_away_from_character"):
		inspection_panel.position_panel_away_from_character(character)

# Handle when a character is clicked
func _on_character_clicked(character):
	# If there was a previously selected character, resume its movement
	if current_selected_character and current_selected_character != character:
		current_selected_character.resume_walking()
	
	# Update the current selected character
	current_selected_character = character
	
	# When a character is clicked, center the camera on them
	center_camera_on_character(character)
	
	# Show the inspection panel
	print("LOCATION: Character clicked! Name: " + character.variant_name)
	
	if inspection_panel:
		print("LOCATION: Showing inspection panel")
		inspection_panel.show_character_info(character)
	else:
		push_error("LOCATION: Inspection panel is null, cannot show character info")

# Handle character approved
func _on_character_approved(character):
	print("LOCATION: Character approved:", character.variant_name)
	# Clear the current selected character
	current_selected_character = null
	# Reset camera position (character is still walking)
	reset_camera_position()
	
	# Advance time by 15 minutes
	advance_time(15)
	
	# If the game manager exists, notify it of the character approval
	if game_manager and game_manager.has_method("_on_character_approved"):
		game_manager._on_character_approved(character)

# Handle character rejected
func _on_character_rejected(character):
	print("LOCATION: Character rejected:", character.variant_name)
	# Clear the current selected character
	current_selected_character = null
	# Reset camera position (character is still walking)
	reset_camera_position()
	
	# Advance time by 15 minutes
	advance_time(15)
	
	# If the game manager exists, notify it of the character rejection
	if game_manager and game_manager.has_method("_on_character_rejected"):
		game_manager._on_character_rejected(character)

# Handle exit button pressed
func _on_exit_pressed():
	print("LOCATION: Exit button pressed")
	# Clear the current selected character
	current_selected_character = null
	# Reset camera position
	reset_camera_position()

# Handle remove NPC button pressed
func _on_remove_npc_pressed(character):
	print("LOCATION: Remove NPC button pressed for", character.variant_name)
	# Clear the current selected character
	current_selected_character = null
	# Reset camera position
	reset_camera_position()
	
	# Advance time by 15 minutes
	advance_time(15)

# Reset camera to the center of the viewport
func reset_camera_position():
	if not game_camera:
		return
		
	var viewport_size = get_viewport_rect().size
	var center_pos = viewport_size / 2
	
	var tween = create_tween()
	tween.tween_property(game_camera, "position", center_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(game_camera, "zoom", Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

# Handle clicking away from a character
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if the inspection panel is visible - if so, don't process background clicks
		if inspection_panel and inspection_panel.visible:
			# Don't process background clicks when the panel is open
			# This prevents the panel from closing immediately after opening
			print("LOCATION: Click detected while inspection panel is open, ignoring for background")
			return
			
		# Check if we clicked on the background (not on a character)
		var clicked_on_character = false
		if current_selected_character:
			# Get the mouse position in global coordinates
			var mouse_pos = get_global_mouse_position()
			# Check if we clicked on the current character
			var character_rect = Rect2(
				current_selected_character.global_position - Vector2(42.5, 70),  # Half of collision shape size
				Vector2(85, 140)  # Full collision shape size
			)
			clicked_on_character = character_rect.has_point(mouse_pos)
		
		# If we clicked away from the character, resume its movement
		if current_selected_character and not clicked_on_character:
			print("LOCATION: Clicked away from character, will resume walking")
			# Small delay before resuming walking to prevent input conflicts
			await get_tree().create_timer(0.1).timeout
			
			print("LOCATION: Clicked away from character, resuming walking")
			current_selected_character.resume_walking()
			current_selected_character = null
			# Hide the inspection panel
			if inspection_panel:
				inspection_panel.hide_panel()
			# Reset camera
			reset_camera_position()
	
	# Check for ESC key to return to map
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("LOCATION: ESC key pressed, returning to map")
		get_tree().change_scene_to_file("res://scenes/main_map.tscn")

# Handle mouse enter event for scroll button
func _on_scroll_button_mouse_entered():
	if scroll_sprite and open_scroll_texture:
		scroll_sprite.texture = open_scroll_texture
		print("LOCATION: Mouse entered scroll button, showing open scroll")

# Handle mouse exit event for scroll button
func _on_scroll_button_mouse_exited():
	if scroll_sprite and closed_scroll_texture:
		scroll_sprite.texture = closed_scroll_texture
		print("LOCATION: Mouse exited scroll button, showing closed scroll")

# Advances time through the game manager
func advance_time(added_minutes):
	# If the game manager exists, forward time updates to it
	if game_manager and game_manager.has_method("advance_time"):
		game_manager.advance_time(added_minutes)

func setup_minimap_button():
	print("LOCATION: Setting up minimap button...")
	
	# Connect the minimap button pressed signal
	var minimap_button = $CanvasLayer/Control/MinimapButton
	if minimap_button:
		minimap_button.pressed.connect(_on_minimap_button_pressed)
		
		# Add a border to the minimap with a distinct style
		var minimap_border = minimap_button.get_node("MinimapBorder")
		if minimap_border:
			var stylebox = StyleBoxFlat.new()
			stylebox.border_width_left = 4
			stylebox.border_width_top = 4
			stylebox.border_width_right = 4
			stylebox.border_width_bottom = 4
			stylebox.border_color = Color(0.8, 0.7, 0.3, 0.9) # Gold color for better visibility
			stylebox.corner_radius_top_left = 10
			stylebox.corner_radius_top_right = 10
			stylebox.corner_radius_bottom_right = 10
			stylebox.corner_radius_bottom_left = 10
			stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.15) # Very subtle dark tint for background
			stylebox.content_margin_left = 10
			stylebox.content_margin_top = 10
			stylebox.content_margin_right = 10
			stylebox.content_margin_bottom = 10
			minimap_border.add_theme_stylebox_override("panel", stylebox)
		
		print("LOCATION: Minimap button connected")

# Handle minimap button pressed
func _on_minimap_button_pressed():
	print("LOCATION: Minimap button pressed, going to main map")
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")
