extends Control

signal character_approved(character)
signal character_rejected(character)
signal exit_pressed(character)
signal remove_npc_pressed
signal camera_reset_requested

var current_character = null
var has_spoken_to = {}  # Dictionary to track characters we've spoken to

# UI components
@onready var exit_button = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/ExitButton
@onready var approve_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/ApproveButton
@onready var reject_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/RejectButton
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/BackButton

# Action buttons
@onready var interrogate_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/InterrogateButton
@onready var inventory_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/InventoryButton
@onready var transcript_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/TranscriptButton

# Content panels
@onready var id_card = $PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard
@onready var action_buttons = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons
@onready var dialogue_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/DialoguePanel
@onready var inventory_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/InventoryPanel
@onready var transcript_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/TranscriptPanel
@onready var transcript_image = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/TranscriptPanel/TranscriptImage
@onready var dialogue_label = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/DialoguePanel/Label

# A list of possible dialogues
var stanford_dialogues = [
	"Hi there! I'm just passing through to the library.",
	"Go Cardinal! I've got a final to study for.",
	"I'm late for my CS lecture, can I go through?",
	"Beautiful day on campus, isn't it?",
	"I'm meeting friends at the Oval for lunch."
]

var berkeley_dialogues = [
	"Hey, just visiting to check out the campus.",
	"Go Bears! I'm here for the game.",
	"I heard there's a great research symposium today.",
	"Stanford's campus is nice, but Berkeley is better.",
	"I'm meeting my Stanford friend for coffee."
]

func _ready():
	# Hide the panel initially
	visible = false
	
	# Disconnect existing connections if any
	if reject_button.pressed.is_connected(_on_reject_button_pressed):
		reject_button.pressed.disconnect(_on_reject_button_pressed)
	
	if exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.disconnect(_on_exit_button_pressed)
	
	# Connect button signals
	approve_button.pressed.connect(func():
		print("DEBUG: Direct approve button press triggered")
		_on_approve_button_pressed()
	)
	reject_button.pressed.connect(func():
		print("DEBUG: Direct reject button press triggered")
		_on_reject_button_pressed()
	)
	exit_button.pressed.connect(_on_exit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect action button signals
	interrogate_button.pressed.connect(func(): _switch_panel("dialogue"))
	inventory_button.pressed.connect(func(): _switch_panel("inventory"))
	transcript_button.pressed.connect(func(): _switch_panel("transcript"))
	
	# Hide all panels initially
	_hide_all_panels()
	
	print("Inspection Panel: All button signals connected in _ready")

func _hide_all_panels():
	dialogue_panel.visible = false
	inventory_panel.visible = false
	transcript_panel.visible = false

func _show_main_view():
	back_button.visible = false
	id_card.visible = true
	action_buttons.visible = true
	_hide_all_panels()

func _show_content_view():
	back_button.visible = true
	id_card.visible = false
	action_buttons.visible = false

func _on_back_button_pressed():
	_show_main_view()

func _switch_panel(panel_name: String):
	_show_content_view()
	_hide_all_panels()
	
	match panel_name:
		"dialogue":
			dialogue_panel.visible = true
			if current_character:
				var character_type_name = "Stanford" if current_character.character_type == 0 else "Berkeley"
				if character_type_name == "Stanford":
					dialogue_label.text = "\"" + stanford_dialogues[randi() % stanford_dialogues.size()] + "\""
				else:
					dialogue_label.text = "\"" + berkeley_dialogues[randi() % berkeley_dialogues.size()] + "\""
		"inventory":
			inventory_panel.visible = true
		"transcript":
			transcript_panel.visible = true
			if current_character:
				# Load the transcript image based on the character's name
				var transcript_path = "res://assets/L1_transcripts/" + current_character.variant_name.replace(" ", "") + "_Transcript_" + str(get_transcript_number(current_character.variant_name)) + ".png"
				var transcript_texture = load(transcript_path)
				if transcript_texture:
					transcript_image.texture = transcript_texture

func show_character_info(character):
	if character == null:
		return
		
	current_character = character
	
	# Pause the character's movement
	character.is_walking = false
	character.input_pickable = false
	
	# Get the character's sprite frame and set it as the portrait
	if character.has_node("AnimatedSprite2D"):
		var sprite = character.get_node("AnimatedSprite2D")
		if sprite and sprite.sprite_frames:
			var frame_texture = sprite.sprite_frames.get_frame_texture("walk", 0)
			$PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard/VBoxContainer/IDPlaceholder.texture = frame_texture
	
	# Load the L1ID image if available
	if character.l1_id != "":
		var id_texture = load("res://assets/L1_id/" + character.l1_id + ".PNG")
		if id_texture:
			$PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard/VBoxContainer/IDPlaceholder.texture = id_texture
	
	# Show the panel
	visible = true
	_show_main_view()  # Start with main view
	print("Inspection Panel: Now displaying character info for", character.variant_name)

func hide_panel():
	visible = false
	if current_character:
		# Re-enable input on the character before clearing reference
		current_character.input_pickable = true
	current_character = null
	print("Inspection Panel: Hidden")

func _on_exit_button_pressed():
	print("Inspection Panel: Exit pressed")
	
	if current_character:
		print("Inspection Panel: Triggering walk resumption")
		# First resume walking
		current_character.resume_walking()
		# Then emit signals
		exit_pressed.emit(current_character)
		camera_reset_requested.emit()  # Request camera reset
		print("Inspection Panel: Exit signal emitted for character")
	
	# Hide panel and clear reference
	hide_panel()

func _on_approve_button_pressed():
	print("Inspection Panel: APPROVE button pressed!")
	
	if current_character:
		print("Inspection Panel: Character approved:", current_character.variant_name)
		
		# Store character reference in case it gets cleared
		var character_ref = current_character
		
		# Hide the panel before resuming walking
		hide_panel()
		
		# Add a small delay before resuming walking
		await get_tree().create_timer(0.1).timeout
		
		# Make the character resume walking FIRST
		print("Inspection Panel: Making character resume walking...")
		character_ref.resume_walking()
		print("Inspection Panel: Character resume_walking() called")
		
		# Emit signal AFTER resuming walking
		print("Inspection Panel: Emitting character_approved signal")
		character_approved.emit(character_ref)
		
		# Clear the current character reference
		current_character = null

func _on_reject_button_pressed():
	print("Inspection Panel: REJECT button pressed!")
	
	if current_character:
		print("Inspection Panel: Character rejected:", current_character.variant_name)
		
		# Store character reference in case it gets cleared
		var character_ref = current_character
		
		# Hide the panel before making character disappear
		hide_panel()
		
		# Make the character disappear FIRST
		print("Inspection Panel: Making character disappear...")
		character_ref.disappear()
		print("Inspection Panel: Character disappear() called")
		
		# Emit signal AFTER disappear
		print("Inspection Panel: Emitting character_rejected signal")
		character_rejected.emit(character_ref)
		
		# Clear the current character reference
		current_character = null

func get_random_stanford_major():
	var majors = ["Computer Science", "Engineering", "Physics", "Economics", "Biology", "Psychology"]
	return majors[randi() % majors.size()]

func get_random_berkeley_major():
	var majors = ["EECS", "Business", "Chemistry", "Political Science", "Mathematics", "Media Studies"]
	return majors[randi() % majors.size()]

# Helper function to get transcript number based on character name
func get_transcript_number(character_name: String) -> int:
	match character_name:
		"Alex Kim": return 1
		"Jessica Li": return 2
		"Ryan Field": return 3
		"Maya Patel": return 4
		"Daniel Chen": return 5
		"Sibana Adhana": return 6
		"Kelvin Nguyen": return 7
		"Hannah Scott": return 8
		"Sam Green": return 9
		"Tenzin Sherpa": return 10
		_: return 1  # Default to first transcript if name not found