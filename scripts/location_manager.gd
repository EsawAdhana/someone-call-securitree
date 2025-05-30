extends Node

# Dictionary to store spawn points for each location
var spawn_points = {
	"StadiumArea": {
		"left": Vector2(-400, 0),
		"right": Vector2(400, 0),
		"top": Vector2(0, -250),
		"bottom": Vector2(0, 250)
	},
	"OvalArea": {
		"left": Vector2(-250, 0),
		"right": Vector2(250, 0),
		"top": Vector2(0, -250),
		"bottom": Vector2(0, 250)
	},
	"HooverTowerArea": {
		"left": Vector2(-250, 0),
		"right": Vector2(250, 0),
		"top": Vector2(0, -250),
		"bottom": Vector2(0, 250)
	}
}

# Get a random location excluding the current one
func get_random_location(current_location: String) -> String:
	var available_locations = spawn_points.keys()
	available_locations.erase(current_location)
	return available_locations[randi() % available_locations.size()]

# Get the opposite direction
func get_opposite_direction(direction: String) -> String:
	match direction:
		"left": return "right"
		"right": return "left"
		"top": return "bottom"
		"bottom": return "top"
		_: return "right"  # default case

# Get spawn position for a location and direction
func get_spawn_position(location: String, direction: String) -> Vector2:
	if spawn_points.has(location) and spawn_points[location].has(direction):
		return spawn_points[location][direction]
	return Vector2.ZERO

# Determine exit direction based on position
func get_exit_direction(position: Vector2, bounds: Rect2) -> String:
	if position.x <= bounds.position.x:
		return "left"
	elif position.x >= bounds.position.x + bounds.size.x:
		return "right"
	elif position.y <= bounds.position.y:
		return "top"
	else:
		return "bottom" 