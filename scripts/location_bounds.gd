extends Node2D

# The rectangle that defines where NPCs can spawn and move
@export var bounds_rect: Rect2 = Rect2(0, 0, 500, 500)
@export var debug_draw: bool = false # For visualizing the bounds in editor

func _ready():
	# Ensure the bounds are valid
	if bounds_rect.size.x <= 0 or bounds_rect.size.y <= 0:
		push_warning("LocationBounds: Invalid bounds size. Using default 500x500.")
		bounds_rect.size = Vector2(500, 500)

func get_random_position_in_bounds() -> Vector2:
	return Vector2(
		randf_range(bounds_rect.position.x, bounds_rect.position.x + bounds_rect.size.x),
		randf_range(bounds_rect.position.y, bounds_rect.position.y + bounds_rect.size.y)
	)

func is_position_in_bounds(pos: Vector2) -> bool:
	return bounds_rect.has_point(pos)

func get_clamped_position(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, bounds_rect.position.x, bounds_rect.position.x + bounds_rect.size.x),
		clamp(pos.y, bounds_rect.position.y, bounds_rect.position.y + bounds_rect.size.y)
	)

# Debug draw the bounds
func _draw():
	if debug_draw:
		draw_rect(bounds_rect, Color(1, 0, 0, 0.3), true)  # Fill
		draw_rect(bounds_rect, Color(1, 0, 0, 0.8), false) # Border 