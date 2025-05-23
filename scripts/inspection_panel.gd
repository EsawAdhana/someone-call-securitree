extends Control

signal character_approved(character)
signal character_rejected(character)
signal exit_pressed
signal remove_npc_pressed

var current_character = null
var has_spoken_to = {}  # Dictionary to track characters we've spoken to
var current_file_index = 0
var character_files = ["ID Card", "Criminal Record", "Academic History"]

# UI components
@onready var exit_button = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/ExitButton
@onready var dialog_label = $PanelContainer/MarginContainer/VBoxContainer/MainContent/MiddleSection/DialogueSection/DialogPanel/MarginContainer/DialogLabel
@onready var character_icon = $PanelContainer/MarginContainer/VBoxContainer/MainContent/LeftSection/NPCIcon/CharacterIcon
@onready var approve_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/ApproveButton
@onready var reject_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/RejectButton

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
	if approve_button.pressed.is_connected(_on_approve_button_pressed):
		approve_button.pressed.disconnect(_on_approve_button_pressed)
		
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
	
	print("Inspection Panel: All button signals connected in _ready")

func show_character_info(character):
	if character == null:
		return
		
	current_character = character
	
	# Pause the character's movement - this should already be paused in character's click handler
	# But we'll set it again to be sure
	character.is_walking = false
	
	# Display character type info for debugging purposes
	var character_type_name = "Stanford" if character.character_type == 0 else "Berkeley"
	print("Inspection Panel: Showing character info for %s - Type: %s" % [character.variant_name, character_type_name])
	
	# Set dialogue based on character type
	if character.character_type == 0:  # Stanford
		dialog_label.text = "\"" + stanford_dialogues[randi() % stanford_dialogues.size()] + "\""
	else:  # Berkeley
		dialog_label.text = "\"" + berkeley_dialogues[randi() % berkeley_dialogues.size()] + "\""
	
	# Set the character icon
	if character.character_type == 0:
		character_icon.modulate = Color(0.8, 0, 0)  # Stanford red
	else:
		character_icon.modulate = Color(0, 0, 0.8)  # Berkeley blue
	
	# Check if we've spoken to this character before
	var character_id = character.get_instance_id()
	has_spoken_to[character_id] = true
	
	# Show the panel
	visible = true
	print("Inspection Panel: Now displaying character info for", character.variant_name)

func hide_panel():
	visible = false
	current_character = null
	print("Inspection Panel: Hidden")

func _on_exit_button_pressed():
	print("Inspection Panel: Exit pressed")
	exit_pressed.emit()
	
	if current_character:
		# Add a small delay before resuming walking
		await get_tree().create_timer(0.1).timeout
		
		print("Inspection Panel: Resuming character walking after exit")
		current_character.resume_walking()
		current_character = null
	
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
