extends Node

# Stanford student data pools (all legitimate)
const STANFORD_NAMES = [
	"Alex Kim", "Jessica Li", "Ryan Field", "Maya Patel", "Daniel Chen", 
	"Sibana Adhana", "Kelvin Nguyen"
]

const STANFORD_IDS = [
	"06649274", "06889672", "06824178", "06626458", "06813788",
	"06858458", "05626489", "06547321", "06782456", "06923847",
	"06345678", "06781234", "06456789", "06987654"
]

const STANFORD_DORMS = [
	"Ng House", "Crothers", "Arroyo", "Bob", "Eucalypto", "Trancos", 
	"Wilbur", "Stern", "FloMo", "Roble", "Branner", "Donner"
]

const STANFORD_YEARS = ["Frosh", "Sophomore", "Junior", "Senior"]

const STANFORD_MAJORS = [
	"Computer Science", "Electrical Engineering", "Human Biology", "Economics",
	"Psychology", "History", "Mechanical Engineering", "English", "Physics",
	"Computational Biology", "Political Science", "Mathematics"
]

const STANFORD_CLUBS = [
	"ASES", "SSI", "TreeHacks", "BASES", "Stanford Water Polo Club",
	"Stanford Women in Business", "Stanford Blockchain Club", "APMSA", "O-tone",
	"Stanford Historical Society", "SVSA", "Stanford Xtrm", "SWID"
]

const STANFORD_LEGITIMATE_DIALOGUE = [
	"Just finished my problem set for CS 106B.",
	"Heading to Green Library to study.",
	"Can't wait for Big Game this weekend!",
	"The food at Wilbur is actually pretty good today.",
	"Have you been to the Cantor Arts Center?",
	"I'm thinking of declaring a minor in Human-Computer Interaction.",
	"The weather is perfect for studying at the Oval today.",
	"My TA for Math 51 is really helpful.",
	"I love the new renovation they did to Tresidder.",
	"Walking from my dorm to class takes about 10 minutes."
]

const STANFORD_LEGITIMATE_ITEMS = [
	"Stanford water bottle", "textbooks", "laptop", "notebooks", "pens",
	"Stanford ID card", "bike lock", "headphones", "protein bars", "coffee mug",
	"graphing calculator", "lab goggles", "Stanford sweatshirt", "flash drives",
	"planners", "sticky notes", "highlighters", "Stanford stickers"
]

const STANFORD_TRANSCRIPTS = [
	{
		"CS 106B": "A", "MATH 51": "A-", "PWR 1": "A", "COLLEGE 101": "A"
	},
	{
		"BIO 83": "A", "CHEM 33": "A-", "PSYCH 1": "A", "PWR 2MDG": "B+"
	},
	{
		"ECON 1A": "A", "MATH 19": "A", "HISTORY 1A": "A-", "THINK 45": "A"
	},
	{
		"ENGR 40A": "A-", "PHYSICS 61": "A", "CME 106": "B+", "AA 101": "A"
	},
	{
		"PSYCH 70": "A", "DESIGN 1": "A", "WELLNESS 104": "B+", "TAPS 115": "A"
	}
]

# Berkeley/Suspicious data pools
const BERKELEY_SUSPICIOUS_DIALOGUE = [
	"Where's the... uh... main library again?",
	"*nervously fidgeting with fake ID*",
	"Yeah, I totally know where Hoover Tower is...",
	"The campus is so... big... and confusing...",
	"I love the Berkeley... I mean Stanford campus!",
	"*looking around nervously*",
	"Is the student center that way?",
	"I'm definitely not lost right now...",
	"The Cardinal? Oh yeah, that's our... thing...",
	"*trying to hide suspicious items*"
]

const BERKELEY_SUSPICIOUS_ITEMS = [
	"UC Berkeley pen", "fake Stanford ID", "Berkeley stickers", "Golden Bears t-shirt",
	"UC Berkeley notebook", "stolen cafeteria tray", "forged documents",
	"Berkeley campus map", "Go Bears! button", "UC Berkeley water bottle",
	"suspicious looking ID card", "counterfeit Stanford merchandise"
]

const BERKELEY_TRANSCRIPTS = [
	{
		"HIST 10": "A", "PHIL 80": "B+", "ECOM 102A": "B", "MATH 1": "A"
	},
	{
		"UC BERKELEY 101": "A", "PSYCH 70": "B", "ENGL 45": "A-", "MATH 16A": "B+"
	},
	{
		"BERKELEY HIST": "A", "PHIL 1": "A-", "ECON 100": "B", "COMP SCI 61A": "A"
	}
]

# Name-ID mismatches for Berkeley students
const BERKELEY_NAME_ID_MISMATCHES = [
	{"name": "Hannah Scott", "id": "78945672"}, # Uses Hannah Scott ID but with suspicious ID number
	{"name": "Sam Green", "id": "06000000"}, # Uses Sam Green ID but with obviously fake ID
	{"name": "Tenzin Sherpa", "id": "99999999"} # Uses Tenzin Sherpa ID but with clearly fake ID
]

# Track used characters to avoid duplicates
var used_characters = []
var character_count = 0

func get_random_character() -> Dictionary:
	print("[CHARACTER DEBUG] Getting random character")
	
	# Limit total characters
	if character_count >= 15:
		print("[CHARACTER DEBUG] Maximum character limit reached")
		return {}
		
	character_count += 1
	
	# Decide character type - 70% Stanford, 30% Berkeley
	var is_stanford = randf() < 0.7
	var character_type = 0 if is_stanford else 1
	
	print("[CHARACTER DEBUG] Generating", "Stanford" if is_stanford else "Berkeley", "student")
	
	if is_stanford:
		return generate_stanford_student()
	else:
		return generate_berkeley_student()

func generate_stanford_student() -> Dictionary:
	# For Stanford students, everything must be legitimate and consistent
	var name = STANFORD_NAMES[randi() % STANFORD_NAMES.size()]
	var student_id = STANFORD_IDS[randi() % STANFORD_IDS.size()]
	
	# Ensure no duplicates
	while used_characters.has(name + student_id):
		name = STANFORD_NAMES[randi() % STANFORD_NAMES.size()]
		student_id = STANFORD_IDS[randi() % STANFORD_IDS.size()]
	
	used_characters.append(name + student_id)
	
	return {
		"name": name,
		"type": 0,
		"id": student_id,
		"dorm": STANFORD_DORMS[randi() % STANFORD_DORMS.size()],
		"year": STANFORD_YEARS[randi() % STANFORD_YEARS.size()],
		"major": STANFORD_MAJORS[randi() % STANFORD_MAJORS.size()],
		"clubs": _get_random_clubs(STANFORD_CLUBS, randi() % 3 + 1),
		"stats": {
			"sat": randi_range(1450, 1600),
			"gpa": randf_range(3.5, 4.0)
		},
		"transcript": STANFORD_TRANSCRIPTS[randi() % STANFORD_TRANSCRIPTS.size()],
		"backpack_items": _get_random_items(STANFORD_LEGITIMATE_ITEMS, randi() % 3 + 2),
		"personality": "Legitimate Stanford student",
		"dialogue": _get_random_dialogue(STANFORD_LEGITIMATE_DIALOGUE, 3)
	}

func generate_berkeley_student() -> Dictionary:
	# For Berkeley students, introduce 1-3 suspicious elements
	var num_flaws = randi() % 3 + 1  # 1-3 flaws
	var flaws = []
	
	# Possible flaws: name_mismatch, bad_dialogue, bad_items, bad_transcript
	var possible_flaws = ["name_mismatch", "bad_dialogue", "bad_items", "bad_transcript"]
	
	# Randomly select which flaws to introduce
	for i in range(num_flaws):
		var flaw = possible_flaws[randi() % possible_flaws.size()]
		if not flaws.has(flaw):
			flaws.append(flaw)
	
	print("[CHARACTER DEBUG] Berkeley student flaws:", flaws)
	
	var name: String
	var student_id: String
	
	# Handle name/ID mismatch
	if flaws.has("name_mismatch"):
		var mismatch = BERKELEY_NAME_ID_MISMATCHES[randi() % BERKELEY_NAME_ID_MISMATCHES.size()]
		name = mismatch["name"]
		student_id = mismatch["id"]
	else:
		# Use Berkeley student names that have corresponding ID cards
		var berkeley_names = ["Hannah Scott", "Sam Green", "Tenzin Sherpa"]
		name = berkeley_names[randi() % berkeley_names.size()]
		student_id = STANFORD_IDS[randi() % STANFORD_IDS.size()]
	
	# Ensure no duplicates
	while used_characters.has(name + student_id):
		if flaws.has("name_mismatch"):
			var mismatch = BERKELEY_NAME_ID_MISMATCHES[randi() % BERKELEY_NAME_ID_MISMATCHES.size()]
			name = mismatch["name"]
			student_id = mismatch["id"]
		else:
			var berkeley_names = ["Hannah Scott", "Sam Green", "Tenzin Sherpa"]
			name = berkeley_names[randi() % berkeley_names.size()]
			student_id = STANFORD_IDS[randi() % STANFORD_IDS.size()]
	
	used_characters.append(name + student_id)
	
	# Generate dialogue
	var dialogue: Array
	if flaws.has("bad_dialogue"):
		dialogue = _get_random_dialogue(BERKELEY_SUSPICIOUS_DIALOGUE, 3)
	else:
		dialogue = _get_random_dialogue(STANFORD_LEGITIMATE_DIALOGUE, 3)
	
	# Generate backpack items
	var backpack_items: Array
	if flaws.has("bad_items"):
		# Mix legitimate items with 1-2 suspicious ones
		var legit_items = _get_random_items(STANFORD_LEGITIMATE_ITEMS, randi() % 2 + 1)
		var bad_items = _get_random_items(BERKELEY_SUSPICIOUS_ITEMS, randi() % 2 + 1)
		backpack_items = legit_items + bad_items
	else:
		backpack_items = _get_random_items(STANFORD_LEGITIMATE_ITEMS, randi() % 3 + 2)
	
	# Generate transcript
	var transcript: Dictionary
	if flaws.has("bad_transcript"):
		transcript = BERKELEY_TRANSCRIPTS[randi() % BERKELEY_TRANSCRIPTS.size()]
	else:
		transcript = STANFORD_TRANSCRIPTS[randi() % STANFORD_TRANSCRIPTS.size()]
	
	return {
		"name": name,
		"type": 1,
		"id": student_id,
		"dorm": STANFORD_DORMS[randi() % STANFORD_DORMS.size()],
		"year": STANFORD_YEARS[randi() % STANFORD_YEARS.size()],
		"major": STANFORD_MAJORS[randi() % STANFORD_MAJORS.size()],
		"clubs": _get_random_clubs(STANFORD_CLUBS, randi() % 2 + 1),
		"stats": {
			"sat": randi_range(1200, 1500),
			"gpa": randf_range(2.8, 3.8)
		},
		"transcript": transcript,
		"backpack_items": backpack_items,
		"personality": "Suspicious behavior patterns",
		"dialogue": dialogue,
		"flaws": flaws  # Store for debugging
	}

# Helper functions
func _get_random_clubs(club_list: Array, count: int) -> Array:
	var clubs = []
	var available_clubs = club_list.duplicate()
	
	for i in range(min(count, available_clubs.size())):
		var club = available_clubs[randi() % available_clubs.size()]
		clubs.append(club)
		available_clubs.erase(club)
	
	return clubs

func _get_random_items(item_list: Array, count: int) -> Array:
	var items = []
	var available_items = item_list.duplicate()
	
	for i in range(min(count, available_items.size())):
		var item = available_items[randi() % available_items.size()]
		items.append(item)
		available_items.erase(item)
	
	return items

func _get_random_dialogue(dialogue_list: Array, count: int) -> Array:
	var dialogue = []
	var available_dialogue = dialogue_list.duplicate()
	
	for i in range(min(count, available_dialogue.size())):
		var line = available_dialogue[randi() % available_dialogue.size()]
		dialogue.append(line)
		available_dialogue.erase(line)
	
	return dialogue

# Reset the used characters list for a new round
func reset_characters():
	used_characters.clear() 
	character_count = 0
	print("[CHARACTER DEBUG] Character data reset") 
