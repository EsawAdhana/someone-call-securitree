extends CharacterBody2D

# Character types and properties
@export var character_type: int = 0 # 0 = Stanford, 1 = Berkeley
@export var walking_speed: float = 200.0

# List of male names for sprite selection
const MALE_NAMES = ["Alex", "Daniel", "Kelvin", "Ryan", "Sam"]

# Variant properties (for gameplay)
var variant_name: String = "Unknown"
var has_id: bool = true
var valid_major: bool = true
var l1_id: String = "" # Store the L1ID for the character
var has_been_interacted: bool = false
var has_been_rejected: bool = false
var was_rejected: bool = false

# Walking and destinations
var target_position: Vector2 = Vector2.ZERO
var is_walking: bool = false
var walk_direction: Vector2 = Vector2.ZERO
var just_spawned: bool = true

# Animation references
@onready var animated_sprite = $AnimatedSprite2D
@onready var exclamation_mark = $ExclamationMark
@onready var name_label = $NameLabel

# Signals
signal character_clicked(character)
signal character_exited(character)

# Debug info
var initial_position: Vector2
var debug_frame_count: int = 0

func _ready():
	# Set up walking
	initial_position = global_position
	just_spawned = true
	
	print("CHARACTER DEBUG: Character spawned at:", global_position)
	print("CHARACTER DEBUG: Character name:", variant_name)
	print("CHARACTER DEBUG: Character type:", "Stanford" if character_type == 0 else "Berkeley")
	
	# Initialize name label if available (will be set by spawner)
	if name_label:
		name_label.text = variant_name  # Default to variant_name, will be overridden by spawner
	
	# Always use the singleton game manager
	var game_manager = get_node("/root/GameManager")
	
	# Register Berkeley character with game manager
	if character_type == 1: # Berkeley student
		if game_manager and game_manager.has_method("register_berkeley_person"):
			game_manager.register_berkeley_person()
			print("CHARACTER DEBUG: Registered Berkeley person with singleton game manager")
		else:
			push_error("CHARACTER DEBUG: Could not find singleton game manager for Berkeley registration")
	
	# Register this character with the game manager for total count tracking
	if game_manager and game_manager.has_method("register_character"):
		game_manager.register_character()
		print("CHARACTER DEBUG: Registered character with singleton game manager for total count")
	else:
		push_error("CHARACTER DEBUG: Could not find singleton game manager for character registration")
	
	# Store initial position for debugging
	initial_position = global_position
	
	# Set the correct sprite variant based on name
	if animated_sprite:
		set_sprite_variant()
	
	# Add to characters group for tracking
	add_to_group("characters")
	
	# CRITICAL: Make sure input detection works
	input_pickable = true
	print("CHARACTER DEBUG: input_pickable set to " + str(input_pickable))
	
	# Connect input signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	# Connect to inspection panel signals - using more robust method
	await get_tree().create_timer(0.1).timeout # Small delay to ensure scene is ready
	var inspection_panel = find_inspection_panel()
	if inspection_panel:
		inspection_panel.exit_pressed.connect(_on_inspection_exit.bind())
		inspection_panel.character_rejected.connect(_on_character_rejected.bind())
		inspection_panel.character_approved.connect(_on_character_approved.bind())
		print("CHARACTER DEBUG: Connected to inspection panel signals")
	else:
		push_warning("CHARACTER DEBUG: Could not find InspectionPanel")
	
	print("CHARACTER DEBUG: All input signals connected")
	
	# Start animation
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play("walk")
		print("CHARACTER DEBUG: Animation started")
	else:
		print("CHARACTER DEBUG: No AnimatedSprite2D or sprite_frames found")
	
	# Show exclamation mark for uninteracted characters
	if exclamation_mark:
		exclamation_mark.visible = true
		
		# Set exclamation mark color/marker based on easy mode setting for all characters
		update_exclamation_mark_color()
	
	# Connect to easy mode changes
	if game_manager and game_manager.has_signal("easy_mode_changed"):
		game_manager.easy_mode_changed.connect(_on_easy_mode_changed)
	
	# Start walking after a small delay
	start_walking()

func set_sprite_variant():
	# Get character data to determine name for sprite selection
	var char_data = get_meta("character_data", {})
	var name_for_sprite = char_data.get("name", variant_name)  # Use the actual name (from ID) for sprite selection
	
	# Get the first name from the name
	var first_name = name_for_sprite.split(" ")[0]
	
	# Check if it's a male name
	if first_name in MALE_NAMES:
		# Randomly choose between stanford1 and stanford2
		var variant = randi() % 2 + 1 # This gives us 1 or 2
		print("CHARACTER DEBUG: Male character %s using stanford%d sprite" % [first_name, variant])
		var sprite_frames = load("res://assets/characters/stanford%d.tres" % variant)
		if sprite_frames:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.play("walk")
		else:
			print("CHARACTER DEBUG: Failed to load sprite frames for stanford%d" % variant)
	else:
		# Female character - always use stanford3
		print("CHARACTER DEBUG: Female character %s using stanford3 sprite" % first_name)
		var sprite_frames = load("res://assets/characters/stanford3.tres")
		if sprite_frames:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.play("walk")
		else:
			print("CHARACTER DEBUG: Failed to load sprite frames for stanford3")

func set_blue_exclamation_mark():
	# Change exclamation mark color to blue for Berkeley students (testing)
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		# Change both top and bottom parts to blue
		if vbox.has_node("ExclamationTop"):
			var top_panel = vbox.get_node("ExclamationTop")
			var top_style = top_panel.get_theme_stylebox("panel").duplicate()
			top_style.bg_color = Color(0, 0.5, 1, 1)  # Blue color
			top_panel.add_theme_stylebox_override("panel", top_style)
		
		if vbox.has_node("ExclamationBottom"):
			var bottom_panel = vbox.get_node("ExclamationBottom")
			var bottom_style = bottom_panel.get_theme_stylebox("panel").duplicate()
			bottom_style.bg_color = Color(0, 0.5, 1, 1)  # Blue color
			bottom_panel.add_theme_stylebox_override("panel", bottom_style)

func set_red_exclamation_mark():
	# Change exclamation mark color to red (default color)
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		# Reset exclamation mark position to original
		exclamation_mark.position.y = -100  # Reset to original position
		
		# Hide any letter label that might exist
		hide_letter_label()
		
		# Show the original exclamation mark panels
		show_exclamation_panels()
		
		# Change both top and bottom parts to red
		if vbox.has_node("ExclamationTop"):
			var top_panel = vbox.get_node("ExclamationTop")
			var top_style = top_panel.get_theme_stylebox("panel").duplicate()
			top_style.bg_color = Color(1, 0, 0, 1)  # Red color
			top_panel.add_theme_stylebox_override("panel", top_style)
		
		if vbox.has_node("ExclamationBottom"):
			var bottom_panel = vbox.get_node("ExclamationBottom")
			var bottom_style = bottom_panel.get_theme_stylebox("panel").duplicate()
			bottom_style.bg_color = Color(1, 0, 0, 1)  # Red color
			bottom_panel.add_theme_stylebox_override("panel", bottom_style)

func set_stanford_letter_marker():
	# Set a big red "S" for Stanford students in easy mode
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		# Hide the original exclamation mark panels
		hide_exclamation_panels()
		
		# Create or get the letter label
		var letter_label = get_or_create_letter_label()
		letter_label.text = "S"
		letter_label.modulate = Color(1, 0, 0, 1)  # Red color
		letter_label.visible = true

func set_berkeley_letter_marker():
	# Set a big blue "B" for Berkeley students in easy mode
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		# Hide the original exclamation mark panels
		hide_exclamation_panels()
		
		# Create or get the letter label
		var letter_label = get_or_create_letter_label()
		letter_label.text = "B"
		letter_label.modulate = Color(0, 0.5, 1, 1)  # Blue color
		letter_label.visible = true

func get_or_create_letter_label() -> Label:
	# Get or create a letter label for easy mode markers
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		# Check if letter label already exists
		var letter_label = vbox.get_node_or_null("LetterLabel")
		if not letter_label:
			# Create a new letter label
			letter_label = Label.new()
			letter_label.name = "LetterLabel"
			letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			letter_label.add_theme_font_size_override("font_size", 48)  # Increased from 32 to 48
			letter_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			letter_label.add_theme_constant_override("shadow_offset_x", 3)  # Increased shadow for larger text
			letter_label.add_theme_constant_override("shadow_offset_y", 3)
			letter_label.custom_minimum_size = Vector2(50, 50)  # Increased from 40x40 to 50x50
			vbox.add_child(letter_label)
			
			# Move the entire exclamation mark higher when using letters
			exclamation_mark.position.y = -130  # Moved up from -100 to -130
		
		return letter_label
	return null

func hide_exclamation_panels():
	# Hide the original exclamation mark panels
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		if vbox.has_node("ExclamationTop"):
			vbox.get_node("ExclamationTop").visible = false
		
		if vbox.has_node("ExclamationBottom"):
			vbox.get_node("ExclamationBottom").visible = false

func show_exclamation_panels():
	# Show the original exclamation mark panels
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		
		if vbox.has_node("ExclamationTop"):
			vbox.get_node("ExclamationTop").visible = true
		
		if vbox.has_node("ExclamationBottom"):
			vbox.get_node("ExclamationBottom").visible = true

func hide_letter_label():
	# Hide the letter label
	if exclamation_mark and exclamation_mark.has_node("VBoxContainer"):
		var vbox = exclamation_mark.get_node("VBoxContainer")
		var letter_label = vbox.get_node_or_null("LetterLabel")
		if letter_label:
			letter_label.visible = false

# Override _input to handle clicks - this is a backup in case the input_event signal isn't working
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if inspection panel is open - if so, ignore input
		var inspection_panel = find_inspection_panel()
		if inspection_panel and inspection_panel.visible:
			return
		
		# Check if the click is within our collision shape
		var global_mouse_pos = get_global_mouse_position()
		var shape = $CollisionShape2D
		
		if shape:
			var shape_size = shape.shape.size
			var shape_pos = global_position + shape.position
			
			# Simple bounding box check
			if global_mouse_pos.x >= shape_pos.x - shape_size.x / 2 and \
			   global_mouse_pos.x <= shape_pos.x + shape_size.x / 2 and \
			   global_mouse_pos.y >= shape_pos.y - shape_size.y / 2 and \
			   global_mouse_pos.y <= shape_pos.y + shape_size.y / 2:
				print("CHARACTER DEBUG: Direct click detected!")
				_handle_click()
				get_viewport().set_input_as_handled()

func _physics_process(delta):
	# Keep original movement logic but with minor optimizations
	debug_frame_count += 1
	
	if is_walking:
		# Set velocity based on direction and speed
		velocity = walk_direction * walking_speed
		move_and_slide()
		
		# Get viewport boundaries
		var viewport_rect = get_viewport_rect()
		var viewport_size = viewport_rect.size
		var margin = 50 # Keep characters away from the edges
		
		# Check if character hits viewport boundaries and bounce or choose new target
		var should_change_target = false
		if global_position.x <= margin or global_position.x >= viewport_size.x - margin:
			if randf() < 0.5: # 50% chance to bounce, 50% to choose new target
				walk_direction.x *= -1 # Bounce
				face_walk_direction()
			else:
				should_change_target = true
		
		if global_position.y <= margin or global_position.y >= viewport_size.y - margin:
			if randf() < 0.5: # 50% chance to bounce, 50% to choose new target
				walk_direction.y *= -1 # Bounce
				face_walk_direction()
			else:
				should_change_target = true
		
		# Keep character within bounds
		global_position.x = clamp(global_position.x, margin, viewport_size.x - margin)
		global_position.y = clamp(global_position.y, margin, viewport_size.y - margin)
		
		# Check if character reached destination or should change target
		if should_change_target or global_position.distance_to(target_position) < 10:
			choose_new_target()
		
		# Clear the just_spawned flag after moving a bit
		if just_spawned and global_position.distance_to(initial_position) > 50:
			just_spawned = false
			print("CHARACTER DEBUG: No longer just spawned")

# Input handling - CRITICAL for character interaction
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if inspection panel is open - if so, ignore input
		var inspection_panel = find_inspection_panel()
		if inspection_panel and inspection_panel.visible:
			return
		
		print("CHARACTER DEBUG: Input event - click detected!")
		_handle_click()
		get_viewport().set_input_as_handled()

# Centralized click handling
func _handle_click():
	print("CHARACTER DEBUG: Handling click on character: " + variant_name)
	# Play UI click sound
	AudioManager.play_ui_click()
	
	# Stop character and emit signal
	is_walking = false
	if animated_sprite:
		animated_sprite.stop()
		animated_sprite.frame = 0 # Reset to first frame
		print("CHARACTER DEBUG: Animation stopped")
	
	# Mark as interacted and hide exclamation mark only after a decision is made
	# Removed the automatic processing here - only happens on Accept/Reject
	
	emit_signal("character_clicked", self)
	print("CHARACTER DEBUG: character_clicked signal emitted")
	
	# Visual feedback
	modulate = Color(1.5, 1.5, 1.5) # Bright highlight when clicked
	# Reset modulate after a short time
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

# Visual feedback for mouse hover
func _on_mouse_entered():
	# Check if inspection panel is open - if so, ignore hover
	var inspection_panel = find_inspection_panel()
	if inspection_panel and inspection_panel.visible:
		return
	
	print("CHARACTER DEBUG: Mouse entered")
	modulate = Color(1.2, 1.2, 1.2) # Slight highlight

func _on_mouse_exited():
	# Check if inspection panel is open - if so, ignore hover
	var inspection_panel = find_inspection_panel()
	if inspection_panel and inspection_panel.visible:
		return
	
	print("CHARACTER DEBUG: Mouse exited")
	modulate = Color(1, 1, 1) # Normal color

# Movement functions
func start_walking():
	print("CHARACTER DEBUG: Starting to walk")
	is_walking = true
	choose_new_target()

func face_walk_direction():
	# Flip sprite based on walk direction
	if animated_sprite:
		if walk_direction.x < 0:
			animated_sprite.flip_h = true
		elif walk_direction.x > 0:
			animated_sprite.flip_h = false

# Visual animations
func disappear():
	print("CHARACTER DEBUG: Disappearing character:", variant_name)
	
	# Immediately stop all movement
	is_walking = false
	velocity = Vector2.ZERO
	
	if animated_sprite:
		animated_sprite.pause()
		print("CHARACTER DEBUG: Paused animation")
	
	# Force collision to disable (prevents further interaction)
	$CollisionShape2D.set_deferred("disabled", true)
	print("CHARACTER DEBUG: Disabled collision")
	
	# Play disappear animation with completion callback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.5)
	
	# Make sure to free the character when the animation completes (back to original behavior)
	tween.tween_callback(func():
		print("CHARACTER DEBUG: Tween complete, freeing character:", variant_name)
		queue_free()
	)
	
	# In case tween doesn't work for some reason, force free after a timeout
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		print("CHARACTER DEBUG: Backup timeout reached, forcing free")
		queue_free()

func continue_walking():
	print("CHARACTER DEBUG: Continuing to walk")
	# Resume walking if the character was stopped (e.g., after inspection)
	is_walking = true
	walk_direction = (target_position - global_position).normalized()
	face_walk_direction()

# Resume walking and animation
func resume_walking():
	print("CHARACTER DEBUG: Resuming walking for: " + variant_name)
	# Force is_walking to true
	is_walking = true
	
	# Ensure animation is playing
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play("walk")
		print("CHARACTER DEBUG: Animation restarted with walk animation")
	
	# Choose a new target and direction
	choose_new_target()
	print("CHARACTER DEBUG: New walking direction: " + str(walk_direction))

func choose_new_target():
	var viewport_size = get_viewport_rect().size
	var margin = 50
	
	# Pick a new random target within the viewport
	target_position = Vector2(
		randf_range(margin, viewport_size.x - margin),
		randf_range(margin, viewport_size.y - margin)
	)
	walk_direction = (target_position - global_position).normalized()
	face_walk_direction()

# Handle inspection panel exit
func _on_inspection_exit(character):
	if character == self:
		print("CHARACTER DEBUG: Handling inspection exit for: " + variant_name)
		# No need for additional logic here since resume_walking is called directly

# Helper function to find the InspectionPanel
func find_inspection_panel():
	# Try different possible paths, starting with the most likely
	var paths = [
		"../../../UI/InspectionPanel", # Relative to character in LocationTemplate
		"/root/LocationTemplate/UI/InspectionPanel", # Absolute path
		"../../UI/InspectionPanel", # Legacy path
		"/root/MainMap/UI/InspectionPanel", # Alternative path
		"/root/Main/UI/InspectionPanel" # Alternative path
	]
	
	for path in paths:
		var panel = get_node_or_null(path)
		if panel:
			print("CHARACTER DEBUG: Found InspectionPanel at path: ", path)
			return panel
	
	# If not found in predefined paths, search the scene tree
	print("CHARACTER DEBUG: InspectionPanel not found in predefined paths, searching scene tree...")
	var root = get_tree().root
	return find_inspection_panel_recursive(root)

# Recursive helper to find InspectionPanel anywhere in the scene tree
func find_inspection_panel_recursive(node: Node) -> Node:
	if node.name == "InspectionPanel":
		return node
	
	for child in node.get_children():
		var result = find_inspection_panel_recursive(child)
		if result:
			return result
	
	return null

func _on_character_rejected(character):
	if character == self:
		print("CHARACTER DEBUG: Starting rejection process for:", variant_name)
		
		# Mark as processed when rejected
		if not has_been_interacted:
			has_been_interacted = true
			# Hide exclamation mark when actually processed
			if exclamation_mark:
				exclamation_mark.visible = false
			
			# Notify game manager that this character has been processed
			var game_manager = get_node("/root/GameManager")
			if game_manager and game_manager.has_method("increment_interacted_characters"):
				game_manager.increment_interacted_characters()
				print("CHARACTER DEBUG: Notified game manager of character processing (rejected)")
			
			# Removed duplicate call - location template handles this through signals
		
		has_been_rejected = true
		was_rejected = true
		
		# Add a small delay to ensure GameManager processes the rejection first
		await get_tree().create_timer(0.1).timeout
		print("CHARACTER DEBUG: About to disappear after delay:", variant_name)
		
		# No morale decrease here - handled by game_manager
		disappear()

func _on_character_approved(character):
	if character == self:
		print("CHARACTER DEBUG: Starting approval process for:", variant_name)
		
		# Mark as processed when approved
		if not has_been_interacted:
			has_been_interacted = true
			# Hide exclamation mark when actually processed
			if exclamation_mark:
				exclamation_mark.visible = false
			
			# Notify game manager that this character has been processed
			var game_manager = get_node("/root/GameManager")
			if game_manager and game_manager.has_method("increment_interacted_characters"):
				game_manager.increment_interacted_characters()
				print("CHARACTER DEBUG: Notified game manager of character processing (approved)")
			
			# Removed duplicate call - location template handles this through signals
		
		print("CHARACTER DEBUG: Approved character will resume walking:", variant_name)
		# Character approved - just resume walking, no disappearing
		resume_walking()

func update_exclamation_mark_color():
	"""Update exclamation mark color based on character type and easy mode"""
	var game_manager = get_node("/root/GameManager")
	
	if game_manager and game_manager.is_easy_mode_enabled():
		# Easy mode: Use letter markers for both Stanford and Berkeley
		if character_type == 1:  # Berkeley student
			set_berkeley_letter_marker()
			print("CHARACTER DEBUG: Set blue 'B' marker for Berkeley student (Easy Mode)")
		else:  # Stanford student
			set_stanford_letter_marker()
			print("CHARACTER DEBUG: Set red 'S' marker for Stanford student (Easy Mode)")
	else:
		# Normal mode: All students get red exclamation marks
		set_red_exclamation_mark()
		if character_type == 1:
			print("CHARACTER DEBUG: Set red exclamation mark for Berkeley student (Normal Mode)")
		else:
			print("CHARACTER DEBUG: Set red exclamation mark for Stanford student (Normal Mode)")

func _on_easy_mode_changed(enabled: bool):
	"""Called when easy mode setting changes"""
	# Update all characters since easy mode now affects both Stanford and Berkeley
	update_exclamation_mark_color()
