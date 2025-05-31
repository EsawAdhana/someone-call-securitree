extends Resource
class_name StudentPath

# Explicitly type the array as String
var locations: Array[String] = []
var current_location_index: int = 0

func _init(path_locations: Array[String] = []):
    locations = path_locations

func get_next_location() -> String:
    if current_location_index + 1 < locations.size():
        current_location_index += 1
        return locations[current_location_index]
    return ""

func get_current_location() -> String:
    if current_location_index < locations.size():
        return locations[current_location_index]
    return ""

func has_next_location() -> bool:
    return current_location_index + 1 < locations.size()