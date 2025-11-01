extends Node2D


# Get pipes
const PIPE_SCENE_TRIPLE = preload("res://Scenes/triple_pipe.tscn")

var pipe_elevation_max: float = 270

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_pipe()


func create_pipe() -> void:
	var new_pipe = PIPE_SCENE_TRIPLE.instantiate()
	add_child(new_pipe)
	
	# Set y position randomly
	new_pipe.position.y = randf_range(-pipe_elevation_max, pipe_elevation_max)


func _on_timer_timeout() -> void:
	create_pipe() # TODO - Add object pooling
