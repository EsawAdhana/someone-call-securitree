extends Node2D

# Character spawning configuration
@export var character_scene: PackedScene
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 5.0
@export var max_characters: int = 5
@export var stanford_chance: float = 0.6  # 60% chance for Stanford students

# Track current characters
var current_characters = []
var spawn_timer: Timer

# Sprite frame resources
var stanford_sprites = []
var berkeley_sprites = []
var sprite_resources_loaded = false

# Signal for character interaction
signal character_clicked(character)

func _ready():
	print("DIRECT_SPAWNER: Initializing...")
	
	# Initialize the timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Load the character scene if not already set
	if not character_scene:
		print("DIRECT_SPAWNER: Loading character scene from path")
		character_scene = load("res://scenes/character.tscn")
		if not character_scene:
			push_error("DIRECT_SPAWNER: Failed to load character scene!")
	
	# Load all sprite resources
	load_sprite_resources()
	
	# Start spawning
	await get_tree().create_timer(0.5).timeout
	start_spawning()

# Load all sprite resources
func load_sprite_resources():
	print("DIRECT_SPAWNER: Loading sprite resources...")
	
	# Load Stanford sprites (1-3)
	for i in range(1, 4):  # Stanford 1 to 3
		var path = "res://assets/characters/stanford" + str(i) + ".tres"
		var res = load(path)
		if res:
			stanford_sprites.append(res)
			print("DIRECT_SPAWNER: Loaded Stanford sprite " + str(i))
		else:
			push_warning("DIRECT_SPAWNER: Failed to load " + path)
	
	# Load Berkeley sprites (1-4)
	for i in range(1, 5):  # Cal 1 to 4
		var path = "res://assets/characters/cal" + str(i) + ".tres"
		var res = load(path)
		if res:
			berkeley_sprites.append(res)
			print("DIRECT_SPAWNER: Loaded Berkeley sprite " + str(i))
		else:
			push_warning("DIRECT_SPAWNER: Failed to load " + path)
	
	# Check if we have at least one of each type
	if stanford_sprites.size() > 0 and berkeley_sprites.size() > 0:
		sprite_resources_loaded = true
		print("DIRECT_SPAWNER: Successfully loaded sprite resources")
	else:
		push_warning("DIRECT_SPAWNER: Couldn't load enough sprite resources")

func start_spawning():
	print("DIRECT_SPAWNER: Starting to spawn characters")
	
	if not character_scene:
		push_error("DirectSpawner: No character scene assigned!")
		return
	
	# Set the first spawn time
	set_random_spawn_time()
	
	# Force a first character spawn immediately
	spawn_character()

func set_random_spawn_time():
	var wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start(wait_time)

func _on_spawn_timer_timeout():
	if current_characters.size() < max_characters:
		spawn_character()
	
	# Set the timer for the next spawn
	set_random_spawn_time()

func spawn_character():
	# Don't spawn if we already have the maximum number of characters
	if current_characters.size() >= max_characters:
		print("DIRECT_SPAWNER: Maximum characters reached, not spawning")
		return
	
	print("DIRECT_SPAWNER: Spawning a new character")
	
	# Create a new character instance
	var character = character_scene.instantiate()
	if not character:
		push_error("DirectSpawner: Failed to instantiate character scene")
		return
	
	# FIX: Ensure input_pickable is set
	character.input_pickable = true
	
	# Get viewport size for positioning
	var viewport_size = get_viewport_rect().size
	
	# Position character DIRECTLY INSIDE the screen
	# Pick a random position inside the visible area of the screen
	var pos_x = randf_range(100, viewport_size.x - 100)
	var pos_y = randf_range(100, viewport_size.y - 100)
	var spawn_position = Vector2(pos_x, pos_y)
	
	character.global_position = spawn_position
	print("DIRECT_SPAWNER: Character positioned at " + str(spawn_position))
	
	# Configure character type (Stanford or Berkeley)
	character.character_type = 0 if randf() < stanford_chance else 1
	
	# Generate random character details
	setup_character_variants(character)
	
	# Choose a different random position for the character to walk to
	var target_position = Vector2.ZERO
	var attempts = 0
	
	# Keep trying to find a target position that's different from the spawn position
	while attempts < 10:
		target_position = Vector2(
			randf_range(100, viewport_size.x - 100),
			randf_range(100, viewport_size.y - 100)
		)
		
		# If the target is far enough from the spawn position, use it
		if target_position.distance_to(spawn_position) > 300:
			break
			
		attempts += 1
	
	character.target_position = target_position
	print("DIRECT_SPAWNER: Character target set to " + str(target_position))
	
	# IMPORTANT: Connect signals - make sure this works!
	# FIX: Always disconnect before connecting to avoid duplicate connections
	if character.character_clicked.is_connected(_on_character_clicked):
		character.character_clicked.disconnect(_on_character_clicked)
	
	character.character_clicked.connect(_on_character_clicked)
	print("DIRECT_SPAWNER: Connected character_clicked signal")
	
	if character.character_exited.is_connected(_on_character_exited):
		character.character_exited.disconnect(_on_character_exited)
		
	character.character_exited.connect(_on_character_exited)
	
	# FIX: Add the character as a direct child of this node, not as a sibling
	add_child(character)
	current_characters.append(character)
	print("DIRECT_SPAWNER: Character added to scene, total characters: " + str(current_characters.size()))
	
	# Configure sprite based on character type
	if character.has_node("AnimatedSprite2D"):
		var sprite = character.get_node("AnimatedSprite2D")
		
		# Assign a random sprite based on character type
		if sprite and sprite_resources_loaded:
			if character.character_type == 0:  # Stanford
				# Choose a random Stanford sprite
				if stanford_sprites.size() > 0:
					var sprite_index = randi() % stanford_sprites.size()
					sprite.sprite_frames = stanford_sprites[sprite_index]
					print("DIRECT_SPAWNER: Assigned Stanford sprite variant " + str(sprite_index + 1))
			else:  # Berkeley
				# Choose a random Berkeley sprite
				if berkeley_sprites.size() > 0:
					var sprite_index = randi() % berkeley_sprites.size()
					sprite.sprite_frames = berkeley_sprites[sprite_index]
					print("DIRECT_SPAWNER: Assigned Berkeley sprite variant " + str(sprite_index + 1))
		
		# Start animation
		sprite.play("walk")
	
	# Force the character to start walking
	character.is_walking = true
	character.walk_direction = (target_position - spawn_position).normalized()
	character.just_spawned = false  # Not needed since we're spawning directly on-screen

# Set up random character properties
func setup_character_variants(character):
	# Generate name based on character type
	var first_names = ["Alex", "Taylor", "Jordan", "Casey", "Riley", "Morgan", "Avery", "Quinn"]
	var stanford_last_names = ["Smith", "Johnson", "Williams", "Jones", "Brown"]
	var berkeley_last_names = ["Garcia", "Rodriguez", "Martinez", "Hernandez", "Lopez"]
	
	var first_name = first_names[randi() % first_names.size()]
	var last_name
	
	if character.character_type == 0:  # Stanford
		last_name = stanford_last_names[randi() % stanford_last_names.size()]
	else:  # Berkeley
		last_name = berkeley_last_names[randi() % berkeley_last_names.size()]
	
	character.variant_name = first_name + " " + last_name
	
	# Random gameplay variations
	character.has_id = randf() < 0.9  # 90% chance to have ID
	character.valid_major = randf() < 0.8  # 80% chance to have valid major

# Handle character being clicked - THIS IS CRITICAL
func _on_character_clicked(character):
	print("DIRECT_SPAWNER: Character " + character.variant_name + " was clicked!")
	
	# Forward the signal to whoever is listening (should be LocationTemplate)
	character_clicked.emit(character)

# Handle character exiting the scene
func _on_character_exited(character):
	print("DIRECT_SPAWNER: Character exited")
	if current_characters.has(character):
		current_characters.erase(character)
