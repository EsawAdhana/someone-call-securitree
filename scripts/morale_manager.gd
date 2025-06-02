extends Node

signal morale_changed(new_value)
signal morale_depleted

var current_morale: float = 100.0
const MORALE_DECREASE_AMOUNT: float = 10.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Make sure it persists across scene changes

func decrease_morale():
	current_morale = max(0, current_morale - MORALE_DECREASE_AMOUNT)
	morale_changed.emit(current_morale)
	
	if current_morale <= 0:
		morale_depleted.emit()

func get_morale() -> float:
	return current_morale

func reset_morale():
	current_morale = 100.0
	morale_changed.emit(current_morale) 
