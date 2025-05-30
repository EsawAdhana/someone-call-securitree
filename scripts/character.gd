extends CharacterBody2D

# Character types and properties
@export var character_type: int = 0  # 0 = Stanford, 1 = Berkeley
@export var walking_speed: float = 200.0

# Variant properties (for gameplay)
var variant_name: String = "Unknown"
var has_id: bool = true
var valid_major: bool = true

# Walking and destinations
var target_position: Vector2 = Vector2.ZERO
var is_walking: bool = false
var walk_direction: Vector2 = Vector2.ZERO
var just_spawned: bool = true

# Animation references
@onready var animated_sprite = $AnimatedSprite2D

# Signals
signal character_clicked(character)
signal character_exited(character)

# Debug info
var initial_position: Vector2
var debug_frame_count: int = 0

func _ready():
	# Store initial position for debugging
	initial_position = global_position
	
	# Add to characters group for tracking
	add_to_group("characters")
	
	# CRITICAL: Make sure input detection works
	input_pickable = true
	print("CHARACTER DEBUG: input_pickable set to " + str(input_pickable))
	
	# Connect input signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	print("CHARACTER DEBUG: All input signals connected")
	
	# Start animation
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play("walk")
		print("CHARACTER DEBUG: Animation started")
	else:
		print("CHARACTER DEBUG: No AnimatedSprite2D or sprite_frames found")
	
	# Start walking after a small delay
	await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
	start_walking()

# Override _input to handle clicks - this is a backup in case the input_event signal isn't working
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if the click is within our collision shape
		var global_mouse_pos = get_global_mouse_position()
		var shape = $CollisionShape2D
		
		if shape:
			var shape_size = shape.shape.size
			var shape_pos = global_position + shape.position
			
			# Simple bounding box check
			if global_mouse_pos.x >= shape_pos.x - shape_size.x/2 and \
			   global_mouse_pos.x <= shape_pos.x + shape_size.x/2 and \
			   global_mouse_pos.y >= shape_pos.y - shape_size.y/2 and \
			   global_mouse_pos.y <= shape_pos.y + shape_size.y/2:
				print("CHARACTER DEBUG: Direct click detected!")
				_handle_click()
				get_viewport().set_input_as_handled()

func _physics_process(delta):
	debug_frame_count += 1
	
	if is_walking:
		# Set velocity based on direction and speed
		velocity = walk_direction * walking_speed
		move_and_slide()
		
		# Get viewport boundaries
		var viewport_rect = get_viewport_rect()
		var viewport_size = viewport_rect.size
		var margin = 50  # Keep characters away from the edges
		
		# Check if character hits viewport boundaries and bounce or choose new target
		var should_change_target = false
		if global_position.x <= margin or global_position.x >= viewport_size.x - margin:
			if randf() < 0.5:  # 50% chance to bounce, 50% to choose new target
				walk_direction.x *= -1  # Bounce
				face_walk_direction()
			else:
				should_change_target = true
		
		if global_position.y <= margin or global_position.y >= viewport_size.y - margin:
			if randf() < 0.5:  # 50% chance to bounce, 50% to choose new target
				walk_direction.y *= -1  # Bounce
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
		print("CHARACTER DEBUG: Input event - click detected!")
		_handle_click()
		get_viewport().set_input_as_handled()

# Centralized click handling
func _handle_click():
	print("CHARACTER DEBUG: Handling click on character: " + variant_name)
	# Stop character and emit signal
	is_walking = false
	if animated_sprite:
		animated_sprite.pause()
	emit_signal("character_clicked", self)
	print("CHARACTER DEBUG: character_clicked signal emitted")
	
	# Visual feedback
	modulate = Color(1.5, 1.5, 1.5)  # Bright highlight when clicked
	# Reset modulate after a short time
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

# Visual feedback for mouse hover
func _on_mouse_entered():
	print("CHARACTER DEBUG: Mouse entered")
	modulate = Color(1.2, 1.2, 1.2)  # Slight highlight

func _on_mouse_exited():
	print("CHARACTER DEBUG: Mouse exited")
	modulate = Color(1, 1, 1)  # Normal color

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
	
	# Make sure to free the character when the animation completes
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
	# Ensure velocity is not zero
	velocity = walk_direction * walking_speed
	
	# Ensure animation is playing
	if animated_sprite:
		animated_sprite.play()
		print("CHARACTER DEBUG: Animation restarted")
	
	# Recalculate direction to target if needed
	if target_position == Vector2.ZERO or global_position.distance_to(target_position) < 20:
		# Choose a new exit point
		start_walking()
	else:
		# Use existing target
		walk_direction = (target_position - global_position).normalized()
		face_walk_direction()
	
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
