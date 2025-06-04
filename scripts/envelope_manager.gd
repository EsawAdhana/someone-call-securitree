extends Node

# Signal for when the envelope message is read
signal envelope_read

# Locations that should show the envelope
const ENVELOPE_LOCATIONS = ["FloMoArea", "Y2E2Area", "GreenLibraryArea", "StadiumArea"]

# Track if the envelope has been read for the current level (for location entry requirement)
var envelope_read_for_level = false

func _ready():
	# Connect to level manager signals to reset envelope state
	LevelManager.level_started.connect(_on_level_started)

func should_show_envelope(location_name: String) -> bool:
	# Envelope should always be visible in envelope locations, regardless of read status
	return ENVELOPE_LOCATIONS.has(location_name)

func should_require_envelope_read(location_name: String) -> bool:
	# This is separate from visibility - this checks if envelope must be read before entering location
	return ENVELOPE_LOCATIONS.has(location_name) and not envelope_read_for_level

func mark_envelope_as_read():
	envelope_read_for_level = true
	envelope_read.emit()

func _on_level_started(_level_number: int):
	envelope_read_for_level = false