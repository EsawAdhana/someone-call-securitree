extends Control

signal morale_depleted

# Morale bar reference
@onready var morale_bar = $PanelContainer/MarginContainer/VBoxContainer/MoraleProgressBar

# Morale settings
var max_morale = 100.0
var current_morale = 100.0
var morale_depletion_rate = {
	"reject_stanford": 15.0,  # Penalty for rejecting a Stanford student
	"accept_berkeley": 10.0   # Penalty for accepting a Berkeley student
}

func _ready():
	# Initialize the morale bar
	morale_bar.max_value = max_morale
	morale_bar.value = current_morale

# Public method to decrease morale
func decrease_morale(action_type):
	if action_type in morale_depletion_rate:
		current_morale -= morale_depletion_rate[action_type]
		current_morale = max(0, current_morale)  # Ensure morale doesn't go below 0
		update_morale_display()
		
		# Check if morale has been depleted
		if current_morale <= 0:
			morale_depleted.emit()

# Public method to increase morale (if ever needed)
func increase_morale(amount):
	current_morale += amount
	current_morale = min(current_morale, max_morale)  # Ensure morale doesn't exceed max
	update_morale_display()

# Update the visual display of the morale bar
func update_morale_display():
	# Animate the morale bar
	var tween = create_tween()
	tween.tween_property(morale_bar, "value", current_morale, 0.5).set_ease(Tween.EASE_OUT)
	
	# Change color based on morale level
	if current_morale < 25:
		morale_bar.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	elif current_morale < 50:
		morale_bar.add_theme_color_override("font_color", Color(0.8, 0.7, 0.2))
	else:
		morale_bar.remove_theme_color_override("font_color") 