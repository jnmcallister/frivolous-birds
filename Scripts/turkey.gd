# Flies out of player when they die. Doesn't collide with anything and just serves to be a visual effect

extends Sprite2D

@onready var turkey_sprite: Sprite2D = $"."

var active: bool = false # Becomes true when player dies
var velocity: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turkey_sprite.hide()


func on_player_death(init_velocity: Vector2) -> void:
	# Allow turkey to move
	active = true
	velocity = init_velocity
	
	# Unhide turkey
	turkey_sprite.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check if this is able to move
	if active:
		# Move based on velocity
		position += velocity * delta
		
		# Accelerate y velocity with gravity
		velocity += ProjectSettings.get_setting("physics/2d/default_gravity") * ProjectSettings.get_setting("physics/2d/default_gravity_vector") * delta
