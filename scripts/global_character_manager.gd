extends Node

# Dictionary to store character data for each location
# Format: { location_name: [character_data_dict] }
var location_characters = {}

# Add character data for a specific location
func add_character_data(location_name: String, character_data: Dictionary):
	if not location_characters.has(location_name):
		location_characters[location_name] = []
	location_characters[location_name].append(character_data)
	print("GlobalCharacterManager: Added character data for", location_name)

# Get all character data for a specific location
func get_characters_data(location_name: String) -> Array:
	if location_characters.has(location_name):
		return location_characters[location_name]
	return []

# Check if a location has any characters
func has_characters(location_name: String) -> bool:
	return location_characters.has(location_name) and not location_characters[location_name].is_empty()

# Clear all characters for a specific location
func clear_location(location_name: String):
	if location_characters.has(location_name):
		location_characters.erase(location_name)
		print("GlobalCharacterManager: Cleared characters for", location_name)

# Remove a specific character from a location
func remove_character(location_name: String, character):
	if not location_characters.has(location_name):
		return
	
	var characters = location_characters[location_name]
	for i in range(characters.size() - 1, -1, -1):
		var data = characters[i]
		if data["variant_name"] == character.variant_name:
			characters.remove_at(i)
			print("GlobalCharacterManager: Removed character", character.variant_name, "from", location_name)
			break

# Update character data for a specific location
func update_character_data(location_name: String, character_data: Dictionary):
	if not location_characters.has(location_name):
		return
	
	var characters = location_characters[location_name]
	for i in range(characters.size()):
		var data = characters[i]
		if data["variant_name"] == character_data["variant_name"]:
			characters[i] = character_data
			print("GlobalCharacterManager: Updated character data for", character_data["variant_name"], "in", location_name)
			break

# Get the total number of characters across all locations
func get_total_characters() -> int:
	var total = 0
	for location in location_characters.values():
		total += location.size()
	return total

# Clear all character data
func clear_all():
	location_characters.clear()
	print("GlobalCharacterManager: Cleared all character data") 