extends Node

signal morale_changed(new_value)
signal morale_depleted

var current_morale: float = 100.0
const MORALE_DECREASE_AMOUNT: float = 50.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Make sure it persists across scene changes

func decrease_morale():
	var old_morale = current_morale
	current_morale = max(0, current_morale - MORALE_DECREASE_AMOUNT)
	
	print("MORALE DEBUG: Decreased from", old_morale, "to", current_morale, "(decrease amount:", MORALE_DECREASE_AMOUNT, ")")
	
	morale_changed.emit(current_morale)
	
	if current_morale <= 0:
		print("MORALE DEBUG: ⚠️ CRITICAL - Morale depleted! Emitting morale_depleted signal")
		morale_depleted.emit()
	else:
		print("MORALE DEBUG: Still alive with", current_morale, "% morale")

func get_morale() -> float:
	return current_morale

func reset_morale():
	current_morale = 100.0
	morale_changed.emit(current_morale) 
