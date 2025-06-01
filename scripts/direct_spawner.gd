extends Node2D

# Character spawning configuration
@export var character_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0
@export var max_characters: int = 10 # Changed to 10 for our predefined characters

# Track current characters
var current_characters = []
var spawn_timer: Timer

# Character data manager
var character_data_manager

# Signal for character interaction
signal character_clicked(character)

func _ready():
	print("[SPAWN DEBUG] DirectSpawner _ready() called")
	print("[SPAWN DEBUG] Max characters set to:", max_characters)
	
	# Initialize character data manager
	character_data_manager = preload("res://scripts/character_data.gd").new()
	character_data_manager.reset_characters()
	print("[SPAWN DEBUG] Character data manager initialized and reset")
	
	# Initialize the timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	print("[SPAWN DEBUG] Spawn timer initialized")
	
	# Load the character scene if not already set
	if not character_scene:
		print("[SPAWN DEBUG] Loading character scene from path")
		character_scene = load("res://scenes/character.tscn")
		if not character_scene:
			push_error("[SPAWN DEBUG] Failed to load character scene!")
		else:
			print("[SPAWN DEBUG] Character scene loaded successfully")
	
	# Start spawning
	print("[SPAWN DEBUG] Starting initial spawn delay")
	await get_tree().create_timer(0.5).timeout
	start_spawning()

func start_spawning():
	print("[SPAWN DEBUG] start_spawning() called")
	print("[SPAWN DEBUG] Current character count:", current_characters.size())
	set_random_spawn_time()

func set_random_spawn_time():
	var wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	print("[SPAWN DEBUG] Setting spawn timer for", wait_time, "seconds")
	spawn_timer.start(wait_time)

func _on_spawn_timer_timeout():
	print("[SPAWN DEBUG] Spawn timer timeout triggered")
	print("[SPAWN DEBUG] Current character count:", current_characters.size())
	print("[SPAWN DEBUG] Max characters:", max_characters)
	
	spawn_character()
	
	# Only set next spawn time if we haven't reached max characters
	if current_characters.size() < max_characters:
		print("[SPAWN DEBUG] Setting next spawn timer")
		set_random_spawn_time()
	else:
		print("[SPAWN DEBUG] Maximum characters reached, not setting next spawn timer")

func spawn_character():
	print("[SPAWN DEBUG] spawn_character() called")
	print("[SPAWN DEBUG] Current character count:", current_characters.size())
	
	# Don't spawn if we already have the maximum number of characters
	if current_characters.size() >= max_characters:
		print("[SPAWN DEBUG] Maximum characters reached, not spawning")
		return
	
	print("[SPAWN DEBUG] Getting next character data")
	
	# Get next character data
	var char_data = character_data_manager.get_random_character()
	print("[SPAWN DEBUG] Character data received:", char_data)
	
	if char_data.is_empty():
		print("[SPAWN DEBUG] No more characters available")
		return
	
	print("[SPAWN DEBUG] Got character data for:", char_data["name"])
	
	# Create a new character instance
	var character = character_scene.instantiate()
	if not character:
		push_error("[SPAWN DEBUG] Failed to instantiate character scene")
		return
	
	print("[SPAWN DEBUG] Character instance created")
	
	# Set up character properties
	character.input_pickable = true
	character.character_type = char_data["type"]
	character.variant_name = char_data["name"]
	character.has_id = true # All our predefined characters have IDs
	character.valid_major = true # All our predefined characters have valid majors
	character.l1_id = char_data["id"] # Set the ID for the character
	
	# Store additional data in the character for the inspection panel
	character.set_meta("character_data", char_data)
	
	# Connect character's clicked signal to forward it through the spawner
	if not character.character_clicked.is_connected(_on_character_clicked):
		character.character_clicked.connect(_on_character_clicked)
		print("[SPAWN DEBUG] Connected character click signal")
	
	# Assign Stanford sprite based on character's name (to determine gender)
	if character.has_node("AnimatedSprite2D"):
		var sprite = character.get_node("AnimatedSprite2D")
		var first_name = char_data["name"].split(" ")[0]
		
		# Female names in our character data
		var female_names = ["Jessica", "Maya", "Hannah", "Sibana"]
		
		# Choose sprite based on gender
		var sprite_frames
		if female_names.has(first_name):
			sprite_frames = load("res://assets/characters/stanford3.tres") # Female sprite
		else:
			# Randomly choose between stanford1 and stanford2 for male characters
			var male_sprites = [
				"res://assets/characters/stanford1.tres",
				"res://assets/characters/stanford2.tres"
			]
			sprite_frames = load(male_sprites[randi() % 2])
		
		if sprite_frames:
			sprite.sprite_frames = sprite_frames
			sprite.play("walk")
	
	# Get viewport size for positioning
	var viewport_size = get_viewport_rect().size
	print("[SPAWN DEBUG] Viewport size:", viewport_size)
	
	# Position character DIRECTLY INSIDE the screen with safe margins
	var margin = 100
	var pos_x = randf_range(margin, viewport_size.x - margin)
	var pos_y = randf_range(margin, viewport_size.y - margin)
	var spawn_position = Vector2(pos_x, pos_y)
	
	character.global_position = spawn_position
	print("[SPAWN DEBUG] Character positioned at:", spawn_position)
	
	# Choose a different random position for the character to walk to
	var target_position = Vector2.ZERO
	var attempts = 0
	
	# Keep trying to find a target position that's different from the spawn position
	while attempts < 10:
		target_position = Vector2(
			randf_range(margin, viewport_size.x - margin),
			randf_range(margin, viewport_size.y - margin)
		)
		
		# If the target is far enough from the spawn position, use it
		if target_position.distance_to(spawn_position) > 200:
			break
			
		attempts += 1
	
	character.target_position = target_position
	print("[SPAWN DEBUG] Character target set to:", target_position)
	
	# Add to our tracking array
	current_characters.append(character)
	
	# Add to the global manager instead of adding directly to the scene
	var location = get_parent()
	if location and location.has_method("get_location_name"):
		var location_name = location.get_location_name()
		var global_manager = get_node("/root/GlobalCharacterManager")
		if global_manager:
			# Add to the global manager
			global_manager.add_character(location_name, character)
			# Add to the scene immediately since this is a new character
			location.add_child(character)
			character.visible = true
			character.modulate.a = 1.0 # Ensure full opacity
			print("[SPAWN DEBUG] Character added to scene and global manager")
		else:
			push_error("[SPAWN DEBUG] Could not find GlobalCharacterManager")
	else:
		push_error("[SPAWN DEBUG] Could not determine location name")
	
	print("[SPAWN DEBUG] Successfully spawned character", char_data["name"], "of type", char_data["type"])
	print("[SPAWN DEBUG] New character count:", current_characters.size())

# Forward the character clicked signal
func _on_character_clicked(character):
	print("[SPAWN DEBUG] Character clicked, forwarding signal:", character.variant_name)
	character_clicked.emit(character)
