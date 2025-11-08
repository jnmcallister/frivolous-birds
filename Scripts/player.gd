class_name player
extends CharacterBody2D


const JUMP_VELOCITY = -600.0

@export var jumpAction: String = "jumpP1"

@onready var player_explosion: Node2D = $player_explosion

func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed(jumpAction):
		velocity.y = JUMP_VELOCITY

	# Move player
	move_and_slide()


# Called when player touches killzone
func on_player_died() -> void:
	player_explosion.get_node("CPUParticles2D").emitting = true
