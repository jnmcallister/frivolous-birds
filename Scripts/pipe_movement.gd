extends Node2D


const respawn_x_pos: float = -1500 # When the pipes go past this point, go back into pipe queue

signal respawn_pipe(Node2D)

var speed: float = -400
var move_pipe: bool = false

func _physics_process(delta: float) -> void:
	if move_pipe:
		# Move pipe
		position.x += speed * delta;
		
		# Check if this is past respawn point
		if global_position.x <= respawn_x_pos:
			respawn_pipe.emit($".")


func set_move_pipe(enabled: bool) -> void:
	move_pipe = enabled	


func set_pipe_speed(pipe_speed: float) -> void:
	speed = pipe_speed
