extends Node2D

# Reference to the location name
@export var location_name = "Generic Location"
@export var inspection_panel_scene: PackedScene

# Book variables
var book_open = false
var current_page = 0
var total_pages = 3 # Total number of placeholder pages

# Variable to keep track of the inspection panel instance
var inspection_panel = null
var direct_spawner = null
var game_camera = null
var current_selected_character = null # Track the currently selected character
var game_manager = null # Reference to the game manager
var global_character_manager = null # Reference to the global character manager

# References to scroll textures
var closed_scroll_texture
var open_scroll_texture
var scroll_sprite

func _ready():
	print("LOCATION: Ready called for ", self)
	print("LOCATION: Location template initializing...")
	
	# Set up the camera if it doesn't exist
	setup_camera()
	
	# Set up the game manager
	setup_game_manager()
	
	# Set up the global character manager
	setup_global_character_manager()
	
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
	
	# Restore any existing characters for this location
	restore_location_characters()

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

func setup_global_character_manager():
	# Try to find the global character manager in the scene tree
	global_character_manager = get_node("/root/GlobalCharacterManager")
	
	# If it doesn't exist, create it
	if not global_character_manager:
		global_character_manager = Node.new()
		global_character_manager.set_script(load("res://scripts/global_character_manager.gd"))
		global_character_manager.name = "GlobalCharacterManager"
		get_tree().get_root().add_child(global_character_manager)
		print("LOCATION: Created new GlobalCharacterManager")

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
	
	if not inspection_panel:
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
	else:
		print("LOCATION: Found existing inspection panel at", inspection_panel.get_path())
	
	# Hide it initially
	inspection_panel.visible = false
	
	# Connect signals
	if inspection_panel:
		# Disconnect existing connections if any
		if inspection_panel.character_approved.is_connected(_on_character_approved):
			inspection_panel.character_approved.disconnect(_on_character_approved)
		if inspection_panel.character_rejected.is_connected(_on_character_rejected):
			inspection_panel.character_rejected.disconnect(_on_character_rejected)
		if inspection_panel.exit_pressed.is_connected(_on_exit_pressed):
			inspection_panel.exit_pressed.disconnect(_on_exit_pressed)
		if inspection_panel.remove_npc_pressed.is_connected(_on_remove_npc_pressed):
			inspection_panel.remove_npc_pressed.disconnect(_on_remove_npc_pressed)
		if inspection_panel.camera_reset_requested.is_connected(reset_camera_position):
			inspection_panel.camera_reset_requested.disconnect(reset_camera_position)
		
		# Connect signals
		inspection_panel.character_approved.connect(_on_character_approved)
		inspection_panel.character_rejected.connect(_on_character_rejected)
		inspection_panel.exit_pressed.connect(_on_exit_pressed)
		inspection_panel.remove_npc_pressed.connect(_on_remove_npc_pressed)
		inspection_panel.camera_reset_requested.connect(reset_camera_position)
		print("LOCATION: Connected all inspection panel signals")
	else:
		push_error("LOCATION: Failed to create inspection panel!")

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
	print("LOCATION: Scroll button pressed")
	if not book_open:
		AudioManager.play_pop()
		show_book()
	else:
		hide_book()

func _on_book_close_button_pressed():
	# Play click sound
	AudioManager.play_ui_click()
	# Hide the book interface
	book_open = false
	$CanvasLayer/Control/BookInterface.visible = false
	print("LOCATION: Book interface closed")

func _on_book_next_button_pressed():
	AudioManager.play_ui_click()
	if current_page < total_pages - 1:
		current_page += 1
		update_book_content()

func _on_book_prev_button_pressed():
	AudioManager.play_ui_click()
	if current_page > 0:
		current_page -= 1
		update_book_content()

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
	var zoom_factor = 1.5 # Our target zoom
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
	print("LOCATION: Character clicked:", character.variant_name)
	# Play click sound
	AudioManager.play_npc_click()
	
	# Pause the character's movement
	character.is_walking = false
	
	# Store the current selected character
	current_selected_character = character
	
	# Center camera on character
	center_camera_on_character(character)
	
	# Show inspection panel
	if inspection_panel:
		inspection_panel.show_character_info(character)

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
	save_characters_to_global_manager()

# Handle remove NPC button pressed
func _on_remove_npc_pressed(character):
	print("LOCATION: Remove NPC button pressed for", character.variant_name)
	# Clear the current selected character
	current_selected_character = null
	# Reset camera position
	reset_camera_position()
	
	# Remove the character from the global manager
	if global_character_manager:
		global_character_manager.remove_character(location_name, character)
	
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
				current_selected_character.global_position - Vector2(42.5, 70), # Half of collision shape size
				Vector2(85, 140) # Full collision shape size
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
		AudioManager.play_pop()
		save_characters_to_global_manager()
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
	AudioManager.play_pop()
	save_characters_to_global_manager()
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")

# Restore characters for this location
func restore_location_characters():
	if not global_character_manager:
		return

	var now = Time.get_unix_time_from_system()
	var characters_data = global_character_manager.get_characters_data(location_name)
	
	# Create a dictionary to track restored characters
	var restored_characters = {}
	
	for data in characters_data:
		print("Restoring character: ", data)
		var character_scene = load("res://scenes/character.tscn")
		var character = character_scene.instantiate()
		
		# Store the character reference
		var character_id = character.get_instance_id()
		restored_characters[character_id] = character
		
		# Simulate movement while away
		var pos = data["position"]
		var next_pos = data.get("next_position", pos)
		var dir = data.get("walk_direction", Vector2.ZERO)
		var speed = data.get("walking_speed", 50.0)
		var last_time = data.get("last_update_time", now)
		var dt = max(0, now - last_time)
		
		if data.get("is_walking", true):
			# Use interpolation between last position and next position for smoother movement
			var interpolation = min(1.0, dt * speed / max(pos.distance_to(next_pos), 0.001))
			pos = pos.lerp(next_pos, interpolation)
			
			# Calculate future position based on direction and time
			pos += dir * speed * dt
		
		# Set basic properties
		character.global_position = pos
		character.character_type = data["character_type"]
		character.variant_name = data["variant_name"]
		character.has_id = data["has_id"]
		character.valid_major = data["valid_major"]
		character.target_position = data.get("target_position", character.global_position)
		character.is_walking = data.get("is_walking", true)
		character.walk_direction = dir
		character.walking_speed = speed
		character.velocity = data.get("velocity", Vector2.ZERO)
		character.just_spawned = data.get("just_spawned", false)
		character.initial_position = data.get("initial_position", pos)
		
		# Set visual properties
		character.modulate = data.get("modulate", Color(1, 1, 1, 1))
		character.scale = data.get("scale", Vector2(1, 1))
		
		# Add to scene
		add_child(character)
		character.show()
		character.visible = true
		
		# Set up sprite properties
		if character.has_node("AnimatedSprite2D"):
			var sprite = character.animated_sprite
			if data.has("sprite_path") and data["sprite_path"] != "":
				var frames = load(data["sprite_path"])
				if frames:
					sprite.sprite_frames = frames
			
			# Restore sprite state
			if data.has("current_animation"):
				sprite.play(data["current_animation"])
				if data.has("sprite_frame"):
					sprite.frame = data["sprite_frame"]
			
			# Restore sprite orientation
			sprite.flip_h = data.get("sprite_flip_h", false)
		
		print("Added character to scene: ", character, " parent: ", character.get_parent())
	
	# Add a delay before resuming walking for all characters
	await get_tree().create_timer(0.5).timeout
	
	# Now resume walking for all valid characters
	for character_id in restored_characters:
		var character = restored_characters[character_id]
		if is_instance_valid(character) and character.has_method("resume_walking") and character.is_walking:
			# Double check that the character is still valid and in the scene tree
			if is_instance_valid(character) and character.is_inside_tree():
				character.resume_walking()
	
	for c in get_children():
		print("Child of location after restore: ", c)

func save_characters_to_global_manager():
	if global_character_manager:
		global_character_manager.clear_location(location_name)
		var now = Time.get_unix_time_from_system()
		for character in get_tree().get_nodes_in_group("characters"):
			print("Saving character: ", character)
			var anim_name = ""
			var sprite_path = ""
			var sprite_flip_h = false
			var sprite_frame = 0
			
			if character.has_node("AnimatedSprite2D"):
				var sprite = character.animated_sprite
				anim_name = sprite.animation
				sprite_flip_h = sprite.flip_h
				sprite_frame = sprite.frame
				if sprite.sprite_frames:
					sprite_path = sprite.sprite_frames.resource_path
			
			# Calculate next position based on current movement
			var next_pos = character.global_position
			if character.is_walking:
				# Simulate a small time step to get the next position
				next_pos += character.walk_direction * character.walking_speed * 0.016 # One frame at 60fps
			
			var data = {
				"position": character.global_position,
				"next_position": next_pos, # Store next position for smoother transitions
				"character_type": character.character_type,
				"variant_name": character.variant_name,
				"has_id": character.has_id,
				"valid_major": character.valid_major,
				"target_position": character.target_position,
				"is_walking": character.is_walking,
				"walk_direction": character.walk_direction,
				"walking_speed": character.walking_speed,
				"velocity": character.velocity,
				"just_spawned": character.just_spawned,
				"current_animation": anim_name,
				"sprite_path": sprite_path,
				"sprite_flip_h": sprite_flip_h,
				"sprite_frame": sprite_frame,
				"last_update_time": now,
				"modulate": character.modulate,
				"scale": character.scale,
				"initial_position": character.initial_position
			}
			global_character_manager.add_character_data(location_name, data)
			character.queue_free()

func show_book():
	# Show the book interface
	book_open = true
	$CanvasLayer/Control/BookInterface.visible = true
	current_page = 0
	update_book_content()
	print("LOCATION: Book interface opened")

func hide_book():
	# Hide the book interface
	book_open = false
	$CanvasLayer/Control/BookInterface.visible = false
	print("LOCATION: Book interface closed")
