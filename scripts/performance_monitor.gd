extends Node

# Performance monitoring
var update_timer: Timer
var last_fps: float = 0.0
var fps_samples: Array[float] = []
const MAX_FPS_SAMPLES = 30

func _ready():
	# Set up update timer for performance monitoring
	update_timer = Timer.new()
	update_timer.wait_time = 1.0  # Update every second
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)
	
	print("PerformanceMonitor: Started monitoring")

func _process(delta):
	# Track FPS
	var current_fps = Engine.get_frames_per_second()
	last_fps = current_fps
	
	# Store FPS samples for averaging
	fps_samples.append(current_fps)
	if fps_samples.size() > MAX_FPS_SAMPLES:
		fps_samples.pop_front()

func _on_update_timer_timeout():
	# Print performance stats
	var stats = get_performance_stats()
	print("PERF: FPS: ", stats.fps, " | Chars: ", stats.active_characters, " | Pool: ", stats.pooled_characters, " | Nodes: ", stats.total_nodes)
	
	# Warn if performance is poor
	if stats.fps < 30:
		print("PERF WARNING: Low FPS detected! Consider reducing character count or increasing pooling.")
	
	if stats.active_characters > 20:
		print("PERF WARNING: High character count (", stats.active_characters, ") may cause performance issues.")

func get_performance_stats() -> Dictionary:
	"""Get current performance statistics"""
	var character_pool = get_node_or_null("/root/CharacterPool")
	var performance_manager = get_node_or_null("/root/PerformanceManager")
	var global_char_manager = get_node_or_null("/root/GlobalCharacterManager")
	
	var stats = {
		"fps": last_fps,
		"average_fps": 0.0,
		"active_characters": 0,
		"pooled_characters": 0,
		"total_characters": 0,
		"total_nodes": get_total_node_count()
	}
	
	# Calculate average FPS
	if fps_samples.size() > 0:
		var fps_sum = 0.0
		for fps in fps_samples:
			fps_sum += fps
		stats.average_fps = fps_sum / fps_samples.size()
	
	# Get character counts
	if character_pool:
		stats.active_characters = character_pool.get_active_count()
		stats.pooled_characters = character_pool.get_pool_size()
		stats.total_characters = stats.active_characters + stats.pooled_characters
	
	if performance_manager:
		# Use performance manager count as authoritative for active characters
		stats.active_characters = performance_manager.get_character_count()
	
	return stats

func get_total_node_count() -> int:
	"""Get total number of nodes in the scene tree"""
	return count_nodes_recursive(get_tree().root)

func count_nodes_recursive(node: Node) -> int:
	"""Recursively count all nodes in the tree"""
	var count = 1  # Count this node
	for child in node.get_children():
		count += count_nodes_recursive(child)
	return count

func force_garbage_collection():
	"""Force garbage collection to free unused memory"""
	# This doesn't exist in GDScript, but we can suggest it
	print("PERF: Consider calling System.GC.Collect() if available")

func get_memory_usage() -> Dictionary:
	"""Get memory usage information (limited in GDScript)"""
	return {
		"note": "Memory usage monitoring is limited in GDScript",
		"total_nodes": get_total_node_count()
	} 