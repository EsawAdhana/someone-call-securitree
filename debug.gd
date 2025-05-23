extends Node

# Use this for debugging
static func print_pressed(button_name):
	print("DEBUG: Button pressed - " + button_name)
	
	# Output stack trace to see what's happening
	var stack = get_stack()
	for i in range(stack.size()):
		if i > 0:  # Skip the first line which is this function
			print("  " + str(i) + ": " + stack[i]["source"] + ":" + str(stack[i]["line"]) + " in function " + stack[i]["function"])
