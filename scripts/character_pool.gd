extends Node

# Character pool configuration
const MAX_POOL_SIZE = 50  # Maximum characters to keep in pool
const PRELOAD_SIZE = 10   # Number of characters to preload

# Pool storage
var available_characters: Array[Node] = []
var active_characters: Array[Node] = []
var character_scene: PackedScene

func _ready():
	# Load the character scene
	character_scene = load("res://scenes/character.tscn")
	
	# Preload some characters
	for i in range(PRELOAD_SIZE):
		var character = create_new_character()
		character.visible = false
		character.set_process_mode(Node.PROCESS_MODE_DISABLED)
		available_characters.append(character)
		add_child(character)
	
	print("CharacterPool: Preloaded", PRELOAD_SIZE, "characters")

func create_new_character() -> Node:
	"""Create a fresh character instance"""
	var character = character_scene.instantiate()
	# Disable processing initially to save performance
	character.set_physics_process(false)
	character.set_process(false)
	return character

func get_character() -> Node:
	"""Get a character from the pool or create a new one"""
	var character: Node
	
	if available_characters.size() > 0:
		# Reuse from pool
		character = available_characters.pop_back()
		print("CharacterPool: Reused character from pool (", available_characters.size(), " remaining)")
	else:
		# Create new if pool is empty
		character = create_new_character()
		add_child(character)
		print("CharacterPool: Created new character (pool was empty)")
	
	# Reset character state
	reset_character(character)
	
	# Enable processing
	character.set_physics_process(true)
	character.set_process(true)
	character.set_process_mode(Node.PROCESS_MODE_INHERIT)
	character.visible = true
	
	# Track as active
	active_characters.append(character)
	
	return character

func return_character(character: Node):
	"""Return a character to the pool"""
	if not character or not is_instance_valid(character):
		return
	
	# Remove from active list
	var idx = active_characters.find(character)
	if idx != -1:
		active_characters.remove_at(idx)
	
	# Reset character state
	reset_character(character)
	
	# Disable processing to save performance
	character.set_physics_process(false)
	character.set_process(false)
	character.set_process_mode(Node.PROCESS_MODE_DISABLED)
	character.visible = false
	
	# Remove from current parent
	if character.get_parent() and character.get_parent() != self:
		character.get_parent().remove_child(character)
	
	# Add back to our pool if we have space
	if available_characters.size() < MAX_POOL_SIZE:
		if character.get_parent() != self:
			add_child(character)
		available_characters.append(character)
		print("CharacterPool: Returned character to pool (", available_characters.size(), " available)")
	else:
		# Pool is full, actually free the character
		character.queue_free()
		print("CharacterPool: Pool full, freed character")

func reset_character(character: Node):
	"""Reset character to default state"""
	if not character or not is_instance_valid(character):
		return
	
	# Reset movement
	character.is_walking = false
	character.velocity = Vector2.ZERO
	character.target_position = Vector2.ZERO
	character.walk_direction = Vector2.ZERO
	character.just_spawned = true
	
	# Reset interaction state
	character.has_been_interacted = false
	character.has_been_rejected = false
	character.was_rejected = false
	
	# Reset visual state
	character.modulate = Color.WHITE
	character.scale = Vector2.ONE
	
	# Enable collision
	if character.has_node("CollisionShape2D"):
		character.get_node("CollisionShape2D").disabled = false
	
	# Reset animation
	if character.has_node("AnimatedSprite2D"):
		var sprite = character.get_node("AnimatedSprite2D")
		sprite.flip_h = false
		if sprite.sprite_frames:
			sprite.play("walk")
	
	# Reset exclamation mark
	if character.has_node("ExclamationMark"):
		character.get_node("ExclamationMark").visible = true
	
	# Clear metadata
	for meta_name in character.get_meta_list():
		character.remove_meta(meta_name)

func clear_all_active():
	"""Return all active characters to the pool"""
	print("CharacterPool: Clearing", active_characters.size(), "active characters")
	
	# Make a copy of the array since return_character modifies active_characters
	var characters_to_return = active_characters.duplicate()
	
	for character in characters_to_return:
		return_character(character)
	
	active_characters.clear()

func get_active_count() -> int:
	"""Get number of active characters"""
	return active_characters.size()

func get_pool_size() -> int:
	"""Get number of characters in pool"""
	return available_characters.size()

func cleanup():
	"""Clean up all characters (call on game exit)"""
	print("CharacterPool: Cleaning up all characters")
	
	for character in active_characters:
		if is_instance_valid(character):
			character.queue_free()
	
	for character in available_characters:
		if is_instance_valid(character):
			character.queue_free()
	
	active_characters.clear()
	available_characters.clear() 