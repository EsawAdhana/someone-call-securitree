extends Node

# Predefined character data
const CHARACTERS = {
	"Alex Kim": {
		"type": 0,  # Stanford
		"id": "06649274",
		"dorm": "Ng House",
		"year": "Sophomore",
		"major": "Electrical Engineering - Aero-Astro",
		"clubs": ["ASES", "SSI"],
		"stats": {
			"sat": 1590,
			"gpa": 3.94
		},
		"transcript": {
			"ENGR 40A": "A",
			"CME 106": "A",
			"AA 101": "A-",
			"CS 161": "B+"
		},
		"backpack_items": ["Raspberry Pi kit", "notebook full of circuit diagrams", "USB toolkit", "a bag of Cheetos"],
		"personality": "Quiet, introverted, and kind",
		"dialogue": [
			"I'm working on a new circuit design for my rocket project.",
			"The Cheetos? Yeah, they help me think better during late-night coding sessions.",
			"I should be heading to the Space Systems lab soon..."
		]
	},
	"Jessica Li": {
		"type": 0,  # Stanford
		"id": "06889672",
		"dorm": "Crothers",
		"year": "Frosh",
		"major": "Human Biology",
		"clubs": ["Asian-American Stanford Pre-Med Association (APMSA)", "O-tone"],
		"stats": {
			"sat": 1550,
			"gpa": 4.12
		},
		"transcript": {
			"BIO 83": "A",
			"CHEM 33": "A-",
			"PSYCH 1": "A",
			"PWR 2MDG": "B+"
		},
		"backpack_items": ["Flowers", "flashcards", "chopsticks", "granola bars", "Hydro Flask with APMSA sticker"],
		"personality": "Friendly, organized, sings during stress, super Asian",
		"dialogue": [
			"I have APMSA meeting in 10 minutes!",
			"These flashcards? Just reviewing some biochem pathways.",
			"*humming while organizing notes*"
		]
	},
	"Ryan Field": {
		"type": 0,  # Stanford
		"id": "06824178",
		"dorm": "Arroyo",
		"year": "Frosh",
		"major": "History",
		"clubs": ["Stanford Water Polo Club", "Stanford Historical Society"],
		"stats": {
			"sat": 1450,
			"gpa": 3.91
		},
		"transcript": {
			"HISTORY 1A": "A",
			"THINK 45": "A",
			"HISTORY 150": "A-",
			"IHUM": "A"
		},
		"backpack_items": ["Class required books", "gym shorts", "headphones"],
		"personality": "Well-spoken yapper, rich, frat-bro",
		"dialogue": [
			"Just finished water polo practice, heading to the library.",
			"My dad's an alum, class of '89.",
			"Have you read Professor Johnson's new book on constitutional history?"
		]
	},
	"Maya Patel": {
		"type": 0,  # Stanford
		"id": "06626458",
		"dorm": "Bob",
		"year": "Junior",
		"major": "Economics",
		"clubs": ["BASES", "Stanford Women in Business", "Raagapella"],
		"stats": {
			"sat": 1570,
			"gpa": 3.95
		},
		"transcript": {
			"ECON 102B": "A",
			"MATH 104": "A-",
			"BUSGEN 102": "A",
			"PWR 2HTD": "A+"
		},
		"backpack_items": ["Moleskine planner", "Protein bars", "Owala water bottle"],
		"personality": "Friendly, fashionable, finance girl",
		"dialogue": [
			"I have a BASES pitch competition later!",
			"Just finished my econometrics problem set.",
			"Have you seen the new Stanford Women in Business newsletter?"
		]
	},
	"Daniel Chen": {
		"type": 0,  # Stanford
		"id": "06813788",
		"dorm": "Crothers",
		"year": "Frosh",
		"major": "Computer Science",
		"clubs": ["TreeHacks", "Stanford Blockchain Club"],
		"stats": {
			"sat": 1600,
			"gpa": 3.95
		},
		"transcript": {
			"CS 106B": "A",
			"CS 109": "A",
			"MATH 53": "A",
			"COLLEGE 102": "A"
		},
		"backpack_items": ["MacBook", "headphones", "energy drink", "career fair stickers"],
		"personality": "Messy, cracked, quiet, meme-coin trader",
		"dialogue": [
			"*typing furiously on laptop*",
			"Have you heard about my new blockchain project?",
			"Just pulled an all-nighter for my CS assignment."
		]
	},
	"Sibana Adhana": {
		"type": 0,  # Stanford
		"id": "06858458",
		"dorm": "Eucalypto",
		"year": "Frosh",
		"major": "Psychology",
		"clubs": ["Stanford Xtrm", "SWID", "Theta Sorority", "Stanford Women in CS"],
		"stats": {
			"sat": 1590,
			"gpa": 3.45
		},
		"transcript": {
			"PSYCH 70": "A",
			"DESIGN 1": "A",
			"WELLNESS 104": "B+",
			"PWR 1": "A",
			"TAPS 115": "A",
			"CS 247G": "In Progress"
		},
		"backpack_items": ["Dance flats", "yoga mat", "journal", "bunch of snacks"],
		"personality": "Elegant, pretty, creative",
		"dialogue": [
			"Just finished a dance rehearsal!",
			"I'm working on a new game design project.",
			"The wellness course is really helping with stress management."
		]
	},
	"Kelvin Nguyen": {
		"type": 0,  # Stanford
		"id": "05626489",
		"dorm": "Trancos",
		"year": "Senior",
		"major": "Computational Biology",
		"clubs": ["SVSA President", "Stanford Sustainable Investing Group", "Trancos Outdoor House"],
		"stats": {
			"sat": 1510,
			"gpa": 3.88
		},
		"transcript": {
			"BIOE 214": "A-",
			"BIOE 204": "A",
			"CS 226": "A-",
			"SYMSYS 161": "A"
		},
		"backpack_items": ["Climbing powder", "notebook", "plastic water bottle", "bananas"],
		"personality": "Chill, chill, chill",
		"dialogue": [
			"Just got back from climbing at the dish.",
			"Working on this new genomics algorithm.",
			"Want to grab lunch at Wilbur?"
		]
	},
	"Hannah Scott": {
		"type": 1,  # Berkeley
		"id": "78945672",
		"dorm": "Meier",  # Suspicious: upperclassmen dorm
		"year": "Frosh",
		"major": "English",
		"clubs": [],
		"stats": {
			"sat": 1310,
			"gpa": 3.2
		},
		"transcript": {
			"PSYCH 70": "A",
			"ECOM 102A": "B",
			"MATH 1": "A"  # Not a Stanford course
		},
		"backpack_items": ["Plain notebook", "cafeteria tray"],
		"personality": "Nervous, avoids eye contact",
		"dialogue": [
			"Oh, um, I live in Meier... it's near... um...",
			"The cafeteria? Yeah, I just... borrowed this tray...",
			"*looking around nervously*"
		]
	},
	"Sam Green": {
		"type": 1,  # Berkeley
		"id": "06500000",
		"dorm": "Crothers",
		"year": "Senior",
		"major": "Philosophy",
		"clubs": ["Stanford Entrepreneurship Club"],  # This club doesn't exist
		"stats": {
			"sat": 1340,
			"gpa": 3.3
		},
		"transcript": {
			"PHIL 1": "A-",
			"PHIL 80": "B+",
			"SYMSYS 1": "A",
			"HIST 10": "A"  # History of Berkeley - red flag
		},
		"backpack_items": ["Wallet", "fake Stanford ID"],
		"personality": "Overconfident, makes obvious mistakes",
		"dialogue": [
			"Yeah, I'm heading to the Stanford Entrepreneurship Club meeting.",
			"The Berkeley course? Oh, that's just... an elective...",
			"Of course I know where everything is! I'm a senior!"
		]
	},
	"Tenzin Sherpa": {
		"type": 1,  # Berkeley
		"id": "06589678",
		"dorm": "Stern",  # Not a dorm, but a neighborhood
		"year": "Senior",
		"major": "Computer Science",
		"clubs": [],
		"stats": {
			"sat": 1580,
			"gpa": 3.9
		},
		"transcript": {
			"CS 106B": "A",
			"CS 103": "A",
			"MATH 53": "A",
			"COLLEGE 102": "A"
		},
		"backpack_items": ["Snack wrappers", "Berkeley Pen and Stickers"],
		"personality": "Lost, doesn't know campus landmarks",
		"dialogue": [
			"Hoover Tower? Is that the new dining hall?",
			"*trying to hide Berkeley stickers*",
			"I live in Stern dorm... wait, that's not right..."
		]
	}
}

# Function to get a random character that hasn't been used yet
var used_characters = []

func get_random_character() -> Dictionary:
	print("[CHARACTER DEBUG] Getting random character")
	print("[CHARACTER DEBUG] Currently used characters:", used_characters)
	
	if used_characters.size() >= CHARACTERS.size():
		print("[CHARACTER DEBUG] All characters have been used")
		return {}  # No more characters available
		
	var available_characters = CHARACTERS.keys().filter(func(name): return not used_characters.has(name))
	print("[CHARACTER DEBUG] Available characters:", available_characters)
	
	if available_characters.is_empty():
		print("[CHARACTER DEBUG] No available characters left")
		return {}
		
	var random_name = available_characters[randi() % available_characters.size()]
	print("[CHARACTER DEBUG] Selected character:", random_name)
	
	used_characters.append(random_name)
	
	# Create a deep copy of the character data
	var character_data = CHARACTERS[random_name].duplicate(true)
	character_data["name"] = random_name  # Add the name to the dictionary
	
	print("[CHARACTER DEBUG] Character data prepared:", character_data)
	return character_data

# Reset the used characters list for a new round
func reset_characters():
	used_characters.clear() 
