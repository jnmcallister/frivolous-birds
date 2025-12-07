extends Node2D

const MAX_HEIGHT_DIFFERENCE = 125; # Moves the middle segment up or down by at most this ammount

@onready var middle_segment: Area2D = $PipeSegmentHolder/MiddleSegment

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_pipe()


func init_pipe() -> void:
	middle_segment.position.y = randf_range(-MAX_HEIGHT_DIFFERENCE, MAX_HEIGHT_DIFFERENCE)
