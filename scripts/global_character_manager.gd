extends Node

# Dictionary to store actual character instances for each location
# Format: { location_name: [character_instance] }
var location_characters = {}

# Add character instance for a specific location
func add_character(location_name: String, character: Node):
	if not location_characters.has(location_name):
		location_characters[location_name] = []
	
	# Remove the character from its current parent if it has one
	if character.get_parent():
		character.get_parent().remove_child(character)
	
	# Add to our storage
	location_characters[location_name].append(character)
	print("GlobalCharacterManager: Added character for", location_name)

# Get all characters for a specific location
func get_characters(location_name: String) -> Array:
	if location_characters.has(location_name):
		return location_characters[location_name]
	return []

# Check if a location has any characters
func has_characters(location_name: String) -> bool:
	return location_characters.has(location_name) and not location_characters[location_name].is_empty()

# Clear all characters for a specific location
func clear_location(location_name: String):
	if location_characters.has(location_name):
		# Free all characters in this location
		for character in location_characters[location_name]:
			if is_instance_valid(character):
				character.queue_free()
		location_characters.erase(location_name)
		print("GlobalCharacterManager: Cleared characters for", location_name)

# Remove a specific character from a location
func remove_character(location_name: String, character: Node):
	if not location_characters.has(location_name):
		return
	
	var characters = location_characters[location_name]
	var idx = characters.find(character)
	if idx != -1:
		characters.remove_at(idx)
		print("GlobalCharacterManager: Removed character from", location_name)

# Hide all characters in a location
func hide_location_characters(location_name: String):
	if location_characters.has(location_name):
		for character in location_characters[location_name]:
			if is_instance_valid(character):
				# Remove from current parent if any
				if character.get_parent():
					character.get_parent().remove_child(character)
				character.visible = false
				character.is_walking = false # Stop movement
		print("GlobalCharacterManager: Hidden characters for", location_name)

# Show and restore all characters in a location
func show_location_characters(location_name: String, parent_node: Node):
	if location_characters.has(location_name):
		for character in location_characters[location_name]:
			if is_instance_valid(character):
				# Add to the new parent
				parent_node.add_child(character)
				character.visible = true
				character.resume_walking()
		print("GlobalCharacterManager: Shown characters for", location_name)

# Get the total number of characters across all locations
func get_total_characters() -> int:
	var total = 0
	for location in location_characters.values():
		total += location.size()
	return total

# Clear all character data
func clear_all():
	for location in location_characters.keys():
		clear_location(location)
	print("GlobalCharacterManager: Cleared all character data")