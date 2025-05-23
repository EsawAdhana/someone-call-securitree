extends Control

# UI references
@onready var stats_label = $PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var restart_button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton

# Game state
var days_lasted = 1

func _ready():
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Initially hide the screen
	visible = false

# Set the days lasted and update the stats label
func set_days_lasted(days):
	days_lasted = days
	stats_label.text = "You lasted " + str(days_lasted) + " days as a Stanford security guard."

# Show the game over screen
func show_game_over(days):
	set_days_lasted(days)
	visible = true

func _on_restart_button_pressed():
	# Restart the game
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit() 