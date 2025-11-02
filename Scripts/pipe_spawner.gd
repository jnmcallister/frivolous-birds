extends Node2D


# Get pipes
const PIPE_SCENE_TRIPLE = preload("res://Scenes/triple_pipe.tscn")

var pipe_elevation_max: float = 270
var free_pipes: Array[Node2D] = []

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_pipe()


func create_pipe() -> void:
	# Instantiate pipe
	var new_pipe = PIPE_SCENE_TRIPLE.instantiate()
	
	# Set as child of this spawner
	add_child(new_pipe)
	
	# Set pipe position and stats
	initialize_pipe(new_pipe)
	
	# Make pipe remove itself when it reaches end of screen
	new_pipe.respawn_pipe.connect(remove_pipe)


# Puts a pipe on the right side of the screen
# This is different from create_pipe(), which instantiates a new pipe
func spawn_pipe() -> void:
	# Check if there is a pipe available
	if free_pipes.size() > 0:
		# TODO - Add random pipe from list
		initialize_pipe(free_pipes.pop_front())
	
	# If there is no pipe available, instantiate a new one
	else:
		create_pipe()


func _on_timer_timeout() -> void:
	#create_pipe() # TODO - Add object pooling
	spawn_pipe()


func initialize_pipe(pipe_node: Node2D) -> void:
	# Set y position randomly
	pipe_node.position.y = randf_range(-pipe_elevation_max, pipe_elevation_max)
	
	# Start movement
	pipe_node.set_move_pipe(true)


# Removes pipe from scene and adds it to the free_pipes array
func remove_pipe(pipe_node: Node2D) -> void:
	# Stop pipe movement
	pipe_node.set_move_pipe(false)
	
	# Set position to offscreen (where it will start moving again)
	pipe_node.global_position.x = global_position.x
	
	# Add this to queue
	free_pipes.push_back(pipe_node)
