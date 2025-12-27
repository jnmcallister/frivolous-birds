# Flies out of player when they die. Doesn't collide with anything and just serves to be a visual effect

extends Sprite2D

const SWOOSHES_PER_SECOND = 2 # How many swoosh sounds play every second (1 / audio clip length)

@onready var turkey_sprite: Sprite2D = $"."
@onready var spin_sounds: AudioStreamPlayer2D = $SpinSounds

var active: bool = false # Becomes true when player dies
var velocity: Vector2 = Vector2.ZERO
var rotation_velocity: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turkey_sprite.hide()


func on_player_death(init_velocity: Vector2, init_rotation_velocity: float) -> void:
	# Allow turkey to move
	active = true
	velocity = init_velocity
	rotation_velocity = init_rotation_velocity
	
	# Unhide turkey
	turkey_sprite.show()
	
	# Start sounds
	spin_sounds.play()
	spin_sounds.pitch_scale = rotation_velocity / (360 * SWOOSHES_PER_SECOND) # 360 degrees * swoosh sounds per second


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check if this is able to move
	if active:
		# Move based on velocity
		position += velocity * delta
		
		# Accelerate y velocity with gravity
		velocity += ProjectSettings.get_setting("physics/2d/default_gravity") * ProjectSettings.get_setting("physics/2d/default_gravity_vector") * delta
		
		# Rotate
		rotate(deg_to_rad(rotation_velocity) * delta)
