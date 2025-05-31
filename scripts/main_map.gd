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
				
				# Size the highlight to match the collision shape
				var shape = collision_shape.shape as RectangleShape2D
				if shape:
					highlight.size = shape.size
					highlight.position = -shape.size / 2  # Center on the collision shape
					
					# Apply the same transform as the collision shape
					highlight.rotation = collision_shape.rotation
					highlight.scale = collision_shape.scale
					
				collision_shape.add_child(highlight)
			
			# Connect signals
			child.mouse_entered.connect(_on_area_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_area_mouse_exited.bind(child))
			child.input_event.connect(_on_area_input_event.bind(child))

func _process(_delta):
	if tooltip_label.visible:
		tooltip_label.position = get_viewport().get_mouse_position() + Vector2(20, -30)

func _on_area_mouse_entered(area: Area2D):
	tooltip_label.text = location_display_names.get(area.name, area.name)
	tooltip_label.visible = true
	
	# Show highlight
	var collision_shape = area.get_node("CollisionShape2D")
	if collision_shape:
		var highlight = collision_shape.get_node("Highlight")
		if highlight:
			highlight.visible = true

func _on_area_mouse_exited(area: Area2D):
	tooltip_label.visible = false
	
	# Hide highlight
	var collision_shape = area.get_node("CollisionShape2D")
	if collision_shape:
		var highlight = collision_shape.get_node("Highlight")
		if highlight:
			highlight.visible = false

func _on_area_input_event(viewport, event, shape_idx, area):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var scene_path = location_scenes.get(area.name)
		if scene_path:
			AudioManager.play_npc_click()  # Play swish sound when changing locations
			get_tree().change_scene_to_file(scene_path)
