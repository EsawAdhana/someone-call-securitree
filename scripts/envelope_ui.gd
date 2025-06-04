extends Control

@onready var envelope_button = $EnvelopeButton
@onready var message_panel = $MessagePanel
@onready var message_label = $MessagePanel/MarginContainer/VBoxContainer/Message
@onready var close_button = $MessagePanel/MarginContainer/VBoxContainer/CloseButton

func _ready():
	print("ENVELOPE: EnvelopeUI _ready() called")
	
	# Connect button signals
	envelope_button.pressed.connect(_on_envelope_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Make sure message panel is hidden initially
	message_panel.visible = false
	
	# Set up the message content
	setup_message_content()
	
	# Set up proper centering for the message panel
	call_deferred("_setup_message_panel_centering")
	
	print("ENVELOPE: EnvelopeUI setup completed - Size:", size, "Position:", position)
	print("ENVELOPE: Envelope button size:", envelope_button.size)

func _setup_message_panel_centering():
	# Set the message panel to use global coordinates and center on viewport
	if message_panel:
		# Set anchors to center but use global positioning
		message_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		message_panel.anchor_left = 0.0
		message_panel.anchor_right = 0.0
		message_panel.anchor_top = 0.0
		message_panel.anchor_bottom = 0.0
		
		# Set a fixed size - smaller landscape rectangle
		var panel_size = Vector2(500, 180)
		message_panel.size = panel_size
		
		print("ENVELOPE: Message panel centering setup completed")

func _center_message_panel_on_viewport():
	if message_panel:
		# Get the viewport size
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Calculate center position
		var center_pos = (viewport_size - message_panel.size) / 2
		
		# Set global position
		message_panel.global_position = center_pos
		
		print("ENVELOPE: Message panel centered at:", center_pos, "Viewport size:", viewport_size)

func setup_message_content():
	if message_label:
		var current_level = LevelManager.get_current_level()
		var location_name = LevelManager.get_location_for_level(current_level)
		
		# Set different messages based on the location
		match location_name:
			"FloMoArea":
				message_label.text = "📧 SECURITY ALERT\n\nWe've detected unusual activity in the Florence Moore dormitory area. Be extra vigilant when screening individuals in this location. Some suspicious characters may be attempting to blend in with students.\n\n- Campus Security"
			"Y2E2Area":
				message_label.text = "📧 INTELLIGENCE BRIEFING\n\nReports indicate that Berkeley infiltrators have been spotted near the Y2E2 building. They may be posing as engineering students. Pay close attention to their technical knowledge and campus familiarity.\n\n- Stanford Intelligence"
			"GreenLibraryArea":
				message_label.text = "📧 URGENT NOTICE\n\nThe Green Library has been a hotspot for suspicious activity. Some individuals may be using fake student IDs or borrowed library cards. Verify their knowledge of Stanford's academic programs carefully.\n\n- Library Security"
			"StadiumArea":
				message_label.text = "📧 GAME DAY SECURITY\n\nWith increased foot traffic around the stadium, enemy agents may try to infiltrate during events. Look for individuals who seem unfamiliar with Stanford sports traditions or campus culture.\n\n- Athletic Department Security"
			_:
				message_label.text = "📧 GENERAL SECURITY ALERT\n\nRemain vigilant at all times. Berkeley agents may be attempting to infiltrate our campus. Trust your instincts and thoroughly screen all individuals.\n\n- Campus Security"

func _on_envelope_button_pressed():
	print("ENVELOPE: Envelope button pressed!")
	
	# Update message content for current location
	setup_message_content()
	
	# Center the message panel on the viewport before showing it
	_center_message_panel_on_viewport()
	
	# Show the message panel
	message_panel.visible = true
	
	# Play UI sound effect
	AudioManager.play_ui_click()
	
	# Mark the envelope as read in the manager
	EnvelopeManager.mark_envelope_as_read()

func _on_close_button_pressed():
	print("ENVELOPE: Close button pressed!")
	message_panel.visible = false
	
	# Play UI sound effect
	AudioManager.play_ui_click()