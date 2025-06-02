extends Control

@onready var progress_bar = $MarginContainer/VBoxContainer/ProgressBar
@onready var percent_label = $MarginContainer/VBoxContainer/PercentLabel

func _ready():
	# Make sure we're visible and always on top
	show()
	top_level = true # This makes it stay visible regardless of parent visibility
	
	# Set process mode to work when paused so morale updates are visible during game over
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Clear any existing theme overrides from the scene file that might conflict
	progress_bar.remove_theme_stylebox_override("fill")
	progress_bar.remove_theme_stylebox_override("background")
	
	# Set up the progress bar properties
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	
	# Create and set up background style (empty portion)
	var background_style = StyleBoxFlat.new()
	background_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)  # Dark gray background
	background_style.border_width_left = 2
	background_style.border_width_top = 2
	background_style.border_width_right = 2
	background_style.border_width_bottom = 2
	background_style.border_color = Color(0.1, 0.1, 0.1, 0.8)
	background_style.corner_radius_top_left = 8
	background_style.corner_radius_top_right = 8
	background_style.corner_radius_bottom_right = 8
	background_style.corner_radius_bottom_left = 8
	progress_bar.add_theme_stylebox_override("background", background_style)
	
	# Connect to the MoraleManager signals
	MoraleManager.morale_changed.connect(_on_morale_changed)
	
	# Set initial value and color
	var initial_morale = MoraleManager.get_morale()
	progress_bar.value = initial_morale
	print("MORALE BAR DEBUG: Setting initial value to", initial_morale, "%. Progress bar value is now:", progress_bar.value)
	_update_color(initial_morale)
	_update_percent_label(initial_morale)

func _on_morale_changed(new_value: float):
	print("MORALE BAR DEBUG: Morale changed to", new_value, "%")
	
	# Update the progress bar value immediately first
	progress_bar.value = new_value
	print("MORALE BAR DEBUG: Progress bar value set to:", progress_bar.value)
	
	# Then animate it with a tween for smooth visual feedback
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", new_value, 0.3).set_ease(Tween.EASE_OUT)
	
	# Update color and label
	_update_color(new_value)
	_update_percent_label(new_value)
	
	# Force a redraw
	progress_bar.queue_redraw()

func _update_color(value: float):
	# Create a new StyleBoxFlat for the fill
	var fill_style = StyleBoxFlat.new()
	
	# Set color based on morale level
	var target_color: Color
	if value >= 80:
		target_color = Color(0.2, 0.8, 0.2, 1.0) # Bright green
	elif value >= 60:
		target_color = Color(0.6, 0.8, 0.2, 1.0) # Yellow-green  
	elif value >= 40:
		target_color = Color(0.9, 0.7, 0.2, 1.0) # Amber/Orange
	elif value >= 20:
		target_color = Color(0.9, 0.5, 0.2, 1.0) # Orange-red
	else:
		target_color = Color(0.8, 0.2, 0.2, 1.0) # Red
	
	# Configure the fill style
	fill_style.bg_color = target_color
	fill_style.border_width_left = 1
	fill_style.border_width_top = 1
	fill_style.border_width_right = 1
	fill_style.border_width_bottom = 1
	fill_style.border_color = Color(0.1, 0.1, 0.1, 0.5)
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.corner_radius_bottom_left = 6
	
	# Apply the new style to the progress bar
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	print("MORALE BAR DEBUG: Updated color to", target_color, "for value", value, "%. Min:", progress_bar.min_value, "Max:", progress_bar.max_value, "Current:", progress_bar.value)

func _update_percent_label(value: float):
	percent_label.text = "%d%%" % value 
