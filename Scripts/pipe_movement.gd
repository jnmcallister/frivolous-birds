extends Node2D


const speed: float = -400
const respawn_x_pos: float = -700 # When the pipes go past this point, go back into pipe queue

signal respawn_pipe(Node2D)

var move_pipe: bool = true

func _physics_process(delta: float) -> void:
	if move_pipe:
		# Move pipe
		position.x += speed * delta;
		
		# Check if this is past respawn point
		if global_position.x <= respawn_x_pos:
			respawn_pipe.emit($".")


func set_move_pipe(enabled: bool) -> void:
	move_pipe = enabled
