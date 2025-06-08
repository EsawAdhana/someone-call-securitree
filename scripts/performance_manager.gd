extends Node

# Performance optimization settings
const MAX_CHARACTERS_PROCESSING_PER_FRAME = 5  # Limit characters processed per frame
const VIEWPORT_CULLING_MARGIN = 100.0  # Margin for viewport culling
const UPDATE_INTERVAL = 0.1  # Update characters every 0.1 seconds instead of every frame

# Character processing
var characters_to_process: Array[Node] = []
var processing_index: int = 0
var update_timer: Timer

# Viewport culling
var viewport_rect: Rect2
var last_viewport_update: float = 0.0
const VIEWPORT_UPDATE_INTERVAL = 0.5  # Update viewport bounds every 0.5 seconds

func _ready():
	# Set up update timer
	update_timer = Timer.new()
	update_timer.wait_time = UPDATE_INTERVAL
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)
	
	# Get initial viewport
	update_viewport_bounds()
	
	print("PerformanceManager: Initialized with batched character updates")

func _process(delta):
	# Periodically update viewport bounds
	last_viewport_update += delta
	if last_viewport_update >= VIEWPORT_UPDATE_INTERVAL:
		update_viewport_bounds()
		last_viewport_update = 0.0

func update_viewport_bounds():
	"""Update cached viewport bounds for culling"""
	var viewport = get_viewport()
	if viewport:
		viewport_rect = viewport.get_visible_rect()
		# Add margin for characters slightly outside viewport
		viewport_rect = viewport_rect.grow(VIEWPORT_CULLING_MARGIN)

func register_character(character: Node):
	"""Register a character for performance-optimized updates"""
	if character and not characters_to_process.has(character):
		characters_to_process.append(character)
		
		# Disable the character's own physics processing
		character.set_physics_process(false)
		
		print("PerformanceManager: Registered character for batched updates")

func unregister_character(character: Node):
	"""Unregister a character from performance updates"""
	var idx = characters_to_process.find(character)
	if idx != -1:
		characters_to_process.remove_at(idx)
		
		# Adjust processing index if needed
		if processing_index > idx:
			processing_index -= 1
		elif processing_index >= characters_to_process.size():
			processing_index = 0
		
		print("PerformanceManager: Unregistered character from batched updates")

func _on_update_timer_timeout():
	"""Process a batch of characters each timer timeout"""
	if characters_to_process.is_empty():
		return
	
	var processed_count = 0
	var start_index = processing_index
	
	# Process up to MAX_CHARACTERS_PROCESSING_PER_FRAME characters
	while processed_count < MAX_CHARACTERS_PROCESSING_PER_FRAME and processed_count < characters_to_process.size():
		if processing_index >= characters_to_process.size():
			processing_index = 0
		
		var character = characters_to_process[processing_index]
		
		# Check if character is still valid
		if not is_instance_valid(character):
			characters_to_process.remove_at(processing_index)
			continue
		
		# Process the character
		process_character(character)
		
		processing_index += 1
		processed_count += 1
		
		# Prevent infinite loop
		if processing_index == start_index and processed_count > 0:
			break

func process_character(character: Node):
	"""Process a single character's movement and state"""
	if not character or not is_instance_valid(character):
		return
	
	# Check if character is visible in viewport (culling)
	if not is_character_in_viewport(character):
		# Character is outside viewport, reduce processing
		return
	
	# Only process if character is walking
	if not character.is_walking:
		return
	
	# Perform movement update (similar to original _physics_process)
	update_character_movement(character)

func is_character_in_viewport(character: Node) -> bool:
	"""Check if character is within the viewport bounds"""
	if not character or not character.has_method("get_global_position"):
		return true  # Default to processing if we can't determine position
	
	var char_pos = character.global_position
	return viewport_rect.has_point(char_pos)

func update_character_movement(character: Node):
	"""Update character movement (optimized version of original movement code)"""
	var delta = UPDATE_INTERVAL  # Use our update interval instead of frame delta
	
	# Set velocity based on direction and speed
	character.velocity = character.walk_direction * character.walking_speed
	character.move_and_slide()
	
	# Get viewport boundaries with margin
	var margin = 50
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Simple boundary checking with occasional target changes
	var should_change_target = false
	var pos = character.global_position
	
	if pos.x <= margin or pos.x >= viewport_size.x - margin:
		should_change_target = true
	
	if pos.y <= margin or pos.y >= viewport_size.y - margin:
		should_change_target = true
	
	# Keep character within bounds
	character.global_position.x = clamp(pos.x, margin, viewport_size.x - margin)
	character.global_position.y = clamp(pos.y, margin, viewport_size.y - margin)
	
	# Check if character reached destination or should change target
	if should_change_target or pos.distance_to(character.target_position) < 20:
		choose_new_target_for_character(character)
	
	# Update sprite direction
	if character.has_node("AnimatedSprite2D"):
		var sprite = character.get_node("AnimatedSprite2D")
		if character.walk_direction.x < 0:
			sprite.flip_h = true
		elif character.walk_direction.x > 0:
			sprite.flip_h = false

func choose_new_target_for_character(character: Node):
	"""Choose a new target for character movement"""
	var viewport_size = get_viewport().get_visible_rect().size
	var margin = 50
	
	# Pick a new random target within the viewport
	character.target_position = Vector2(
		randf_range(margin, viewport_size.x - margin),
		randf_range(margin, viewport_size.y - margin)
	)
	character.walk_direction = (character.target_position - character.global_position).normalized()

func clear_all_characters():
	"""Clear all registered characters"""
	characters_to_process.clear()
	processing_index = 0
	print("PerformanceManager: Cleared all registered characters")

func get_character_count() -> int:
	"""Get number of registered characters"""
	return characters_to_process.size()

func get_stats() -> Dictionary:
	"""Get performance statistics"""
	return {
		"registered_characters": characters_to_process.size(),
		"processing_index": processing_index,
		"viewport_size": viewport_rect.size,
		"update_interval": UPDATE_INTERVAL
	} 