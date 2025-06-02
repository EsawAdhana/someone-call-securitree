extends Node2D

# Dictionary to map area names to scene paths
var location_scenes = {
	"StadiumArea": "res://scenes/locations/stadium.tscn",
	"HooverTowerArea": "res://scenes/locations/hoover_tower.tscn",
	"MainQuadArea": "res://scenes/locations/main_quad.tscn",
	"GSBArea": "res://scenes/locations/gsb.tscn",
	"GreenLibraryArea": "res://scenes/locations/green_library.tscn",
	"MeyerGreenArea": "res://scenes/locations/meyer_green.tscn",
	"TresidderArea": "res://scenes/locations/tresidder.tscn",
	"FarrillagaArea": "res://scenes/locations/farrillaga.tscn",
	"Y2E2Area": "res://scenes/locations/y2e2.tscn",
	"CoDaArea": "res://scenes/locations/coda.tscn",
	"CantorArea": "res://scenes/locations/cantor.tscn",
	"FloMoArea": "res://scenes/locations/flomo.tscn"
}

# Dictionary to map area names to display names
var location_display_names = {
	"StadiumArea": "Stanford Stadium",
	"HooverTowerArea": "Hoover Tower",
	"MainQuadArea": "Main Quad",
	"GSBArea": "Graduate School of Business",
	"GreenLibraryArea": "Green Library",
	"MeyerGreenArea": "Meyer Green",
	"TresidderArea": "Tresidder Union",
	"FarrillagaArea": "Farrillaga Gym",
	"Y2E2Area": "Y2E2",
	"CoDaArea": "CoDa",
	"CantorArea": "Cantor Arts Center",
	"FloMoArea": "Florence Moore Hall"
}

# Tooltip label
var tooltip_label: Label

func _ready():
	# Start playing background music
	AudioManager.play_background_music()
	
	# Connect to level manager signals
	LevelManager.location_unlocked.connect(_on_location_unlocked)
	LevelManager.level_completed.connect(_on_level_completed)
	
	# Set up game manager reference for level manager
	LevelManager.set_game_manager_reference(get_node("GameManager"))
	
	# Verify level consistency for debugging
	LevelManager.verify_level_consistency()
	
	# Ensure the time display shows the current time when returning to main map
	call_deferred("update_time_display")
	
	# Create tooltip label
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 24)
	tooltip_label.add_theme_color_override("font_color", Color(1, 1, 1))
	tooltip_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tooltip_label.add_theme_constant_override("outline_size", 2)
	tooltip_label.visible = false
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(tooltip_label)
	
	# Set up all location areas
	setup_location_areas()

func _update_location_states():
	# Update visual state for all locations based on level manager
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			var is_unlocked = LevelManager.is_location_unlocked(child.name)
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape:
				var grayed_overlay = collision_shape.get_node("GrayedOverlay")
				if grayed_overlay:
					grayed_overlay.visible = not is_unlocked
			
			# Always allow input for tooltips, but we'll block clicks in the input event handler
			child.input_pickable = true

func _on_location_unlocked(location_name: String):
	print("MAP: Location unlocked:", location_name)
	_update_location_states()
	
	# Add flash/glow animation for the newly unlocked location
	_play_unlock_animation(location_name)

func _play_unlock_animation(location_name: String):
	# Find the area for this location
	var area = get_node_or_null(location_name)
	if not area:
		print("MAP: Could not find area for location:", location_name)
		return
	
	var collision_shape = area.get_node_or_null("CollisionShape2D")
	if not collision_shape:
		print("MAP: Could not find collision shape for location:", location_name)
		return
	
	var highlight = collision_shape.get_node_or_null("Highlight")
	if not highlight:
		print("MAP: Could not find highlight for location:", location_name)
		return
	
	# Create a subtle flash effect
	var original_color = highlight.color
	var flash_color = Color(1, 1, 0.7, 0.5)  # Subtle yellow flash
	
	# Make sure the highlight is visible for the animation
	highlight.visible = true
	highlight.color = flash_color
	
	# Create simple two-flash animation
	var tween = create_tween()
	
	# First flash
	tween.tween_property(highlight, "modulate:a", 0.8, 0.2)
	tween.tween_property(highlight, "modulate:a", 0.2, 0.2)
	
	# Second flash
	tween.tween_property(highlight, "modulate:a", 0.8, 0.2)
	tween.tween_property(highlight, "modulate:a", 0.0, 0.3)
	
	# Restore original state after animation
	tween.tween_callback(func():
		highlight.color = original_color
		highlight.modulate.a = 1.0
		highlight.visible = false  # Hide after animation
		print("MAP: Simple flash animation completed for:", location_name)
	)

func _on_level_completed(level_number: int):
	print("MAP: Level", level_number, "completed, updating location states")
	_update_location_states()

func _process(_delta):
	if tooltip_label.visible:
		tooltip_label.position = get_viewport().get_mouse_position() + Vector2(20, -30)

func _on_area_mouse_entered(area: Area2D):
	var is_unlocked = LevelManager.is_location_unlocked(area.name)
	var location_level = LevelManager.LOCATION_ORDER.find(area.name) + 1
	var current_level = LevelManager.get_current_level()
	
	if not is_unlocked:
		tooltip_label.text = "LEVEL LOCKED"
		tooltip_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	elif location_level < current_level:
		tooltip_label.text = "LEVEL COMPLETED"
		tooltip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	elif location_level == current_level:
		tooltip_label.text = "LEVEL READY"
		tooltip_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	else:
		tooltip_label.text = "LEVEL LOCKED"
		tooltip_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	
	tooltip_label.visible = true
	
	# Show highlight only for the current active level
	var collision_shape = area.get_node("CollisionShape2D")
	if collision_shape and location_level == current_level:
		var highlight = collision_shape.get_node("Highlight")
		if highlight:
			highlight.visible = true

func _on_area_mouse_exited(area: Area2D):
	tooltip_label.visible = false
	tooltip_label.add_theme_color_override("font_color", Color(1, 1, 1)) # Reset color
	
	# Hide highlight
	var collision_shape = area.get_node("CollisionShape2D")
	if collision_shape:
		var highlight = collision_shape.get_node("Highlight")
		if highlight:
			highlight.visible = false

func _on_area_input_event(viewport, event, shape_idx, area):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Get current level state for debugging
		var location_level = LevelManager.LOCATION_ORDER.find(area.name) + 1
		var current_level = LevelManager.get_current_level()
		var debug_info = LevelManager.get_level_debug_info()
		print("MAP CLICK DEBUG: Clicked", area.name, "- Location Level:", location_level, "Current Level:", current_level)
		print("MAP CLICK DEBUG: Level state:", debug_info)
		
		# Check if location is unlocked
		if not LevelManager.is_location_unlocked(area.name):
			print("MAP: Attempted to enter locked location:", area.name)
			return
		
		# Check if this is the current active level (prevent going back to previous levels)
		if location_level < current_level:
			print("MAP: Cannot go back to previous level:", location_level, "(current:", current_level, ")")
			return
		elif location_level > current_level:
			print("MAP: Cannot skip ahead to future level:", location_level, "(current:", current_level, ")")
			return
		
		var scene_path = location_scenes.get(area.name)
		if scene_path:
			print("MAP: Entering current level", location_level, "at location:", area.name)
			# Start the level timer when entering a location
			LevelManager.start_level(location_level)
			
			AudioManager.play_npc_click()  # Play swish sound when changing locations
			get_tree().change_scene_to_file(scene_path)

func update_time_display():
	# Make sure the time display shows the current paused time
	var game_manager = get_node("GameManager")
	if game_manager:
		var current_time = game_manager.get_current_time()
		game_manager.time_updated.emit(current_time)
		print("MAP: Updated time display to show paused time:", game_manager.get_time_string())

func _check_for_first_location_animation():
	# Check if we're at the very beginning (only first location unlocked)
	var unlocked_locations = LevelManager.get_unlocked_locations()
	if unlocked_locations.size() == 1:
		# Only show animation if this is the first location in the order
		var first_location_name = LevelManager.LOCATION_ORDER[0]
		if first_location_name in unlocked_locations:
			print("MAP: Showing animation for first location:", first_location_name)
			# Add a small delay to ensure everything is ready
			await get_tree().create_timer(0.5).timeout
			_play_unlock_animation(first_location_name)

func setup_location_areas():
	# Set up all location areas
	for child in get_children():
		if child is Area2D and child.name.ends_with("Area"):
			child.input_pickable = true
			
			# Add highlight rectangle
			var collision_shape = child.get_node("CollisionShape2D")
			if collision_shape and collision_shape.shape:
				var highlight = ColorRect.new()
				highlight.color = Color(1, 1, 0.5, 0.3)  # Soft yellow
				highlight.visible = false
				highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
				highlight.name = "Highlight"
				
				# Add grayed out overlay for locked locations
				var grayed_overlay = ColorRect.new()
				grayed_overlay.color = Color(0.3, 0.3, 0.3, 0.7)  # Dark gray overlay
				grayed_overlay.visible = false
				grayed_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				grayed_overlay.name = "GrayedOverlay"
				
				# Size both overlays to match the collision shape
				var shape = collision_shape.shape as RectangleShape2D
				if shape:
					highlight.size = shape.size
					highlight.position = -shape.size / 2  # Center on the collision shape
					grayed_overlay.size = shape.size
					grayed_overlay.position = -shape.size / 2
					
					# Apply the same transform as the collision shape
					highlight.rotation = collision_shape.rotation
					highlight.scale = collision_shape.scale
					grayed_overlay.rotation = collision_shape.rotation
					grayed_overlay.scale = collision_shape.scale
					
				collision_shape.add_child(highlight)
				collision_shape.add_child(grayed_overlay)
			
			# Connect signals
			child.mouse_entered.connect(_on_area_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_area_mouse_exited.bind(child))
			child.input_event.connect(_on_area_input_event.bind(child))
	
	# Update the visual state of all locations
	_update_location_states()
	
	# Show animation for first location if this is the initial game start
	call_deferred("_check_for_first_location_animation")
