extends Control

@onready var time_label = $Panel/TimeLabel

func _ready():
	# Connect to GameManager's time_updated signal
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.time_updated.connect(_on_time_updated)
		# Update with initial time
		_on_time_updated(game_manager.get_current_time())

func _on_time_updated(time_data):
	# Format minutes to always show two digits
	var minutes_str = str(time_data.minute).pad_zeros(2)
	# Update the time label
	time_label.text = "%d:%s %s" % [time_data.hour, minutes_str, time_data.am_pm]