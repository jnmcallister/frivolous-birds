class_name player
extends CharacterBody2D


const JUMP_VELOCITY = -700.0

@export var jumpAction: String = "jumpP1"

var enable_movement: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var player_explosion: Node2D = $player_explosion
@onready var game_manager: Node2D = %GameManager

func _ready() -> void:
	game_manager.game_start.connect(on_game_start)


func on_game_start() -> void:
	enable_movement = true


func _physics_process(delta: float) -> void:
	
	# Check if movement is enabled
	if enable_movement:
	
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
