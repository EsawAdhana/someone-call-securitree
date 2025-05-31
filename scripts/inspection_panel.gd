extends Control

signal character_approved(character)
signal character_rejected(character)
signal exit_pressed
signal remove_npc_pressed

var current_character = null
var current_view = "main"  # main, dialogue, inventory, or transcript
var has_spoken_to = {}  # Dictionary to track characters we've spoken to
var current_file_index = 0
var character_files = ["ID Card", "Criminal Record", "Academic History"]

# UI components
@onready var exit_button = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/ExitButton
@onready var dialog_label = $PanelContainer/MarginContainer/VBoxContainer/MainContent/MiddleSection/DialogueSection/DialogPanel/MarginContainer/DialogLabel
@onready var character_icon = $PanelContainer/MarginContainer/VBoxContainer/MainContent/LeftSection/NPCIcon/CharacterIcon
@onready var approve_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/ApproveButton
@onready var reject_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsSection/RejectButton
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/BackButton

# Action buttons
@onready var interrogate_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/InterrogateButton
@onready var inventory_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/InventoryButton
@onready var transcript_button = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons/TranscriptButton

# Content panels
@onready var dialogue_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/DialoguePanel
@onready var inventory_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/InventoryPanel
@onready var transcript_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/TranscriptPanel
@onready var id_card = $PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard
@onready var action_buttons = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons

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
	# Create the content panels if they don't exist
	if not has_node("PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels"):
		var content_panels = Control.new()
		content_panels.name = "ContentPanels"
		content_panels.size_flags_horizontal = Control.SIZE_FILL
		content_panels.size_flags_vertical = Control.SIZE_FILL
		$PanelContainer/MarginContainer/VBoxContainer/MainContent.add_child(content_panels)
		
		# Create DialoguePanel with centering container
		var dialogue_container = CenterContainer.new()
		dialogue_container.name = "DialogueContainer"
		dialogue_container.size_flags_horizontal = Control.SIZE_FILL
		dialogue_container.size_flags_vertical = Control.SIZE_FILL
		content_panels.add_child(dialogue_container)
		
		var dialogue = PanelContainer.new()
		dialogue.name = "DialoguePanel"
		dialogue.visible = false
		dialogue.custom_minimum_size = Vector2(700, 400)
		dialogue_container.add_child(dialogue)
		
		# Add dialogue content
		var dialogue_margin = MarginContainer.new()
		dialogue_margin.add_theme_constant_override("margin_left", 20)
		dialogue_margin.add_theme_constant_override("margin_right", 20)
		dialogue_margin.add_theme_constant_override("margin_top", 20)
		dialogue_margin.add_theme_constant_override("margin_bottom", 20)
		dialogue.add_child(dialogue_margin)
		
		var dialogue_scroll = ScrollContainer.new()
		dialogue_scroll.custom_minimum_size = Vector2(660, 360)
		dialogue_margin.add_child(dialogue_scroll)
		
		var dialogue_vbox = VBoxContainer.new()
		dialogue_vbox.add_theme_constant_override("separation", 20)  # Space between Q&A pairs
		dialogue_scroll.add_child(dialogue_vbox)
		
		# Store the VBoxContainer reference for adding dialogue entries
		dialogue_vbox.name = "DialogueVBox"
		
		# Create InventoryPanel with centering container
		var inventory_container = CenterContainer.new()
		inventory_container.name = "InventoryContainer"
		inventory_container.size_flags_horizontal = Control.SIZE_FILL
		inventory_container.size_flags_vertical = Control.SIZE_FILL
		content_panels.add_child(inventory_container)
		
		var inventory = PanelContainer.new()
		inventory.name = "InventoryPanel"
		inventory.visible = false
		inventory.custom_minimum_size = Vector2(700, 400)
		inventory_container.add_child(inventory)
		
		# Add inventory margin container
		var inventory_margin = MarginContainer.new()
		inventory_margin.add_theme_constant_override("margin_left", 20)
		inventory_margin.add_theme_constant_override("margin_right", 20)
		inventory_margin.add_theme_constant_override("margin_top", 20)
		inventory_margin.add_theme_constant_override("margin_bottom", 20)
		inventory.add_child(inventory_margin)
		
		# Add inventory grid
		var inventory_grid = GridContainer.new()
		inventory_grid.name = "InventoryGrid"
		inventory_grid.columns = 9  # Minecraft-style inventory width
		inventory_grid.add_theme_constant_override("h_separation", 4)  # Add some spacing between slots
		inventory_grid.add_theme_constant_override("v_separation", 4)
		inventory_margin.add_child(inventory_grid)
		
		# Create inventory slots
		for i in range(27):  # 3 rows of 9 slots
			var slot = PanelContainer.new()
			slot.custom_minimum_size = Vector2(64, 64)
			
			# Add a dark stylebox to make it look like a slot
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.1, 1)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.3, 0.3, 0.3, 1)
			slot.add_theme_stylebox_override("panel", style)
			
			inventory_grid.add_child(slot)
		
		# Create TranscriptPanel with centering container
		var transcript_container = CenterContainer.new()
		transcript_container.name = "TranscriptContainer"
		transcript_container.size_flags_horizontal = Control.SIZE_FILL
		transcript_container.size_flags_vertical = Control.SIZE_FILL
		content_panels.add_child(transcript_container)
		
		var transcript = PanelContainer.new()
		transcript.name = "TranscriptPanel"
		transcript.visible = false
		transcript.custom_minimum_size = Vector2(700, 400)
		transcript_container.add_child(transcript)
		
		# Add transcript margin container
		var transcript_margin = MarginContainer.new()
		transcript_margin.add_theme_constant_override("margin_left", 20)
		transcript_margin.add_theme_constant_override("margin_right", 20)
		transcript_margin.add_theme_constant_override("margin_top", 20)
		transcript_margin.add_theme_constant_override("margin_bottom", 20)
		transcript.add_child(transcript_margin)
		
		# Add transcript content
		var transcript_vbox = VBoxContainer.new()
		transcript_margin.add_child(transcript_vbox)
		
		var transcript_image = TextureRect.new()
		transcript_image.name = "TranscriptImage"
		transcript_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		transcript_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		transcript_image.custom_minimum_size = Vector2(660, 360)  # Adjusted for margins
		transcript_vbox.add_child(transcript_image)
		
		# Update the references
		dialogue_panel = dialogue
		inventory_panel = inventory
		transcript_panel = transcript
		
		# Print the node tree for debugging
		print("DEBUG: Node tree after setup:")
		print_node_tree(content_panels)
	
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

func _hide_all_panels():
	if dialogue_panel:
		dialogue_panel.visible = false
	
	if inventory_panel:
		inventory_panel.visible = false
	
	if transcript_panel:
		transcript_panel.visible = false

func _show_main_view():
	current_view = "main"
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
			_show_dialogue_view()
		"inventory":
			_show_inventory_view()
		"transcript":
			_show_transcript_view()

func create_dialogue_entry(question: String, answer: String) -> VBoxContainer:
	var entry = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)  # Reduced space between Q&A pairs
	
	# Question container with left alignment
	var question_margin = MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 20)
	question_margin.add_theme_constant_override("margin_right", 200)  # Space on right for alignment
	
	var question_container = PanelContainer.new()
	var question_style = StyleBoxFlat.new()
	question_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	question_style.corner_radius_top_left = 15
	question_style.corner_radius_top_right = 15
	question_style.corner_radius_bottom_right = 15
	question_style.corner_radius_bottom_left = 0  # Sharp corner for chat bubble effect
	question_container.add_theme_stylebox_override("panel", question_style)
	
	var question_padding = MarginContainer.new()
	question_padding.add_theme_constant_override("margin_left", 15)
	question_padding.add_theme_constant_override("margin_right", 15)
	question_padding.add_theme_constant_override("margin_top", 10)
	question_padding.add_theme_constant_override("margin_bottom", 10)
	
	var question_label = Label.new()
	question_label.text = question
	question_label.custom_minimum_size = Vector2(200, 0)  # Minimum width for question
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 16)
	
	question_padding.add_child(question_label)
	question_container.add_child(question_padding)
	question_margin.add_child(question_container)
	entry.add_child(question_margin)
	
	# Add minimal space between question and answer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)  # Reduced spacing
	entry.add_child(spacer)
	
	# Answer container with right alignment
	var answer_margin = MarginContainer.new()
	answer_margin.add_theme_constant_override("margin_left", 200)  # Space on left for alignment
	answer_margin.add_theme_constant_override("margin_right", 20)
	
	var answer_container = PanelContainer.new()
	var answer_style = StyleBoxFlat.new()
	answer_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	answer_style.corner_radius_top_left = 15
	answer_style.corner_radius_top_right = 15
	answer_style.corner_radius_bottom_left = 15
	answer_style.corner_radius_bottom_right = 0  # Sharp corner for chat bubble effect
	answer_container.add_theme_stylebox_override("panel", answer_style)
	
	var answer_padding = MarginContainer.new()
	answer_padding.add_theme_constant_override("margin_left", 15)
	answer_padding.add_theme_constant_override("margin_right", 15)
	answer_padding.add_theme_constant_override("margin_top", 10)
	answer_padding.add_theme_constant_override("margin_bottom", 10)
	
	var answer_label = Label.new()
	answer_label.text = answer
	answer_label.custom_minimum_size = Vector2(200, 0)  # Minimum width for answer
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	answer_label.add_theme_font_size_override("font_size", 16)
	
	answer_padding.add_child(answer_label)
	answer_container.add_child(answer_padding)
	answer_margin.add_child(answer_container)
	entry.add_child(answer_margin)
	
	return entry

func _show_dialogue_view():
	if not current_character:
		return
		
	current_view = "dialogue"
	back_button.visible = true
	id_card.visible = false
	action_buttons.visible = false
	
	var char_data = current_character.get_meta("character_data")
	if char_data:
		# Find the dialogue VBox
		var dialogue_vbox = dialogue_panel.find_child("DialogueVBox", true, false)
		if dialogue_vbox:
			# Clear existing dialogue
			for child in dialogue_vbox.get_children():
				child.queue_free()
			
			# Create questions based on character
			var questions = []
			
			# Handle specific Berkeley students with revealing dialogue
			match char_data["name"]:
				"Hannah Scott":  # Berkeley student pretending
					questions = [
						["Which dorm do you live in?", "Uh... Meier Hall? *nervously*"],
						["What's your favorite study spot?", "The... uh... Main Quad Library?"],
						["How often do you eat at Stern?", "Oh, I love Stern! Great... pizza."]  # Stern doesn't serve pizza
					]
				"Sam Green":  # Berkeley student pretending
					questions = [
						["What clubs are you involved in?", "The Stanford Entrepreneurship Club! We meet in... uh... Building 9."],
						["Which dining hall do you prefer?", "Definitely Manz dining!"],  # Incorrect name for Manz Hall
						["Where's your next class?", "Over in the Engineering Center."]  # Using generic name
					]
				"Tenzin Sherpa":  # Berkeley student pretending
					questions = [
						["Can you direct me to Hoover Tower?", "Oh yeah, it's right next to the student union!"],  # Wrong location
						["What's your favorite campus tradition?", "I love when we all run through the fountain before finals!"],  # Mixed up traditions
						["Which year are you?", "Junior, started here right after COVID."]  # Timeline might not match
					]
				"Kelvin Nguyen":  # Actual Stanford student
					questions = [
						["Which dorm do you live in?", char_data["dorm"]],
						["What clubs are you involved in?", "I'm the SVSA President and also involved in the Stanford Sustainable Investing Group."],
						["What's your major?", "Computational Biology - just finished BIOE 214 last quarter."]
					]
				_:  # Default Stanford student questions
					var clubs_response = ", ".join(char_data["clubs"]) if char_data.get("clubs", []).size() > 0 else "Just focusing on classes this quarter."
					questions = [
						["Which dorm do you live in?", char_data["dorm"]],
						["What's your major?", char_data["major"]],
						["What clubs are you involved in?", clubs_response]
					]
			
			# Create and add each dialogue entry
			for qa in questions:
				var entry = create_dialogue_entry(qa[0], qa[1])
				dialogue_vbox.add_child(entry)
	
	dialogue_panel.visible = true

func _show_inventory_view():
	if not current_character:
		return
		
	current_view = "inventory"
	back_button.visible = true
	id_card.visible = false
	action_buttons.visible = false
	
	# Show the inventory panel with the grid
	inventory_panel.visible = true

func _show_transcript_view():
	if not current_character:
		return
		
	current_view = "transcript"
	back_button.visible = true
	id_card.visible = false
	action_buttons.visible = false
	
	var char_data = current_character.get_meta("character_data")
	if char_data:
		print("DEBUG: Loading transcript for character: ", char_data["name"])
		if transcript_panel:
			# Try to find the image node using different methods
			var image = transcript_panel.get_node_or_null("MarginContainer/VBoxContainer/TranscriptImage")
			if not image:
				print("DEBUG: Trying alternate path for transcript image")
				image = transcript_panel.find_child("TranscriptImage", true, false)
			
			if image:
				var transcript_number = get_transcript_number(char_data["name"])
				var transcript_name = char_data["name"].replace(" ", "")  # Remove spaces
				var transcript_path = "res://assets/L1_transcripts/" + transcript_name + "_Transcript_" + str(transcript_number) + ".png"
				print("DEBUG: Attempting to load transcript from: ", transcript_path)
				var transcript_texture = load(transcript_path)
				if transcript_texture:
					image.texture = transcript_texture
					print("DEBUG: Transcript texture loaded successfully")
				else:
					print("DEBUG: Failed to load transcript texture from: ", transcript_path)
					# Print the directory contents to debug
					var dir = DirAccess.open("res://assets/L1_transcripts")
					if dir:
						print("DEBUG: Contents of L1_transcripts directory:")
						dir.list_dir_begin()
						var file_name = dir.get_next()
						while file_name != "":
							print("Found file: ", file_name)
							file_name = dir.get_next()
			else:
				print("DEBUG: Transcript image node not found")
				print("DEBUG: Available nodes in transcript_panel: ", transcript_panel.get_children())
		else:
			print("DEBUG: Transcript panel not found")
	
	if transcript_panel:
		transcript_panel.visible = true

# Helper function to print the node tree for debugging
func print_node_tree(node: Node, indent: String = ""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_tree(child, indent + "  ")

func show_character_info(character):
	print("INSPECTION: Showing character info for:", character.variant_name)
	
	if character == null:
		push_error("INSPECTION: Null character passed to show_character_info")
		return
		
	current_character = character
	
	# Make the panel visible
	visible = true
	
	# Show the main view
	_show_main_view()
	
	# Pause the character's movement
	character.is_walking = false
	if character.has_node("AnimatedSprite2D"):
		character.get_node("AnimatedSprite2D").pause()
	character.input_pickable = false
	
	# Get the character's data
	var char_data = character.get_meta("character_data")
	if not char_data:
		push_error("INSPECTION: No character data found in metadata")
		return
	
	print("INSPECTION: Character data:", char_data)
	
	# Update the ID card section - only show name
	var id_label = $PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard/VBoxContainer/Label
	id_label.text = char_data["name"]
	
	# Load the L1ID image based on character name
	var id_image = $PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard/VBoxContainer/IDPlaceholder
	var id_mapping = {
		"Alex Kim": "AlexKim_ID_1",
		"Jessica Li": "JessicaLi_ID_2",
		"Ryan Field": "RyanField_ID_3",
		"Maya Patel": "MayaPatel_ID_4",
		"Daniel Chen": "DanielChen_ID_5",
		"Sibana Adhana": "SibanaAdhana_ID_6",
		"Kelvin Nguyen": "KelvinNguyen_ID_7",
		"Hannah Scott": "HannahScott_ID_8",
		"Sam Green": "SamGreen_ID_9",
		"Tenzin Sherpa": "TenzinSherpa_ID_10"
	}
	
	var id_filename = id_mapping.get(char_data["name"], "id_card_placeholder")
	var id_texture = load("res://assets/L1_id/" + id_filename + ".PNG")
	if id_texture:
		id_image.texture = id_texture
	else:
		print("INSPECTION: Failed to load ID texture for:", id_filename)
	
	print("INSPECTION: Panel updated and shown")

func hide_panel():
	visible = false
	current_character = null
	print("Inspection Panel: Hidden")

func _on_exit_button_pressed():
	print("Inspection Panel: Exit pressed")
	exit_pressed.emit()
	
	if current_character and is_instance_valid(current_character):
		# Add a small delay before resuming walking
		await get_tree().create_timer(0.1).timeout
		
		print("Inspection Panel: Resuming character walking after exit")
		# Double check the character is still valid after the delay
		if is_instance_valid(current_character):
			current_character.resume_walking()
		current_character = null
	
	hide_panel()

func _on_approve_button_pressed():
	print("Inspection Panel: APPROVE button pressed!")
	
	if current_character and is_instance_valid(current_character):
		print("Inspection Panel: Character approved:", current_character.variant_name)
		
		# Store character reference in case it gets cleared
		var character_ref = current_character
		
		# Hide the panel before resuming walking
		hide_panel()
		
		# Add a small delay before resuming walking
		await get_tree().create_timer(0.1).timeout
		
		# Make the character resume walking FIRST - but check if still valid
		if is_instance_valid(character_ref):
			print("Inspection Panel: Making character resume walking...")
			character_ref.resume_walking()
			print("Inspection Panel: Character resume_walking() called")
		else:
			print("Inspection Panel: Character no longer valid, skipping resume_walking")
		
		# Emit signal AFTER resuming walking (only if character is still valid)
		if is_instance_valid(character_ref):
			print("Inspection Panel: Emitting character_approved signal")
			character_approved.emit(character_ref)
		
		# Clear the current character reference
		current_character = null

func _on_reject_button_pressed():
	print("Inspection Panel: REJECT button pressed!")
	
	if current_character and is_instance_valid(current_character):
		print("Inspection Panel: Character rejected:", current_character.variant_name)
		
		# Store character reference in case it gets cleared
		var character_ref = current_character
		
		# Hide the panel before making character disappear
		hide_panel()
		
		# Make the character disappear FIRST - but check if still valid
		if is_instance_valid(character_ref):
			print("Inspection Panel: Making character disappear...")
			character_ref.disappear()
			print("Inspection Panel: Character disappear() called")
		else:
			print("Inspection Panel: Character no longer valid, skipping disappear")
		
		# Emit signal AFTER disappear (only if character is still valid)
		if is_instance_valid(character_ref):
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