extends Control

@onready var progress_bar = $MarginContainer/VBoxContainer/ProgressBar
@onready var percent_label = $MarginContainer/VBoxContainer/PercentLabel

func _ready():
	# Make sure we're visible and always on top
	show()
	top_level = true # This makes it stay visible regardless of parent visibility
	
	# Set up the progress bar style
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	
	# Connect to the MoraleManager signals
	MoraleManager.morale_changed.connect(_on_morale_changed)
	
	# Set initial value and color
	progress_bar.value = MoraleManager.get_morale()
	_update_color(progress_bar.value)
	_update_percent_label(progress_bar.value)

func _on_morale_changed(new_value: float):
	# Update the progress bar with animation
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", new_value, 0.5).set_ease(Tween.EASE_OUT)
	
	# Update color with transition
	_update_color(new_value)
	_update_percent_label(new_value)

func _update_color(value: float):
	var style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	var target_color: Color
	
	if value >= 80:
		target_color = Color(0.2, 0.8, 0.2) # Bright green
	elif value >= 60:
		target_color = Color(0.8, 0.8, 0.2) # Yellow-green
	elif value >= 40:
		target_color = Color(0.8, 0.6, 0.2) # Orange
	elif value >= 20:
		target_color = Color(0.8, 0.4, 0.2) # Orange-red
	else:
		target_color = Color(0.8, 0.2, 0.2) # Red
	
	# Create color transition
	var tween = create_tween()
	tween.tween_property(style, "bg_color", target_color, 0.5).set_ease(Tween.EASE_OUT)

func _update_percent_label(value: float):
	percent_label.text = "%d%%" % value 