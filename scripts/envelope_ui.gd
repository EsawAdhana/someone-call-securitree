extends Control

@onready var envelope_button = $EnvelopeButton
@onready var message_panel = $MessagePanel
@onready var close_button = $MessagePanel/MarginContainer/VBoxContainer/CloseButton

func _ready():
	# Connect button signals
	envelope_button.pressed.connect(_on_envelope_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Make sure message panel is hidden initially
	message_panel.visible = false

func _on_envelope_button_pressed():
	message_panel.visible = true
	# Mark the envelope as read in the manager
	EnvelopeManager.mark_envelope_as_read()

func _on_close_button_pressed():
	message_panel.visible = false