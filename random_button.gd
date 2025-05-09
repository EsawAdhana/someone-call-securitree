# random_button.gd
extends Node2D

var time_remaining = 3

func _ready():
	# Make button visually distinct and larger
	$Button.text = "CLICK ME!"
	$Button.add_theme_color_override("font_color", Color(1, 0, 0))  # Red text
	$Button.modulate = Color(1, 1, 0)  # Yellow button
	
	# Make the button bigger
	$Button.custom_minimum_size = Vector2(200, 100)  # Increase button size
	$Button.size = Vector2(200, 100)
	
	# Add a timer for countdown
	var timer = Timer.new()
	timer.wait_time = 0.1  # Update 10 times per second
	timer.connect("timeout", Callable(self, "_on_timer_tick"))
	add_child(timer)
	timer.start()
	
	# Connect the button press
	$Button.connect("pressed", Callable(self, "_on_button_pressed"))

func _process(delta):
	# Decrease time remaining
	time_remaining -= delta
	if time_remaining <= 0:
		_on_timer_expired()

func _on_timer_tick():
	# Update the button text with countdown
	$Button.text = "CLICK ME!\n%.1f sec" % time_remaining

func _on_button_pressed():
	print("Button pressed!")
	Game.on_button_clicked()
	queue_free()
	
func _on_timer_expired():
	print("Time expired!")
	Game.on_button_timeout()
	queue_free()
