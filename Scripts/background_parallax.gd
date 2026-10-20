extends Parallax2D

# The pipe speed that the autoscroll values in game.tscn were authored for.
# This is fixed on purpose. The spawner emits speed_increased once when the game
# starts, and the first ratio is computed against this baseline. In classic mode
# the start speed is also -400, so that ratio is exactly 1 (no change).
const BASELINE_PIPE_SPEED: float = -400.0

@onready var pipe_spawner: Node2D = %PipeSpawner
@onready var parallax: Parallax2D = $"."

@export var x_offset_bounds: Vector2 # Min and max values for x offset (on _ready)
@export var x_repeat_size_bounds: Vector2 # Min and max values for x repeat size. If both are 0, ignore this

var old_pipe_speed: float = BASELINE_PIPE_SPEED # Speed of pipe before the most recent speed change

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to speed increase event
	# (old_pipe_speed is NOT read from the spawner here, because the game mode
	# has not been chosen yet when this runs)
	pipe_spawner.speed_increased.connect(increase_speed)
	
	# Randomize x offset
	parallax.scroll_offset.x = randf_range(x_offset_bounds.x, x_offset_bounds.y)
	
	# Randomize x repeat size
	if x_repeat_size_bounds.x != 0 or x_repeat_size_bounds.y != 0: # Ignore if both are 0
		parallax.repeat_size.x = randf_range(x_repeat_size_bounds.x, x_repeat_size_bounds.y)


func increase_speed(new_speed: float) -> void:
	# Find the percent difference between old and new speeds
	# If the previous speed was -400 and the new speed is -440, the % difference will be 1.1
	var percent_difference = new_speed / old_pipe_speed
	
	# Set old pipe speed to this
	old_pipe_speed = new_speed
	
	# Increase speed of scrolling parallax
	parallax.autoscroll *= percent_difference
