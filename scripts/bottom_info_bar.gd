extends Control

@onready var manifesto_section = $PanelContainer/MarginContainer/VBoxContainer/InfoSections/ManifestoSection

func _ready():
	print("BOTTOM_INFO_BAR: Initialized")

func _on_manifesto_close_button_pressed():
	print("BOTTOM_INFO_BAR: Manifesto close button pressed")
	
	# Hide the manifesto section
	if manifesto_section:
		manifesto_section.visible = false
		print("BOTTOM_INFO_BAR: Manifesto section hidden")
		
		# Play UI sound
		AudioManager.play_ui_click()
	else:
		print("BOTTOM_INFO_BAR: ERROR - Could not find manifesto section")

func show_manifesto():
	# Public method to show the manifesto again if needed
	if manifesto_section:
		manifesto_section.visible = true
		print("BOTTOM_INFO_BAR: Manifesto section shown")

func hide_manifesto():
	# Public method to hide the manifesto
	if manifesto_section:
		manifesto_section.visible = false
		print("BOTTOM_INFO_BAR: Manifesto section hidden") 