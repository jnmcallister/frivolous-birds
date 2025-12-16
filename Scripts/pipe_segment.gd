extends Sprite2D

@export var scale_factor: float = 3

@onready var pipe_segment: Sprite2D = $"."
@onready var killzone: Area2D = $Killzone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Scale sprite and killzone so they show up and collide properly
	#var scale_amount = transform.get_scale().y
	#pipe_segment.region_rect = Rect2(0, 0, pipe_segment.region_rect.size.x, pipe_segment.region_rect.size.y * scale_amount + 26) # Set sprite region amount
	killzone.apply_scale(Vector2(1, scale_factor)) # Adjust killzone size
	#apply_scale(Vector2(1, 1 / scale_amount)) # Make sprite less stretched, while making killzone the proper size
	pipe_segment.offset.y -= 64 * (scale_factor - 1) - 26 # Offset sprite
	pass
