extends Control

signal character_approved(character)
signal character_rejected(character)
signal exit_pressed(character)
signal remove_npc_pressed
signal camera_reset_requested

var current_character = null
var current_view = "main" # main, dialogue, inventory, or transcript
var has_spoken_to = {} # Dictionary to track characters we've spoken to

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
@onready var dialogue_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/DialoguePanel
@onready var inventory_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/InventoryPanel
@onready var transcript_panel = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels/TranscriptPanel
@onready var id_card = $PanelContainer/MarginContainer/VBoxContainer/MainContent/IDCard
@onready var action_buttons = $PanelContainer/MarginContainer/VBoxContainer/MainContent/ActionButtons

# Store character items
var character_items = {}

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
	print("DEBUG: Starting _ready")
	# Create the content panels if they don't exist
	if not has_node("PanelContainer/MarginContainer/VBoxContainer/MainContent/ContentPanels"):
		print("DEBUG: Creating content panels")
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
		dialogue_vbox.add_theme_constant_override("separation", 20) # Space between Q&A pairs
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
		inventory_grid.columns = 9 # Minecraft-style inventory width
		inventory_grid.add_theme_constant_override("h_separation", 4) # Add some spacing between slots
		inventory_grid.add_theme_constant_override("v_separation", 4)
		inventory_margin.add_child(inventory_grid)
		
		# Create inventory slots
		for i in range(27): # 3 rows of 9 slots
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
		transcript_image.custom_minimum_size = Vector2(660, 360) # Adjusted for margins
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
	
	# Connect action button signals with debug logging
	interrogate_button.pressed.connect(func():
		print("DEBUG: Interrogate button pressed")
		_switch_panel("dialogue")
	)
	inventory_button.pressed.connect(func():
		print("DEBUG: Inventory button pressed")
		_switch_panel("inventory")
	)
	transcript_button.pressed.connect(func():
		print("DEBUG: Transcript button pressed")
		_switch_panel("transcript")
	)
	
	# Hide all panels initially
	_hide_all_panels()
	
	print("DEBUG: Finished _ready")

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
	AudioManager.play_ui_click() # Play UI click when going back
	_switch_panel("main")

func _switch_panel(panel_name: String):
	print("DEBUG: Switching to panel:", panel_name)
	AudioManager.play_ui_click() # Play UI click when switching panels
	current_view = panel_name
	
	# Hide all panels first
	dialogue_panel.visible = false
	inventory_panel.visible = false
	transcript_panel.visible = false
	id_card.visible = false
	action_buttons.visible = false
	
	# Show the selected panel
	match panel_name:
		"main":
			print("DEBUG: Showing main panel")
			id_card.visible = true
			action_buttons.visible = true
		"dialogue":
			print("DEBUG: Showing dialogue panel")
			dialogue_panel.visible = true
			_show_dialogue_view()
		"inventory":
			print("DEBUG: Showing inventory panel")
			inventory_panel.visible = true
			_show_inventory_view()
		"transcript":
			print("DEBUG: Showing transcript panel")
			transcript_panel.visible = true
			_show_transcript_view()
	
	print("DEBUG: Panel switch complete")

func create_dialogue_entry(question: String, answer: String) -> VBoxContainer:
	var entry = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 10) # Reduced space between Q&A pairs
	
	# Question container with left alignment
	var question_margin = MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 20)
	question_margin.add_theme_constant_override("margin_right", 200) # Space on right for alignment
	
	var question_container = PanelContainer.new()
	var question_style = StyleBoxFlat.new()
	question_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	question_style.corner_radius_top_left = 15
	question_style.corner_radius_top_right = 15
	question_style.corner_radius_bottom_right = 15
	question_style.corner_radius_bottom_left = 0 # Sharp corner for chat bubble effect
	question_container.add_theme_stylebox_override("panel", question_style)
	
	var question_padding = MarginContainer.new()
	question_padding.add_theme_constant_override("margin_left", 15)
	question_padding.add_theme_constant_override("margin_right", 15)
	question_padding.add_theme_constant_override("margin_top", 10)
	question_padding.add_theme_constant_override("margin_bottom", 10)
	
	var question_label = Label.new()
	question_label.text = question
	question_label.custom_minimum_size = Vector2(200, 0) # Minimum width for question
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 16)
	
	question_padding.add_child(question_label)
	question_container.add_child(question_padding)
	question_margin.add_child(question_container)
	entry.add_child(question_margin)
	
	# Add minimal space between question and answer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5) # Reduced spacing
	entry.add_child(spacer)
	
	# Answer container with right alignment
	var answer_margin = MarginContainer.new()
	answer_margin.add_theme_constant_override("margin_left", 200) # Space on left for alignment
	answer_margin.add_theme_constant_override("margin_right", 20)
	
	var answer_container = PanelContainer.new()
	var answer_style = StyleBoxFlat.new()
	answer_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	answer_style.corner_radius_top_left = 15
	answer_style.corner_radius_top_right = 15
	answer_style.corner_radius_bottom_left = 15
	answer_style.corner_radius_bottom_right = 0 # Sharp corner for chat bubble effect
	answer_container.add_theme_stylebox_override("panel", answer_style)
	
	var answer_padding = MarginContainer.new()
	answer_padding.add_theme_constant_override("margin_left", 15)
	answer_padding.add_theme_constant_override("margin_right", 15)
	answer_padding.add_theme_constant_override("margin_top", 10)
	answer_padding.add_theme_constant_override("margin_bottom", 10)
	
	var answer_label = Label.new()
	answer_label.text = answer
	answer_label.custom_minimum_size = Vector2(200, 0) # Minimum width for answer
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
				"Hannah Scott": # Berkeley student pretending
					questions = [
						["Which dorm do you live in?", "Uh... Meier Hall? *nervously*"],
						["What's your favorite study spot?", "The... uh... Main Quad Library?"],
						["How often do you eat at Stern?", "Oh, I love Stern! Great... pizza."] # Stern doesn't serve pizza
					]
				"Sam Green": # Berkeley student pretending
					questions = [
						["What clubs are you involved in?", "The Stanford Entrepreneurship Club! We meet in... uh... Building 9."],
						["Which dining hall do you prefer?", "Definitely Manz dining!"], # Incorrect name for Manz Hall
						["Where's your next class?", "Over in the Engineering Center."] # Using generic name
					]
				"Tenzin Sherpa": # Berkeley student pretending
					questions = [
						["Can you direct me to Hoover Tower?", "Oh yeah, it's right next to the student union!"], # Wrong location
						["What's your favorite campus tradition?", "I love when we all run through the fountain before finals!"], # Mixed up traditions
						["Which year are you?", "Junior, started here right after COVID."] # Timeline might not match
					]
				"Kelvin Nguyen": # Actual Stanford student
					questions = [
						["Which dorm do you live in?", char_data["dorm"]],
						["What clubs are you involved in?", "I'm the SVSA President and also involved in the Stanford Sustainable Investing Group."],
						["What's your major?", "Computational Biology - just finished BIOE 214 last quarter."]
					]
				_: # Default Stanford student questions
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
	print("DEBUG: Showing inventory view")
	
	if not current_character:
		print("DEBUG: No current character")
		return
		
	current_view = "inventory"
	back_button.visible = true
	id_card.visible = false
	action_buttons.visible = false
	
	# Get the character's data
	var char_data = current_character.get_meta("character_data")
	if not char_data:
		print("DEBUG: No character data found")
		return
		
	print("DEBUG: Character data found for:", char_data["name"])
	
	# Get or generate items for this character
	var items = _get_character_items(char_data)
	print("DEBUG: Got items for character:", items)
	
	# Get the inventory grid
	var inventory_grid = inventory_panel.find_child("InventoryGrid", true, false)
	if not inventory_grid:
		print("DEBUG: Could not find InventoryGrid")
		return
	
	print("DEBUG: Found inventory grid with", inventory_grid.get_child_count(), "slots")
	
	# Create tooltip label if it doesn't exist
	var tooltip_label = inventory_panel.find_child("TooltipLabel", true, false)
	if not tooltip_label:
		tooltip_label = Label.new()
		tooltip_label.name = "TooltipLabel"
		tooltip_label.visible = false
		tooltip_label.add_theme_color_override("font_color", Color.WHITE)
		tooltip_label.add_theme_font_size_override("font_size", 16)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.4, 0.4, 1)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		tooltip_label.add_theme_stylebox_override("normal", style)
		inventory_panel.add_child(tooltip_label)
	
	# Clear existing items
	for slot in inventory_grid.get_children():
		# Clear any existing textures
		var existing_texture = slot.get_child(0) if slot.get_child_count() > 0 else null
		if existing_texture:
			slot.remove_child(existing_texture)
			existing_texture.queue_free()
	
	# Add items to the grid
	for i in range(items.size()):
		var slot = inventory_grid.get_child(i)
		if slot:
			var item_texture = TextureRect.new()
			var item_name = items[i]
			
			# Determine the path based on whether it's a Berkeley item
			var texture_path = "res://assets/backpack-items/"
			if item_name.begins_with("cal-"):
				texture_path += "berkeley/"
			texture_path += item_name + ".png"
			
			print("DEBUG: Loading texture from:", texture_path)
			
			# Load and set the texture
			var texture = load(texture_path)
			if texture:
				print("DEBUG: Successfully loaded texture for item:", item_name)
				item_texture.texture = texture
				item_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
				item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				item_texture.custom_minimum_size = Vector2(60, 60)
				
				# Add mouse enter/exit signals for tooltip
				item_texture.mouse_entered.connect(func():
					# Format the item name for display (remove hyphens and capitalize)
					var display_name = item_name.replace("-", " ").capitalize()
					tooltip_label.text = display_name
					tooltip_label.visible = true
					
					# Position tooltip above the item
					var item_pos = item_texture.global_position
					tooltip_label.position = Vector2(
						item_pos.x + (item_texture.size.x - tooltip_label.size.x) / 2,
						item_pos.y - tooltip_label.size.y - 5
					)
				)
				item_texture.mouse_exited.connect(func():
					tooltip_label.visible = false
				)
				
				slot.add_child(item_texture)
			else:
				print("DEBUG: Failed to load texture from:", texture_path)
	
	# Show the inventory panel
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
				var transcript_name = char_data["name"].replace(" ", "") # Remove spaces
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
	if current_character:
		# Re-enable input on the character before clearing reference
		current_character.input_pickable = true
		# Resume walking and ensure animation is playing
		if current_character.has_node("AnimatedSprite2D"):
			var sprite = current_character.get_node("AnimatedSprite2D")
			sprite.play("walk")
		current_character.resume_walking()
	current_character = null
	print("Inspection Panel: Hidden and character state restored")

func _on_exit_button_pressed():
	AudioManager.play_ui_click() # Play UI click when exiting
	if current_character:
		# Resume walking and ensure animation is playing
		if current_character.has_node("AnimatedSprite2D"):
			var sprite = current_character.get_node("AnimatedSprite2D")
			sprite.play("walk")
		current_character.resume_walking()
	exit_pressed.emit(current_character)
	visible = false

func _on_approve_button_pressed():
	if current_character:
		AudioManager.play_ui_click() # Play UI click when approving
		character_approved.emit(current_character)
		visible = false

func _on_reject_button_pressed():
	if current_character:
		AudioManager.play_ui_click() # Play UI click when rejecting
		# Play pop sound after a short delay to match the disappear animation
		await get_tree().create_timer(0.3).timeout
		AudioManager.play_pop()
		character_rejected.emit(current_character)
		visible = false

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
		_: return 1 # Default to first transcript if name not found

func _get_character_items(char_data: Dictionary) -> Array:
	# Check if we already have items for this character
	if character_items.has(char_data["name"]):
		return character_items[char_data["name"]]
	
	# Generate new items based on character type
	var is_berkeley = char_data["type"] == 1
	var items = get_node("/root/BackpackItemsManager").get_random_items_for_character(is_berkeley)
	
	# Store the items for this character
	character_items[char_data["name"]] = items
	
	return items
