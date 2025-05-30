extends Node2D

@onready var location_manager = $"/root/LocationManager"

# The current location name (to be set by each inheriting scene)
var current_location: String = ""

# Area2D nodes that will detect when character exits the screen
@onready var exit_areas = {
	"left": $ExitAreas/LeftExit,
	"right": $ExitAreas/RightExit,
	"top": $ExitAreas/TopExit,
	"bottom": $ExitAreas/BottomExit
}

func _ready():
	# Set up exit detection areas
	for direction in exit_areas:
		if exit_areas[direction]:
			exit_areas[direction].body_entered.connect(_on_exit_area_entered.bind(direction))
			
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

func _on_exit_area_entered(body: Node2D, direction: String):
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
		
	var new_location = location_manager.get_random_location(current_location)
	var spawn_direction = location_manager.get_opposite_direction(direction)
	var spawn_position = location_manager.get_spawn_position(new_location, spawn_direction)
	
	# Store the spawn position and direction for the next scene
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.stored_spawn_data = {
			"position": spawn_position,
			"direction": spawn_direction
		}
		
		# Store walking state if available
		if body.has_method("is_walking"):
			game_manager.stored_spawn_data["was_walking"] = body.is_walking
	
	# Change to the new location scene
	get_tree().change_scene_to_file("res://scenes/locations/" + new_location.to_lower().replace("area", "") + ".tscn") 