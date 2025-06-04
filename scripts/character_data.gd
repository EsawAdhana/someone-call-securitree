extends Node

# Stanford student data pools (all legitimate) - based on actual ID assets
const STANFORD_NAME_ID_PAIRS = [
	{"name": "Alex Kim", "id": "06649274", "id_asset": "AlexKim_ID_1.PNG"},
	{"name": "Jessica Li", "id": "06889672", "id_asset": "JessicaLi_ID_2.PNG"},
	{"name": "Ryan Field", "id": "06824178", "id_asset": "RyanField_ID_3.PNG"},
	{"name": "Maya Patel", "id": "06626458", "id_asset": "MayaPatel_ID_4.PNG"},
	{"name": "Daniel Chen", "id": "06813788", "id_asset": "DanielChen_ID_5.PNG"},
	{"name": "Sibana Adhana", "id": "06858458", "id_asset": "SibanaAdhana_ID_6.PNG"},
	{"name": "Kelvin Nguyen", "id": "05626489", "id_asset": "KelvinNguyen_ID_7.PNG"}
]

# Berkeley students using stolen/fake IDs - these are the suspicious ones
const BERKELEY_NAME_ID_PAIRS = [
	{"name": "Hannah Scott", "id": "06547321", "id_asset": "HannahScott_ID_8.PNG"},
	{"name": "Sam Green", "id": "06782456", "id_asset": "SamGreen_ID_9.png"},
	{"name": "Tenzin Sherpa", "id": "06923847", "id_asset": "TenzinSherpa_ID_10.PNG"}
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

# Name-ID mismatches for Berkeley students (when they use wrong names)
const BERKELEY_NAME_MISMATCHES = [
	# Berkeley student using Hannah Scott's ID but wrong name displayed
	{"actual_name": "Marcus Williams", "fake_name": "Hannah Scott", "stolen_id": "06547321", "id_asset": "HannahScott_ID_8.PNG"},
	# Berkeley student using Sam Green's ID but wrong name displayed
	{"actual_name": "Lisa Chen", "fake_name": "Sam Green", "stolen_id": "06782456", "id_asset": "SamGreen_ID_9.png"},
	# Berkeley student using Tenzin Sherpa's ID but wrong name displayed
	{"actual_name": "Jake Rodriguez", "fake_name": "Tenzin Sherpa", "stolen_id": "06923847", "id_asset": "TenzinSherpa_ID_10.PNG"}
]

# Track used characters to avoid duplicates
var used_characters = []
var character_count = 0

# Track guaranteed spawning for first level
var first_level_stanford_spawned = false
var first_level_berkeley_spawned = false

func get_random_character() -> Dictionary:
	print("[CHARACTER DEBUG] Getting random character")
	
	# Limit total characters
	if character_count >= 15:
		print("[CHARACTER DEBUG] Maximum character limit reached")
		return {}
		
	character_count += 1
	
	# Check if this is the first level and apply guaranteed spawning logic
	var current_level = LevelManager.get_current_level()
	if current_level == 1:
		return get_character_for_first_level()
	
	# For other levels, use the original random logic
	var is_stanford = randf() < 0.7
	var character_type = 0 if is_stanford else 1
	
	print("[CHARACTER DEBUG] Generating", "Stanford" if is_stanford else "Berkeley", "student")
	
	if is_stanford:
		return generate_stanford_student()
	else:
		return generate_berkeley_student()

func get_character_for_first_level() -> Dictionary:
	print("[CHARACTER DEBUG] Getting character for first level")
	print("[CHARACTER DEBUG] Stanford spawned:", first_level_stanford_spawned, "Berkeley spawned:", first_level_berkeley_spawned)
	
	# For the first level, guarantee one Stanford and one Berkeley student
	if not first_level_stanford_spawned and not first_level_berkeley_spawned:
		# First character - randomly choose which type to spawn first
		if randf() < 0.5:
			first_level_stanford_spawned = true
			print("[CHARACTER DEBUG] Spawning guaranteed Stanford student first")
			return generate_stanford_student()
		else:
			first_level_berkeley_spawned = true
			print("[CHARACTER DEBUG] Spawning guaranteed Berkeley student first")
			return generate_berkeley_student()
	elif not first_level_stanford_spawned:
		# Second character - spawn the missing Stanford student
		first_level_stanford_spawned = true
		print("[CHARACTER DEBUG] Spawning guaranteed Stanford student second")
		return generate_stanford_student()
	elif not first_level_berkeley_spawned:
		# Second character - spawn the missing Berkeley student
		first_level_berkeley_spawned = true
		print("[CHARACTER DEBUG] Spawning guaranteed Berkeley student second")
		return generate_berkeley_student()
	else:
		# Both guaranteed types spawned, use random logic for any additional characters
		var is_stanford = randf() < 0.7
		print("[CHARACTER DEBUG] Both guaranteed types spawned, generating random", "Stanford" if is_stanford else "Berkeley", "student")
		if is_stanford:
			return generate_stanford_student()
		else:
			return generate_berkeley_student()

func generate_stanford_student() -> Dictionary:
	# For Stanford students, pick a random name-ID pair (everything matches perfectly)
	var name_id_pair = STANFORD_NAME_ID_PAIRS[randi() % STANFORD_NAME_ID_PAIRS.size()]
	var name = name_id_pair["name"]
	var student_id = name_id_pair["id"]
	var id_asset = name_id_pair["id_asset"]
	
	# Ensure no duplicates
	while used_characters.has(name + student_id):
		name_id_pair = STANFORD_NAME_ID_PAIRS[randi() % STANFORD_NAME_ID_PAIRS.size()]
		name = name_id_pair["name"]
		student_id = name_id_pair["id"]
		id_asset = name_id_pair["id_asset"]
	
	used_characters.append(name + student_id)
	
	return {
		"name": name,
		"displayed_name": name,  # For Stanford students, displayed name matches ID name
		"type": 0,
		"id": student_id,
		"id_asset": id_asset,
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
	var id_asset: String
	var displayed_name: String  # The name that shows above the character
	
	# Handle name/ID mismatch
	if flaws.has("name_mismatch"):
		# Berkeley student using a fake name that doesn't match their stolen ID
		var mismatch = BERKELEY_NAME_MISMATCHES[randi() % BERKELEY_NAME_MISMATCHES.size()]
		displayed_name = mismatch["actual_name"]  # Wrong name displayed above character
		name = mismatch["fake_name"]  # Correct name on the stolen ID card
		student_id = mismatch["stolen_id"]
		id_asset = mismatch["id_asset"]
		print("[CHARACTER DEBUG] Name mismatch - Display name:", displayed_name, "ID name:", name)
	else:
		# Use Berkeley student with matching name and ID (but they're still Berkeley students)
		var berkeley_pair = BERKELEY_NAME_ID_PAIRS[randi() % BERKELEY_NAME_ID_PAIRS.size()]
		name = berkeley_pair["name"]
		displayed_name = name  # Name matches ID
		student_id = berkeley_pair["id"]
		id_asset = berkeley_pair["id_asset"]
	
	# Ensure no duplicates
	while used_characters.has(displayed_name + student_id):
		if flaws.has("name_mismatch"):
			var mismatch = BERKELEY_NAME_MISMATCHES[randi() % BERKELEY_NAME_MISMATCHES.size()]
			displayed_name = mismatch["actual_name"]
			name = mismatch["fake_name"]
			student_id = mismatch["stolen_id"]
			id_asset = mismatch["id_asset"]
		else:
			var berkeley_pair = BERKELEY_NAME_ID_PAIRS[randi() % BERKELEY_NAME_ID_PAIRS.size()]
			name = berkeley_pair["name"]
			displayed_name = name
			student_id = berkeley_pair["id"]
			id_asset = berkeley_pair["id_asset"]
	
	used_characters.append(displayed_name + student_id)
	
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
		"name": name,  # Name on the ID card
		"displayed_name": displayed_name,  # Name shown above character (can be different)
		"type": 1,
		"id": student_id,
		"id_asset": id_asset,
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
	# Reset first level guaranteed spawning tracking
	first_level_stanford_spawned = false
	first_level_berkeley_spawned = false
	print("[CHARACTER DEBUG] Character data reset, including first level guarantees") 
