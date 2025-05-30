extends Node

# Dictionary to store area bounds for each location
var area_bounds = {
	"StadiumArea": Vector2(800, 500),
	"HooverTowerArea": Vector2(500, 500),
	"MainQuadArea": Vector2(800, 500),
	"GSBArea": Vector2(600, 400),
	"GreenLibraryArea": Vector2(600, 400),
	"MeyerGreenArea": Vector2(700, 400),
	"TresidderArea": Vector2(600, 500),
	"FarrillagaArea": Vector2(500, 500),
	"Y2E2Area": Vector2(700, 360),
	"CoDaArea": Vector2(700, 400),
	"CantorArea": Vector2(600, 440),
	"FloMoArea": Vector2(800, 400)
}

# Get the bounds for a location
func get_area_bounds(location: String) -> Vector2:
	if area_bounds.has(location):
		return area_bounds[location]
	return Vector2(500, 500)  # Default size if location not found 