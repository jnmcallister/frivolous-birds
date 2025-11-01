extends CharacterBody2D


const JUMP_VELOCITY = -600.0

@export var jumpAction: String = "jumpP1"

func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed(jumpAction):
		velocity.y = JUMP_VELOCITY

	# Move player
	move_and_slide()
