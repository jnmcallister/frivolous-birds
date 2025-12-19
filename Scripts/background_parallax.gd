extends Parallax2D

@onready var pipe_spawner: Node2D = %PipeSpawner
@onready var parallax: Parallax2D = $"."

@export var x_offset_bounds: Vector2 # Min and max values for x offset (on _ready)
@export var x_repeat_size_bounds: Vector2 # Min and max values for x repeat size. If both are 0, ignore this

var old_pipe_speed: float = 0 # Speed of pipe before speed increase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get initial pipe speed
	old_pipe_speed = pipe_spawner.get_pipe_speed_default()
	
	# Connect to speed increase event
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
