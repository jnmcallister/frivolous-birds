extends Node


@export var enabled: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot") && enabled:
		# Get screenshot filepath
		var filepath = "user://Screenshot.png"
		
		# Get screenshot image
		var screenshot = get_viewport().get_texture().get_image()
		
		# Save it
		screenshot.save_png(filepath)
		print("Saved " + filepath)
