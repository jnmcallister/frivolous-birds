class_name player
extends CharacterBody2D


const JUMP_VELOCITY = -600.0

@export var jumpAction: String = "jumpP1"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var player_explosion: Node2D = $player_explosion
@onready var game_manager: Node2D = %GameManager

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
	# Start particles
	player_explosion.get_node("CPUParticles2D").emitting = true
	
	# Hide player
	sprite.process_mode = Node.PROCESS_MODE_DISABLED
	sprite.visible = false
	
	# Disable collision
	collision.process_mode = Node.PROCESS_MODE_DISABLED
	collision.set_deferred("disabled", true)
	
	# Tell game manager that a player died
	game_manager.on_player_died()
