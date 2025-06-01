extends Node

const NEUTRAL_ITEMS = [
	"sticky-tabs",
	"locker-lock",
	"coin-purse",
	"hydroflask",
	"portable-speaker",
	"comb",
	"tennis-shoes",
	"water-bottle",
	"pencil",
	"ballet-flats",
	"gum",
	"firstaid",
	"granola",
	"headphone",
	"key",
	"basketball",
	"glue-stick",
	"computer",
	"tennis-racket",
	"eraser",
	"umbrella",
	"notebook",
	"usb",
	"sunglasses",
	"sewing-kit",
	"wine-flask",
	"wallet",
	"boomerang",
	"stethoscope"
]

const BERKELEY_ITEMS = [
	"cal-horn",
	"cal-cup",
	"cal-hat",
	"cal-bear",
	"cal-notebook",
	"cal-flag"
]

# Get a random subset of neutral items
func get_random_neutral_items(count: int) -> Array:
	var items = []
	var available_items = NEUTRAL_ITEMS.duplicate()
	for i in range(min(count, available_items.size())):
		var random_index = randi() % available_items.size()
		items.append(available_items[random_index])
		available_items.remove_at(random_index)
	return items

# Get a random subset of Berkeley items
func get_random_berkeley_items(count: int) -> Array:
	var items = []
	var available_items = BERKELEY_ITEMS.duplicate()
	for i in range(min(count, available_items.size())):
		var random_index = randi() % available_items.size()
		items.append(available_items[random_index])
		available_items.remove_at(random_index)
	return items

# Get a random set of items for a character based on their type
func get_random_items_for_character(is_berkeley_student: bool) -> Array:
	var items = []
	
	if is_berkeley_student:
		# For Berkeley students, include 1-2 Berkeley items and 4-6 neutral items
		var berkeley_count = randi() % 2 + 1 # 1-2 Berkeley items
		var neutral_count = randi() % 3 + 4 # 4-6 neutral items
		
		items.append_array(get_random_berkeley_items(berkeley_count))
		items.append_array(get_random_neutral_items(neutral_count))
	else:
		# For Stanford students, include 5-8 neutral items
		var neutral_count = randi() % 4 + 5 # 5-8 neutral items
		items.append_array(get_random_neutral_items(neutral_count))
	
	return items