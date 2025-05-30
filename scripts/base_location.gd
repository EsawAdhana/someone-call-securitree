extends Node2D

# The current location name (to be set by each inheriting scene)
var current_location: String = ""

func _ready():
	# If we have stored spawn data, position the character correctly
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.stored_spawn_data:
		var spawn_data = game_manager.stored_spawn_data
		await get_tree().create_timer(0.1).timeout # Wait for scene to be ready
		
		# Find the player character
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = spawn_data.position
			
			# Only resume walking if the character has the method and was walking
			if player.has_method("resume_walking") and player.get("is_walking"):
				await get_tree().create_timer(0.2).timeout # Additional safety delay
				if is_instance_valid(player) and player.has_method("resume_walking"):
					player.resume_walking()
		
		# Clear the stored spawn data
		game_manager.stored_spawn_data = null 