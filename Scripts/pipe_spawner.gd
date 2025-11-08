extends Node2D


# Get pipes
const PIPE_SCENE_TRIPLE = preload("res://Scenes/triple_pipe.tscn")
const PIPE_SCENE_DOUBLE = preload("res://Scenes/double_pipe.tscn")

var pipe_elevation_max: float = 260
var free_pipes: Array[Node2D] = []

var triple_pipe_count: int = 8
var double_pipe_count: int = 2
var pipe_speed: float = -400

@onready var timer: Timer = $Timer
@onready var game_manager: Node2D = %GameManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiate_pipes()
	spawn_pipe()
	game_manager.double_speed.connect(double_pipe_speed)


# Instantiates several pipes and adds them to free_pipes queue
func instantiate_pipes() -> void:
	# Add triple pipes
	for i in range(triple_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_TRIPLE)
	
	# Add double pipes
	for i in range(double_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_DOUBLE)


# Instantiates a new pipe and adds it to free_pipes queue
func instantiate_new_pipe(pipe: Resource) -> void:
	# Instantiate pipe
	var new_pipe = pipe.instantiate()
	
	# Set as child of this spawner
	add_child(new_pipe)
	
	# Make pipe remove itself when it reaches end of screen
	new_pipe.get_node("PipeSegmentHolder").respawn_pipe.connect(remove_pipe)
	
	# Signal to game manager to increase score when player crosses line
	new_pipe.get_node("PipeSegmentHolder/PipeScoreArea").score_increment.connect(game_manager.on_score_increment)
	
	# Add to queue
	free_pipes.push_back(new_pipe)


# Puts a pipe on the right side of the screen
# This is different from create_pipe(), which instantiates a new pipe
func spawn_pipe() -> void:
	# Check if there is a pipe available
	if free_pipes.size() > 0:
		# Add random pipe from list
		var random_index = randi_range(0, free_pipes.size() - 1)
		initialize_pipe(free_pipes[random_index])
		
		# Remove pipe from list
		free_pipes.remove_at(random_index)
	
	# If there is no pipe available, instantiate new ones
	else:
		instantiate_pipes()


func _on_timer_timeout() -> void:
	spawn_pipe()


func initialize_pipe(pipe_node: Node2D) -> void:
	# Set y position randomly
	pipe_node.position.y = randf_range(-pipe_elevation_max, pipe_elevation_max)
	
	# Start movement
	pipe_node.get_node("PipeSegmentHolder").set_move_pipe(true)
	pipe_node.get_node("PipeSegmentHolder").set_pipe_speed(pipe_speed)


# Removes pipe from scene and adds it to the free_pipes array
func remove_pipe(pipe_node: Node2D) -> void:
	# Stop pipe movement
	pipe_node.set_move_pipe(false)
	
	# Set position to offscreen (where it will start moving again)
	pipe_node.global_position.x = global_position.x
	
	# Add this to queue
	var pipe_parent = pipe_node.get_parent()
	free_pipes.push_back(pipe_parent)


func double_pipe_speed() -> void:
	pipe_speed *= 2
	timer.wait_time /= 4
