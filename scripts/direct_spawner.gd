extends Node2D

# Character spawning configuration
@export var character_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0
@export var base_characters: int = 2 # Start with 2 characters in round 1
@export var characters_per_round_increase: int = 2 # Increase by 2 each round

# Round timing configuration
var round_duration: float = 30.0  # Total round duration in seconds (updated to 30s)
var spawn_window_fraction: float = 0.5  # Spawn within first 50% of round

# Calculated max characters based on current level
var max_characters: int = 2

# Track current characters
var current_characters = []
var spawn_timer: Timer

# Spawn timing variables
var spawn_window_duration: float
var level_start_time: float
var spawn_times: Array = []  # Pre-calculated spawn times
var next_spawn_index: int = 0

# Character data manager
var character_data_manager

# Signal for character interaction
signal character_clicked(character)

func _ready():
	print("[SPAWN DEBUG] DirectSpawner _ready() called")
	
	# Calculate spawn window duration
	spawn_window_duration = round_duration * spawn_window_fraction
	print("[SPAWN DEBUG] Spawn window duration:", spawn_window_duration, "seconds")
	
	# Get current level from LevelManager and calculate max characters
	update_max_characters_for_level()
	
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

func update_max_characters_for_level():
	# Get current level from LevelManager
	var current_level = LevelManager.get_current_level()
	# Calculate max characters: Round 1 = 2, Round 2 = 4, Round 3 = 6, etc.
	max_characters = base_characters + (current_level - 1) * characters_per_round_increase
	print("[SPAWN DEBUG] Level", current_level, "- Max characters updated to:", max_characters)

func calculate_spawn_times():
	"""Calculate all spawn times within the spawn window"""
	spawn_times.clear()
	next_spawn_index = 0
	
	if max_characters <= 0:
		return
	
	if max_characters == 1:
		# If only one character, spawn it early in the window
		spawn_times.append(randf_range(0.5, spawn_window_duration * 0.3))
	else:
		# Distribute spawns across the spawn window
		# Calculate intervals to fit all characters within the spawn window
		var available_time = spawn_window_duration - 1.0  # Leave 1 second buffer at the end
		var base_interval = available_time / max_characters
		
		# Ensure minimum spacing between spawns
		var min_spacing = 1.0
		if base_interval < min_spacing:
			base_interval = min_spacing
		
		var current_time = 0.5  # Start with small initial delay
		
		for i in range(max_characters):
			# Add some randomization while staying within bounds
			var variation = randf_range(-0.5, 0.5)
			var spawn_time = current_time + variation
			
			# Ensure spawn time is within the spawn window
			spawn_time = max(0.5, min(spawn_time, spawn_window_duration - 0.5))
			
			spawn_times.append(spawn_time)
			current_time += base_interval
			
			# Stop if we've exceeded the spawn window
			if current_time >= spawn_window_duration:
				break
	
	# Sort spawn times to ensure proper order
	spawn_times.sort()
	
	print("[SPAWN DEBUG] Calculated spawn times:", spawn_times)
	print("[SPAWN DEBUG] All spawns will complete within", spawn_window_duration, "seconds")

func start_spawning():
	print("[SPAWN DEBUG] start_spawning() called")
	print("[SPAWN DEBUG] Current character count:", current_characters.size())
	
	# Record the level start time
	level_start_time = Time.get_ticks_msec() / 1000.0
	
	# Calculate spawn times for this round
	calculate_spawn_times()
	
	# Inform GameManager about how many characters we plan to spawn
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		# Try to find it in the current scene
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("set_planned_characters_for_round"):
		game_manager.set_planned_characters_for_round(max_characters)
		print("[SPAWN DEBUG] Informed GameManager of planned characters:", max_characters)
	
	# Start the first spawn timer if we have any spawns scheduled
	if spawn_times.size() > 0:
		set_next_spawn_time()
	elif max_characters == 0:
		# If no characters planned, mark all as spawned immediately
		if game_manager and game_manager.has_method("mark_all_planned_characters_spawned"):
			game_manager.mark_all_planned_characters_spawned()

func set_next_spawn_time():
	"""Set timer for the next scheduled spawn"""
	if next_spawn_index >= spawn_times.size():
		print("[SPAWN DEBUG] All spawns scheduled, no more spawn times")
		return
	
	var target_spawn_time = spawn_times[next_spawn_index]
	var current_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	var wait_time = max(0.1, target_spawn_time - current_time)
	
	print("[SPAWN DEBUG] Setting spawn timer for", wait_time, "seconds (target:", target_spawn_time, "s)")
	spawn_timer.start(wait_time)

func set_random_spawn_time():
	# This function is kept for compatibility but now uses the new system
	set_next_spawn_time()

func _on_spawn_timer_timeout():
	print("[SPAWN DEBUG] Spawn timer timeout triggered")
	print("[SPAWN DEBUG] Current character count:", current_characters.size())
	print("[SPAWN DEBUG] Max characters:", max_characters)
	
	var current_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	print("[SPAWN DEBUG] Current time since level start:", current_time, "seconds")
	
	# Check if we're still within the spawn window
	if current_time <= spawn_window_duration:
		spawn_character()
		next_spawn_index += 1
		
		# Set next spawn time if more characters are scheduled
		if next_spawn_index < spawn_times.size() and current_characters.size() < max_characters:
			print("[SPAWN DEBUG] Setting next spawn timer")
			set_next_spawn_time()
		else:
			print("[SPAWN DEBUG] All characters spawned or spawn window closed")
			# Notify GameManager that all planned characters have been spawned
			var game_manager = get_node_or_null("/root/GameManager")
			if not game_manager:
				game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager and game_manager.has_method("mark_all_planned_characters_spawned"):
				game_manager.mark_all_planned_characters_spawned()
				print("[SPAWN DEBUG] Notified GameManager that all planned characters spawned")
	else:
		print("[SPAWN DEBUG] Spawn window closed, no more spawning")
		# Even if spawn window closed, notify that we're done spawning
		var game_manager = get_node_or_null("/root/GameManager")
		if not game_manager:
			game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager and game_manager.has_method("mark_all_planned_characters_spawned"):
			game_manager.mark_all_planned_characters_spawned()
			print("[SPAWN DEBUG] Notified GameManager that spawning finished (window closed)")

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

# Function to update max character count based on current level (called externally)
func update_max_character_count():
	var old_max = max_characters
	update_max_characters_for_level()
	print("[SPAWN DEBUG] Updated max characters from", old_max, "to", max_characters)
	
	# Recalculate spawn times if the count changed
	if old_max != max_characters:
		calculate_spawn_times()
	
	# If we now have room for more characters and spawning stopped, restart it
	if current_characters.size() < max_characters and spawn_timer.is_stopped() and next_spawn_index < spawn_times.size():
		var current_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
		if current_time <= spawn_window_duration:
			print("[SPAWN DEBUG] Restarting spawning due to increased max characters")
			set_next_spawn_time()
