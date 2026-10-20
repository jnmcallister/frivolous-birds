extends Node2D


const respawn_x_pos: float = -1500 # When the pipes go past this point, go back into pipe queue

signal respawn_pipe(Node2D)

# Max distance (px) the pipe travels above or below its base height
@export var y_amplitude: float = 120.0

var speed: float = -400
var move_pipe: bool = false

# Peak vertical velocity in px/s. 0 means this pipe does not move vertically
var y_speed: float = 0.0

# Current position in the sine wave (radians). Accumulated each frame so that
# changing y_speed mid-flight never makes the pipe jump
var y_phase: float = 0.0


func _physics_process(delta: float) -> void:
	if move_pipe:
		# Move pipe horizontally
		position.x += speed * delta;
		
		# Move pipe vertically along a sine wave (only if this pipe was chosen to move)
		if y_speed != 0.0:
			# For y = A * sin(w * t), peak velocity = A * w, so w = peak velocity / A
			var angular_speed: float = y_speed / maxf(y_amplitude, 0.001)
			
			# Advance phase and wrap it so it never grows large enough to lose precision
			y_phase = fmod(y_phase + angular_speed * delta, TAU)
			
			# Offset is local to the parent pipe, which holds the random base height
			position.y = y_amplitude * sin(y_phase)
		
		# Check if this is past respawn point
		if global_position.x <= respawn_x_pos:
			respawn_pipe.emit($".")


func set_move_pipe(enabled: bool) -> void:
	move_pipe = enabled	


func set_pipe_speed(pipe_speed: float) -> void:
	speed = pipe_speed


# Makes this pipe bob up and down, starting at the given point in the wave
func start_y_motion(new_y_speed: float, start_phase: float) -> void:
	y_speed = new_y_speed
	y_phase = start_phase


# Stops vertical motion and snaps back to the base height.
# Called when a pipe is recycled so it never carries over its old wave position
func stop_y_motion() -> void:
	y_speed = 0.0
	y_phase = 0.0
	position.y = 0.0


# Updates the vertical speed of a pipe that is already moving (phase is kept)
func set_y_speed(new_y_speed: float) -> void:
	y_speed = new_y_speed


# True if this pipe is currently bobbing up and down
func is_moving_vertically() -> bool:
	return y_speed != 0.0
