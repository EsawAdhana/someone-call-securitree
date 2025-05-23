extends Node2D

# Dictionary to map area names to scene paths
var location_scenes = {
	"StadiumArea": "res://scenes/locations/stadium.tscn",
	"OvalArea": "res://scenes/locations/oval.tscn",
	"HooverTowerArea": "res://scenes/locations/hoover_tower.tscn",
	# Add all other locations here
}

func _ready():
	# Connect all Area2D nodes' input events for location areas
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			# Connect the input event signal to the on_area_clicked function
			child.input_event.connect(_on_area_input_event.bind(child))
			
			# Make the area visually respond to mouse hover
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape:
				# Create a subtle highlight effect (optional)
				var highlight = Sprite2D.new()
				highlight.modulate = Color(1, 1, 0, 0.3)  # Yellow transparent
				highlight.visible = false
				highlight.name = "Highlight"
				child.add_child(highlight)

func _on_area_input_event(viewport, event, shape_idx, area):
	# Check if the event is a mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clicked on: " + area.name)
		# Get the location scene path from our dictionary
		var scene_path = location_scenes.get(area.name)
		if scene_path:
			# Change to the location scene
			get_tree().change_scene_to_file(scene_path)
		else:
			print("No scene defined for " + area.name)

# Mouse hover effects for area highlights
func _process(delta):
	for child in get_children():
		if child is Area2D and child.has_node("Highlight") and child.name.ends_with("Area"):
			var highlight = child.get_node("Highlight")
			var mouse_position = get_global_mouse_position()
			var collision_shape = child.get_node("CollisionShape2D")
			
			if collision_shape and collision_shape.shape:
				var rect = collision_shape.shape
				var area_position = child.global_position
				
				# Check if mouse is within the area
				if mouse_position.x > area_position.x - rect.size.x/2 and \
				   mouse_position.x < area_position.x + rect.size.x/2 and \
				   mouse_position.y > area_position.y - rect.size.y/2 and \
				   mouse_position.y < area_position.y + rect.size.y/2:
					highlight.visible = true
				else:
					highlight.visible = false
