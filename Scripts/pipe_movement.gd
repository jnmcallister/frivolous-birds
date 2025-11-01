extends Node2D


const speed: float = -400;

func _physics_process(delta: float) -> void:
	# Move pipe
	position.x += speed * delta;
