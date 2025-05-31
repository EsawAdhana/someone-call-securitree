extends Node

# Dictionary to store student data between scenes
var active_students: Dictionary = {}

# Signal to notify when a student should be spawned
signal spawn_student(student_data)

func register_student(character) -> void:
    var student_data = {
        "unique_id": character.unique_id,
        "character_type": character.character_type,
        "variant_name": character.variant_name,
        "has_id": character.has_id,
        "valid_major": character.valid_major,
        "student_path": character.student_path
    }
    active_students[character.unique_id] = student_data

func get_student_data(unique_id: String) -> Dictionary:
    return active_students.get(unique_id, {})

func remove_student(unique_id: String) -> void:
    if active_students.has(unique_id):
        active_students.erase(unique_id)

func transfer_student_to_location(unique_id: String, location: String) -> void:
    if active_students.has(unique_id):
        print("STUDENT MANAGER: Transferring student " + unique_id + " to " + location)
        spawn_student.emit(active_students[unique_id])