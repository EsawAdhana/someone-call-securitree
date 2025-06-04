extends Control

signal dialogue_completed

# UI References
@onready var dialogue_text: RichTextLabel = $DialogueContainer/DialoguePanel/HBoxContainer/TextContainer/DialogueText
@onready var continue_prompt: Label = $DialogueContainer/DialoguePanel/HBoxContainer/TextContainer/ContinuePrompt
@onready var typewriter_timer: Timer = $TypewriterTimer
@onready var name_label: Label = $DialogueContainer/DialoguePanel/HBoxContainer/TextContainer/NameLabel

# Typewriter effect variables
var full_text: String = ""
var current_text: String = ""
var char_index: int = 0
var is_typing: bool = false
var can_continue: bool = false
var text_tokens: Array = [] # Store processed text tokens for proper BBCode handling
var token_index: int = 0

# Multi-page dialogue system
var dialogue_pages: Array = []
var current_page: int = 0
var total_pages: int = 0

# Tutorial dialogue for the first location (FloMo)
var tutorial_dialogue = {
	"name": "Chief Security Officer Martinez",
	"text": "Welcome to your first day, Agent. Here on the [color=red]Securi-Tree[/color] team, we need you to keep order by [color=red]accepting Stanford students[/color] and [color=blue]rejecting Berkeley students[/color].\n\nBerkeley students are sly, but they aren't too bright. Investigate their [color=orange]dialogue[/color], [color=orange]inventory[/color], and [color=orange]transcripts[/color], and keep our campus bear-free. You're our last hope."
}

# Performance-based dialogue templates
var performance_dialogues = {
	"excellent": {
		"adjectives": ["Outstanding work", "Exceptional performance", "Stellar job", "Magnificent execution"],
		"compliments": [
			"Your vigilance is exactly what Stanford needs!",
			"The campus has never been more secure!",
			"You're setting the gold standard for security!",
			"Berkeley doesn't stand a chance against you!",
			"Your dedication to Stanford is inspiring!"
		],
		"closing": ["Keep up the excellent work!", "Stanford is proud of you!", "Continue this outstanding performance!"]
	},
	"good": {
		"adjectives": ["Good work", "Solid performance", "Nice job", "Well done"],
		"compliments": [
			"You're maintaining good campus security.",
			"Your efforts are keeping Stanford safe.",
			"The students appreciate your diligence.",
			"You're handling the Berkeley threat well.",
			"Your training is paying off!"
		],
		"closing": ["Stay focused, Agent!", "Keep it up!", "Stanford counts on you!"]
	},
	"struggling": {
		"adjectives": ["Agent, we need to talk", "This is concerning", "I'm worried about you", "Focus up, Agent"],
		"warnings": [
			"Campus morale is dropping due to security breaches.",
			"Berkeley agents are getting through our defenses.",
			"Students are starting to lose faith in our security.",
			"We're seeing too many infiltrators on campus.",
			"The situation is becoming critical."
		],
		"encouragement": [
			"But I believe you can turn this around!",
			"Remember your training and stay vigilant!",
			"Focus on the details - that's how we catch them!",
			"Don't let Berkeley win this battle!"
		]
	},
	"critical": {
		"adjectives": ["URGENT - Critical situation", "Red alert, Agent", "Emergency briefing", "Crisis mode activated"],
		"warnings": [
			"Campus morale is at dangerous levels!",
			"Berkeley is taking over our campus!",
			"Students are fleeing - they don't feel safe!",
			"Our security reputation is in ruins!",
			"This could be the end of Stanford as we know it!"
		],
		"final_push": [
			"This might be your last chance to save Stanford!",
			"Everything depends on your next actions!",
			"The fate of the Cardinal rests in your hands!",
			"Don't let Berkeley claim victory!"
		]
	}
}

# Location-specific context for non-tutorial areas
var location_contexts = {
	"Y2E2Area": "the Y2E2 engineering building",
	"GreenLibraryArea": "Green Library",
	"StadiumArea": "Stanford Stadium",
	"HooverTowerArea": "Hoover Tower",
	"MainQuadArea": "the Main Quad and MemChu",
	"GSBArea": "the Graduate School of Business",
	"MeyerGreenArea": "Meyer Green",
	"TresidderArea": "Tresidder Student Center",
	"FarrillagaArea": "Farrillaga Family Student Housing",
	"CoDaArea": "the CoDa building",
	"CantorArea": "Cantor Arts Center"
}

# Character names for variety
var security_officers = [
	"Chief Security Officer Martinez",
	"Intelligence Director Chen", 
	"Security Coordinator Williams",
	"Operations Commander Davis",
	"Division Head Wilson",
	"Security Chief Johnson"
]

func _ready():
	# Initially hide the continue prompt
	continue_prompt.visible = false
	
	# Connect timer for typewriter effect - faster speed
	typewriter_timer.wait_time = 0.02  # Reduced from 0.03 to 0.02 for faster typing
	typewriter_timer.timeout.connect(_on_typewriter_timeout)
	
	# Hide initially
	visible = false

func show_dialogue_for_location(location_name: String):
	print("SECURITY DIALOGUE: Showing dialogue for location:", location_name)
	
	var dialogue_data = {}
	
	# Check if this is the tutorial location (FloMo)
	if location_name == "FloMoArea":
		dialogue_data = tutorial_dialogue
		# Tutorial is a single page
		dialogue_pages = [dialogue_data["text"]]
	else:
		# Generate dynamic dialogue based on current morale/performance
		dialogue_data = generate_performance_dialogue(location_name)
		# Performance dialogue is multi-page
		dialogue_pages = dialogue_data["pages"]
	
	# Set the character name
	name_label.text = dialogue_data["name"]
	
	# Initialize multi-page system
	current_page = 0
	total_pages = dialogue_pages.size()
	
	# Show first page
	show_current_page()
	
	# Clear the dialogue text and show the panel
	continue_prompt.visible = false
	visible = true
	
	# Play dialogue sound
	AudioManager.play_ui_click()

func show_current_page():
	# Set up the text for typewriter effect
	full_text = dialogue_pages[current_page]
	
	# Parse the text into tokens for proper BBCode handling
	text_tokens = parse_text_for_typewriter(full_text)
	token_index = 0
	current_text = ""
	char_index = 0
	can_continue = false
	
	# Clear the dialogue text
	dialogue_text.text = ""
	continue_prompt.visible = false
	
	# Start typewriter effect
	start_typewriter_effect()

func parse_text_for_typewriter(text: String) -> Array:
	"""Parse text into tokens, treating BBCode tags as single units"""
	var tokens = []
	var i = 0
	
	while i < text.length():
		var char = text[i]
		
		# Check if we're starting a BBCode tag
		if char == "[":
			# Find the end of the tag
			var tag_end = text.find("]", i)
			if tag_end != -1:
				# Add the complete BBCode tag as a single token
				var tag = text.substr(i, tag_end - i + 1)
				tokens.append({"type": "tag", "content": tag})
				i = tag_end + 1
			else:
				# No closing bracket found, treat as regular character
				tokens.append({"type": "char", "content": char})
				i += 1
		else:
			# Regular character
			tokens.append({"type": "char", "content": char})
			i += 1
	
	return tokens

func generate_performance_dialogue(location_name: String) -> Dictionary:
	# Get current morale to determine performance level
	var current_morale = MoraleManager.get_morale()
	var current_level = LevelManager.get_current_level()
	var performance_level = ""
	
	# Get comprehensive player statistics from GameManager
	var game_manager = get_node("/root/GameManager")
	var player_stats = game_manager.get_player_stats() if game_manager else {}
	
	# Determine performance level based on morale
	if current_morale >= 80:
		performance_level = "excellent"
	elif current_morale >= 60:
		performance_level = "good"
	elif current_morale >= 30:
		performance_level = "struggling"
	else:
		performance_level = "critical"
	
	print("SECURITY DIALOGUE: Current morale:", current_morale, "- Performance level:", performance_level)
	print("SECURITY DIALOGUE: Player stats:", player_stats)
	
	# Get the appropriate dialogue template
	var template = performance_dialogues[performance_level]
	
	# Pick random elements for variety
	var adjective = template["adjectives"][randi() % template["adjectives"].size()]
	var officer_name = security_officers[randi() % security_officers.size()]
	var location_context = location_contexts.get(location_name, "this location")
	
	# Format stats for display
	var morale_text = str(int(current_morale)) + "%"
	var level_text = "Level " + str(current_level)
	
	# Format player statistics
	var stanford_accepted = player_stats.get("stanford_accepted", 0)
	var stanford_rejected = player_stats.get("stanford_rejected", 0) 
	var berkeley_rejected = player_stats.get("berkeley_rejected", 0)
	var berkeley_accepted = player_stats.get("berkeley_accepted", 0)
	
	# Create multi-page dialogue based on performance level
	var pages = []
	
	# Page 1: Opening statement
	if performance_level == "excellent":
		var compliment = template["compliments"][randi() % template["compliments"].size()]
		pages.append(adjective + ", Agent! " + compliment)
		
	elif performance_level == "good":
		var compliment = template["compliments"][randi() % template["compliments"].size()]
		pages.append(adjective + ", Agent. " + compliment)
		
	elif performance_level == "struggling":
		var warning = template["warnings"][randi() % template["warnings"].size()]
		pages.append(adjective + ". " + warning)
		
	else: # critical
		var warning = template["warnings"][randi() % template["warnings"].size()]
		pages.append("[color=red]" + adjective + "[/color]! " + warning)
	
	# Page 2: Current status
	var status_color = ""
	if performance_level == "excellent":
		status_color = "green"
	elif performance_level == "critical":
		status_color = "red"
	else:
		status_color = "orange"
	
	pages.append("[color=gray]Current Status:[/color]\n" + level_text + " | Campus Morale: [color=" + status_color + "]" + morale_text + "[/color]")
	
	# Page 3: Performance summary (if they have stats)
	if stanford_accepted + stanford_rejected + berkeley_rejected + berkeley_accepted > 0:
		var stats_page = "[color=gray]Performance Summary:[/color]\n\n"
		stats_page += "Stanford Students Accepted: [color=green]" + str(stanford_accepted) + "[/color]\n"
		stats_page += "Stanford Students Rejected: [color=red]" + str(stanford_rejected) + "[/color]\n"
		stats_page += "Berkeley Students Rejected: [color=green]" + str(berkeley_rejected) + "[/color]\n"
		stats_page += "Berkeley Students Accepted: [color=red]" + str(berkeley_accepted) + "[/color]"
		pages.append(stats_page)
	
	# Page 4: Next assignment
	var assignment_prefix = ""
	if performance_level == "critical":
		assignment_prefix = "[color=red]URGENT - [/color]"
	
	pages.append(assignment_prefix + "[color=yellow]Next Assignment:[/color]\n\n" + location_context.capitalize())
	
	# Page 5: Closing statement
	if performance_level == "excellent":
		var closing = template["closing"][randi() % template["closing"].size()]
		pages.append("With your track record, I'm confident you'll maintain our high security standards.\n\n[color=green]" + closing + "[/color]")
		
	elif performance_level == "good":
		var closing = template["closing"][randi() % template["closing"].size()]
		pages.append("Continue your security sweep and stay focused.\n\n[color=orange]" + closing + "[/color]")
		
	elif performance_level == "struggling":
		var encouragement = template["encouragement"][randi() % template["encouragement"].size()]
		pages.append(encouragement + "\n\n[color=orange]Stanford is counting on you![/color]")
		
	else: # critical
		var final_push = template["final_push"][randi() % template["final_push"].size()]
		pages.append(final_push + "\n\n[color=red]Do not fail us![/color]")
	
	return {
		"name": officer_name,
		"pages": pages
	}

func start_typewriter_effect():
	is_typing = true
	typewriter_timer.start()

func _on_typewriter_timeout():
	if token_index < text_tokens.size():
		var token = text_tokens[token_index]
		
		# Add the token content to current text
		current_text += token["content"]
		
		# Update the display
		dialogue_text.text = current_text
		token_index += 1
		
		# Play typing sound only for visible characters (not BBCode tags)
		if token["type"] == "char" and token_index % 3 == 0:
			AudioManager.play_ui_click()
	else:
		# Typing complete
		is_typing = false
		typewriter_timer.stop()
		can_continue = true
		
		# Update continue prompt based on page status
		if current_page < total_pages - 1:
			continue_prompt.text = "[Press any key to continue]"
		else:
			continue_prompt.text = "[Press any key to close]"
		
		continue_prompt.visible = true

func _input(event):
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		if is_typing:
			# Skip typewriter effect
			complete_typewriter_immediately()
		elif can_continue:
			# Check if there are more pages
			if current_page < total_pages - 1:
				# Go to next page
				advance_to_next_page()
			else:
				# Close dialogue
				close_dialogue()
		
		# Only handle input if viewport is available
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()
	
	elif event is InputEventMouseButton and event.pressed:
		if is_typing:
			# Skip typewriter effect
			complete_typewriter_immediately()
		elif can_continue:
			# Check if there are more pages
			if current_page < total_pages - 1:
				# Go to next page
				advance_to_next_page()
			else:
				# Close dialogue
				close_dialogue()
		
		# Only handle input if viewport is available
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

func advance_to_next_page():
	current_page += 1
	print("SECURITY DIALOGUE: Advancing to page", current_page + 1, "of", total_pages)
	show_current_page()
	AudioManager.play_ui_click()

func complete_typewriter_immediately():
	# Stop timer and show full text immediately
	typewriter_timer.stop()
	dialogue_text.text = full_text
	is_typing = false
	can_continue = true
	
	# Update continue prompt based on page status
	if current_page < total_pages - 1:
		continue_prompt.text = "[Press any key to continue]"
	else:
		continue_prompt.text = "[Press any key to close]"
	
	continue_prompt.visible = true

func close_dialogue():
	print("SECURITY DIALOGUE: Closing dialogue")
	visible = false
	dialogue_completed.emit()
	
	# Play close sound
	AudioManager.play_ui_click()

# Public method to check if dialogue is active
func is_dialogue_active() -> bool:
	return visible

# Tutorial feedback system for first level mistakes
func show_tutorial_feedback(message: String):
	print("SECURITY DIALOGUE: Showing tutorial feedback:", message)
	
	# Set up tutorial feedback dialogue
	var feedback_dialogue = {
		"name": "Security Training Officer",
		"text": message
	}
	
	# Tutorial feedback is a single page
	dialogue_pages = [feedback_dialogue["text"]]
	
	# Set the character name
	name_label.text = feedback_dialogue["name"]
	
	# Initialize single-page system
	current_page = 0
	total_pages = 1
	
	# Show the feedback
	show_current_page()
	
	# Clear the dialogue text and show the panel
	continue_prompt.visible = false
	visible = true
	
	# Play feedback sound (different from regular dialogue)
	AudioManager.play_ui_click() 