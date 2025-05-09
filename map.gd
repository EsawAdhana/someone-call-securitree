extends Node2D

func _ready():
	# Connect to the Area2D under Sprite2D
	$Map/Stadium.connect("input_event", Callable(self, "_on_Area_input_event").bind("stadium"))
	$Map/GolfCourse.connect("input_event", Callable(self, "_on_Area_input_event").bind("golfcourse"))
	$Map/Oval.connect("input_event", Callable(self, "_on_Area_input_event").bind("oval"))
	
func _on_Area_input_event(_viewport, event, _shape_idx, area_name):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print(area_name + " clicked!")
		
		# Load different scenes based on which area was clicked
		match area_name:
			"stadium":
				print("Loading stadium scene")
				get_tree().change_scene_to_file("res://stadium.tscn")
			"golfcourse":
				print("Loading golf course scene")
				get_tree().change_scene_to_file("res://golfcourse.tscn")
			"oval":
				print("Loading oval scene")
				get_tree().change_scene_to_file("res://oval.tscn")
			_:
				# Fallback case (shouldn't happen with your setup)
				print("Unknown area: " + area_name)
				get_tree().change_scene_to_file("res://region1.tscn")
