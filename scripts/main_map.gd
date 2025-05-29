extends Node2D

# Dictionary to map area names to scene paths
var location_scenes = {
	"StadiumArea": "res://scenes/locations/stadium.tscn",
	"OvalArea": "res://scenes/locations/oval.tscn",
	"HooverTowerArea": "res://scenes/locations/hoover_tower.tscn",
}

@onready var camera: Camera2D = $MapBackground/Camera2D
@onready var map_sprite: Sprite2D = $MapBackground

# Debug visualization
var show_debug_areas = false  # Hidden by default
var debug_colors = [
	Color(1, 0, 0, 0.3),    # Red
	Color(0, 1, 0, 0.3),    # Green  
	Color(0, 0, 1, 0.3),    # Blue
	Color(1, 1, 0, 0.3),    # Yellow
	Color(1, 0, 1, 0.3),    # Magenta
	Color(0, 1, 1, 0.3),    # Cyan
]

# Editing mode
var editing_mode = false
var dragging_area = null
var drag_offset = Vector2.ZERO
var coordinate_label = null

func _ready():
	# Set up zoom-to-fit functionality
	_setup_zoom_to_fit()
	
	# Connect window resize signal for dynamic resizing
	get_tree().get_root().size_changed.connect(_on_window_resized)
	
	# Create coordinate display label (hidden by default)
	_create_coordinate_display()
	
	# Connect all Area2D nodes' input events for location areas
	var color_index = 0
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			# Connect the input event signal to the on_area_clicked function
			child.input_event.connect(_on_area_input_event.bind(child))
			
			# Create debug visualization for the area
			_create_debug_visualization(child, color_index)
			color_index += 1
			
			# Make the area visually respond to mouse hover
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape:
				# Create a subtle highlight effect (optional)
				var highlight = Sprite2D.new()
				highlight.modulate = Color(1, 1, 0, 0.3)  # Yellow transparent
				highlight.visible = false
				highlight.name = "Highlight"
				child.add_child(highlight)

func _create_coordinate_display():
	# Create a label to show coordinates
	coordinate_label = Label.new()
	coordinate_label.add_theme_color_override("font_color", Color.WHITE)
	coordinate_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	coordinate_label.add_theme_constant_override("shadow_offset_x", 2)
	coordinate_label.add_theme_constant_override("shadow_offset_y", 2)
	coordinate_label.position = Vector2(10, 10)
	coordinate_label.text = "Debug Mode: Cmd+Shift+E to enter editing mode"
	coordinate_label.visible = false  # Hidden by default
	
	# Add to UI layer so it's always visible
	var ui_node = get_node("UI")
	if ui_node:
		ui_node.add_child(coordinate_label)

func _create_debug_visualization(area: Area2D, color_index: int):
	var collision_shape = area.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return
	
	# Create a ColorRect to visualize the area
	var debug_rect = ColorRect.new()
	debug_rect.name = "DebugVisualization"
	
	# Set color (cycle through available colors)
	var color = debug_colors[color_index % debug_colors.size()]
	debug_rect.color = color
	
	# Get the shape size and position
	var shape = collision_shape.shape as RectangleShape2D
	if shape:
		debug_rect.size = shape.size
		# Position the rect to be centered on the collision shape
		debug_rect.position = collision_shape.position - shape.size / 2
		debug_rect.rotation = collision_shape.rotation
		debug_rect.scale = collision_shape.scale
	
	# Add label to show area name and position
	var label = Label.new()
	label.name = "AreaLabel"  # Give the label a name so we can find it later
	label.text = area.name + "\n" + str(collision_shape.position)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = Vector2(10, 10)  # Offset from corner
	debug_rect.add_child(label)
	
	# Set visibility based on debug flag
	debug_rect.visible = show_debug_areas
	
	# Add to the area
	area.add_child(debug_rect)
	
	print("Created debug visualization for: ", area.name, " with color: ", color)

func toggle_editing_mode():
	editing_mode = !editing_mode
	print("Editing mode: ", editing_mode)
	
	# Show/hide coordinate display based on editing mode
	if coordinate_label:
		coordinate_label.visible = editing_mode
	
	# Show/hide debug areas when entering editing mode
	if editing_mode:
		show_debug_areas = true
	else:
		show_debug_areas = false
		dragging_area = null  # Stop any current dragging
	
	# Update debug area visibility
	for child in get_children():
		if child is Area2D and child.has_node("DebugVisualization"):
			var debug_rect = child.get_node("DebugVisualization")
			debug_rect.visible = show_debug_areas
			if editing_mode:
				# Make areas more visible in editing mode
				debug_rect.color.a = 0.5  # More opaque
			else:
				# Return to normal transparency
				debug_rect.color.a = 0.3

func _input(event):
	# Press Cmd+Shift+E (or Ctrl+Shift+E on non-Mac) to toggle editing mode
	if event is InputEventKey and event.keycode == KEY_E and event.pressed:
		if (event.meta_pressed and event.shift_pressed) or (event.ctrl_pressed and event.shift_pressed):
			toggle_editing_mode()
	
	# Only allow other debug commands when in editing mode
	if editing_mode:
		# Press 'D' to toggle debug areas visibility (only in editing mode)
		if event is InputEventKey and event.keycode == KEY_D and event.pressed:
			show_debug_areas = !show_debug_areas
			for child in get_children():
				if child is Area2D and child.has_node("DebugVisualization"):
					child.get_node("DebugVisualization").visible = show_debug_areas
			print("Debug areas visibility: ", show_debug_areas)
		
		# Press 'S' to save current positions (only in editing mode)
		if event is InputEventKey and event.keycode == KEY_S and event.pressed:
			save_area_positions()
		
		# Handle dragging in editing mode
		_handle_editing_input(event)

func _handle_editing_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging - find which area we clicked on
				var mouse_pos = camera.get_global_mouse_position()  # Use camera's mouse position
				dragging_area = _get_area_at_position(mouse_pos)
				if dragging_area:
					var collision_shape = dragging_area.get_node("CollisionShape2D")
					drag_offset = collision_shape.position - mouse_pos
					print("Started dragging: ", dragging_area.name)
			else:
				# Stop dragging
				if dragging_area:
					print("Stopped dragging: ", dragging_area.name, " at position: ", dragging_area.get_node("CollisionShape2D").position)
					_update_debug_label(dragging_area)
				dragging_area = null
	
	elif event is InputEventMouseMotion and dragging_area:
		# Update position while dragging
		var new_position = camera.get_global_mouse_position() + drag_offset  # Use camera's mouse position
		var collision_shape = dragging_area.get_node("CollisionShape2D")
		collision_shape.position = new_position
		
		# Update debug visualization position
		if dragging_area.has_node("DebugVisualization"):
			var debug_rect = dragging_area.get_node("DebugVisualization")
			var shape = collision_shape.shape as RectangleShape2D
			if shape:
				debug_rect.position = collision_shape.position - shape.size / 2
		
		_update_debug_label(dragging_area)

func _get_area_at_position(pos: Vector2) -> Area2D:
	# Find which area contains the given position
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape and collision_shape.shape:
				var shape = collision_shape.shape as RectangleShape2D
				var area_pos = collision_shape.position
				var half_size = shape.size / 2
				
				if pos.x >= area_pos.x - half_size.x and pos.x <= area_pos.x + half_size.x and \
				   pos.y >= area_pos.y - half_size.y and pos.y <= area_pos.y + half_size.y:
					return child
	return null

func _update_debug_label(area: Area2D):
	if area and area.has_node("DebugVisualization"):
		var debug_rect = area.get_node("DebugVisualization")
		if debug_rect.has_node("AreaLabel"):  # Check if the label exists
			var label = debug_rect.get_node("AreaLabel")
			var collision_shape = area.get_node("CollisionShape2D")
			label.text = area.name + "\n" + str(collision_shape.position)

func save_area_positions():
	print("=== CURRENT AREA POSITIONS ===")
	print("Copy these values to your scene file:")
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape:
				print(child.name, ": position = Vector2(", collision_shape.position.x, ", ", collision_shape.position.y, ")")
	print("==============================")

func _process(delta):
	# Update coordinate display (only when editing mode is active)
	if coordinate_label and editing_mode:
		var mouse_pos = camera.get_global_mouse_position()  # Use camera's mouse position
		var dragging_text = ""
		if dragging_area:
			dragging_text = " | Dragging: " + dragging_area.name
		coordinate_label.text = "Mouse: (" + str(int(mouse_pos.x)) + ", " + str(int(mouse_pos.y)) + ")" + dragging_text + " | D=Toggle Debug, S=Save, Cmd+Shift+E=Exit"
	
	# Original hover effects for area highlights (only when not editing)
	if not editing_mode:
		for child in get_children():
			if child is Area2D and child.has_node("Highlight") and child.name.ends_with("Area"):
				var highlight = child.get_node("Highlight")
				var mouse_position = camera.get_global_mouse_position()  # Use camera's mouse position
				var collision_shape = child.get_node("CollisionShape2D")
				
				if collision_shape and collision_shape.shape:
					var rect = collision_shape.shape
					var area_position = collision_shape.position  # Use collision shape position, not child.global_position
					
					# Check if mouse is within the area
					if mouse_position.x > area_position.x - rect.size.x/2 and \
					   mouse_position.x < area_position.x + rect.size.x/2 and \
					   mouse_position.y > area_position.y - rect.size.y/2 and \
					   mouse_position.y < area_position.y + rect.size.y/2:
						highlight.visible = true
					else:
						highlight.visible = false

func _setup_zoom_to_fit():
	if not camera or not map_sprite or not map_sprite.texture:
		return
	
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Get texture size
	var texture_size = map_sprite.texture.get_size()
	
	# Calculate zoom to fit both width and height (maintaining aspect ratio)
	var zoom_x = viewport_size.x / texture_size.x
	var zoom_y = viewport_size.y / texture_size.y
	
	# Use the smaller zoom to ensure the entire map fits
	var zoom_factor = min(zoom_x, zoom_y)
	
	# Apply some padding (e.g., 90% of calculated zoom for margins)
	zoom_factor *= 0.9
	
	# Set the camera zoom
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	
	print("Viewport size: ", viewport_size)
	print("Texture size: ", texture_size)
	print("Calculated zoom: ", zoom_factor)

func _on_window_resized():
	# Recalculate zoom when window is resized
	_setup_zoom_to_fit()

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
