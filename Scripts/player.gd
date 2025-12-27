class_name player
extends CharacterBody2D


const JUMP_VELOCITY = -700.0
const SPRITE_ROTATION_MIN = -15
const SPRITE_ROTATION_MAX = 100
const SPRITE_ROTATION_SPEED = 80

@export var jumpAction: String = "jumpP1"
#@export var bird_texture: Texture2D
@export var bird_sprite_frames: SpriteFrames

var enable_movement: bool = false
var player_collide_force: float = 50 # Force to apply to player when they collide with another player
var turkey_init_x_velocity: Vector2 = Vector2(200, 600) # When the player dies, set the x velocity of the turkey to somewhere in this range
var turkey_init_y_velocity: Vector2 = Vector2(-500, -2000)# When the player dies, set the y velocity of the turkey to somewhere in this range
var turkey_init_rotation_velocity: Vector2 = Vector2(360 * 2, 360 * 4) # When the player dies, set the rotation velocity of the turkey to somewhere in this range (degrees/second)

#@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var player_explosion: Node2D = $player_explosion
@onready var game_manager: Node2D = %GameManager
@onready var pipe_spawner: Node2D = %PipeSpawner
@onready var turkey: Sprite2D = $Turkey
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _ready() -> void:
	game_manager.game_start.connect(on_game_start)
	
	# Set sprite
	#if bird_texture:
		#sprite.texture = bird_texture
	if bird_sprite_frames:
		animated_sprite.sprite_frames = bird_sprite_frames


func on_game_start() -> void:
	enable_movement = true


func _physics_process(delta: float) -> void:
	
	# Check if movement is enabled
	if enable_movement:
	
		# Add the gravity.
		velocity += get_gravity() * delta * pipe_spawner.get_gravity_multiplier()

		# Rotate sprite
		if animated_sprite.rotation_degrees < SPRITE_ROTATION_MAX:
			animated_sprite.rotation_degrees += SPRITE_ROTATION_SPEED * delta
		elif animated_sprite.rotation_degrees > SPRITE_ROTATION_MAX:
			animated_sprite.rotation_degrees = SPRITE_ROTATION_MAX

		# Handle jump.
		if Input.is_action_just_pressed(jumpAction):
			jump()

		# Move player
		move_and_slide()
		
		# Handle collisions with other players
		for i in get_slide_collision_count():
			var col_obj = get_slide_collision(i) # Get object at index i
			if col_obj.get_collider() is player: # Check if this is a player
				# Add "bounce" force to other player
				var other_player = col_obj.get_collider() as player
				other_player.velocity -= col_obj.get_normal() * player_collide_force
				velocity += col_obj.get_normal() * player_collide_force


func jump() -> void:
	# Set velocity
	velocity.y = JUMP_VELOCITY * pipe_spawner.get_jump_multiplier()
	
	# Rotate sprite
	animated_sprite.rotation_degrees = SPRITE_ROTATION_MIN
	
	# Start flap animation
	animated_sprite.stop()
	animated_sprite.play("jump")


# Called when player touches killzone
func on_player_died() -> void:
	# Start particles
	player_explosion.get_node("CPUParticles2D").emitting = true
	
	# Calculate velocities of turkey (dead player sprite)
	var turkey_x_velocity = randf_range(turkey_init_x_velocity.x, turkey_init_x_velocity.y)
	var turkey_y_velocity = randf_range(turkey_init_y_velocity.x, turkey_init_y_velocity.y)
	var turkey_velocity: Vector2 = Vector2(turkey_x_velocity, turkey_y_velocity)
	var turkey_rotation_velocity = randf_range(turkey_init_rotation_velocity.x, turkey_init_rotation_velocity.y)
	
	# Throw turkey out of player
	turkey.reparent(get_tree().root)
	turkey.on_player_death(turkey_velocity, turkey_rotation_velocity)
	
	# Hide player
	animated_sprite.process_mode = Node.PROCESS_MODE_DISABLED
	animated_sprite.visible = false
	
	# Disable collision
	collision.process_mode = Node.PROCESS_MODE_DISABLED
	collision.set_deferred("disabled", true)
	
	# Play sounds
	death_sound.play()
	
	# Tell game manager that a player died
	game_manager.on_player_died()


func _on_sprite_animation_finished() -> void:
	# Check which animation this is
	if animated_sprite.animation == "jump":
		animated_sprite.play("idle")
