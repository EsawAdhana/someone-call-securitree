# base_location.gd
extends Node2D

@export var location_name: String = "base"  # Export this to be set in the Inspector

func _ready():
	# Tell the game manager where we are
	Game.change_location(location_name)
	
	# Connect to the existing button that's already in your scene
	$BackToMap.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Add HUD if not already present
	if not has_node("HUD"):
		var hud_scene = load("res://hud.tscn")
		if hud_scene:
			var hud = hud_scene.instantiate()
			add_child(hud)

func _on_back_button_pressed():
	Game.change_location("map")
	get_tree().change_scene_to_file("res://map.tscn")

func spawn_button():
	print("Spawning button in ", location_name, " scene")
	
	# Load the random button scene
	var button_scene = load("res://random_button.tscn")
	if button_scene:
		var button = button_scene.instantiate()
		
		# Position the button randomly within the scene
		var viewport_size = get_viewport_rect().size
		button.position.x = randf_range(100, viewport_size.x - 100)
		button.position.y = randf_range(100, viewport_size.y - 100)
		
		# Add the button to the scene
		add_child(button)
		print("Button added to scene")
	else:
		print("Failed to load button scene!")
