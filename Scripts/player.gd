class_name player
extends CharacterBody2D

enum KillzoneType{
	SNOW,
	GIRAFFE
}

# ---- NORMAL mode values (tune these freely) ----
const JUMP_VELOCITY = -700.0
const GRAVITY = 1960.0 # Downward pull in px/s^2 (project gravity 980 * vector (0, 2))

# ---- CLASSIC mode values (frozen, do not change) ----
const CLASSIC_JUMP_VELOCITY = -700.0
const CLASSIC_GRAVITY = 1960.0

const SPRITE_ROTATION_MIN = -15
const SPRITE_ROTATION_MAX = 100
const SPRITE_ROTATION_SPEED = 80

# ---- Fast fall values (NORMAL mode only, classic never uses these) ----
const FAST_FALL_GRAVITY_MULTIPLIER: float = 2.5 # Gravity AND sprite rotation speed are multiplied by this while the fall key is held
const FAST_FALL_SQUASH_SCALE: Vector2 = Vector2(1.2, 0.8) # Sprite scale while diving (squash and stretch). Push this further for a stronger look
const FAST_FALL_BLEND_TIME: float = 0.15 # Seconds to ease the sprite scale into and out of the dive pose
const FAST_FALL_ANIMATION: StringName = &"fast_fall" # Name of the dive squash animation (built in code, see add_fast_fall_animation)

# Scenes and scripts used by the respawn feature
const TURKEY_SCENE = preload("res://Scenes/turkey.tscn")
const KILLZONE_SCRIPT = preload("res://Scripts/killzone.gd")
const TURKEY_LOCAL_POSITION: Vector2 = Vector2(0, -50) # Where the turkey sits inside the player (matches player.tscn)

@export var jumpAction: String = "jumpP1"
#@export var bird_texture: Texture2D
@export var bird_sprite_frames: SpriteFrames
@export var is_player_1 = true # True if red bird, false if green

# ---- Respawn tuning (editable in the inspector) ----
@export var immunity_duration: float = 2.5 # Seconds of giraffe immunity after respawning
@export var blink_interval: float = 0.2 # Seconds between the sprite appearing/disappearing
@export var respawn_hop_factor: float = 0.6 # Fraction of a normal jump used for the hop on respawn

# The values actually used while playing. Chosen from the lists above in on_game_start()
var active_jump_velocity: float = JUMP_VELOCITY
var active_gravity: float = GRAVITY

# True while the selected game mode is CLASSIC. Set in on_game_start().
# Classic disables fast fall and keeps the old trigger-to-jump gamepad controls.
var is_classic_mode: bool = false

# Input action names. Filled in _ready() from jumpAction and is_player_1,
# so game.tscn does not need a new exported property for player 2.
var fall_action: String = "fallP1" # Hold to dive (NORMAL mode only)
var classic_jump_action: String = "jumpP1Classic" # Extra jump input that only works in CLASSIC mode (gamepad triggers)

var enable_movement: bool = false
var is_dead: bool = false # True from the moment this bird dies until it is respawned
var player_collide_force: float = 500 # Force to apply to player when they collide with another player
var turkey_init_x_velocity: Vector2 = Vector2(200, 600) # When the player dies, set the x velocity of the turkey to somewhere in this range
var turkey_init_y_velocity: Vector2 = Vector2(-500, -2000)# When the player dies, set the y velocity of the turkey to somewhere in this range
var turkey_init_rotation_velocity: Vector2 = Vector2(360 * 2, 360 * 4) # When the player dies, set the rotation velocity of the turkey to somewhere in this range (degrees/second)

# Fast fall state
var is_fast_falling: bool = false # True while the fall key is held and this bird is allowed to dive
var was_fast_falling: bool = false # Value of is_fast_falling on the previous physics frame, used to detect press and release

# Immunity state (only used after a respawn)
var immune: bool = false # While true, giraffes cannot kill this bird (the floor still can)
var immunity_time_left: float = 0 # Seconds until immunity ends
var blink_time_left: float = 0 # Seconds until the sprite toggles visibility again

# Camera shake
var player_jump_shake_intensity: float = 0
var player_jump_shake_time: float = 0
var player_death_shake_intensity: float = 150
var player_death_shake_time: float = 0.8

#@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Animates player sprites
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Animates player scale (squash and stretch)
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var player_explosion: Node2D = $player_explosion
@onready var turkey: Sprite2D = $Turkey

# Audio
@onready var death_sound: AudioStreamPlayer = $DeathSound
@onready var flap_sound: AudioStreamPlayer = $FlapSound
@onready var collide_sound: AudioStreamPlayer = $CollideSound

# Singletons
@onready var game_manager: Node2D = %GameManager
@onready var pipe_spawner: Node2D = %PipeSpawner
@onready var camera: Camera2D = %Camera
@onready var time_freezer: Node = %TimeFreezer

func _ready() -> void:
	game_manager.game_start.connect(on_game_start)
	
	# Set sprite frames
	if bird_sprite_frames:
		animated_sprite.sprite_frames = bird_sprite_frames
	
	# Pick which fall action belongs to this bird (red = S, green = Down arrow)
	fall_action = "fallP1" if is_player_1 else "fallP2"
	
	# The classic-only jump action is the normal jump action with "Classic" added
	# (jumpP1 -> jumpP1Classic, jumpP2 -> jumpP2Classic)
	classic_jump_action = jumpAction + "Classic"
	
	# Add the dive squash animation to the AnimationPlayer
	add_fast_fall_animation()


# Builds the "fast_fall" squash animation in code and adds it to the AnimationPlayer's library.
# Done in code so player.tscn does not need to be hand-edited.
# The animation is a single constant scale key, so when it is played with a blend time the
# AnimationPlayer eases from the current scale into the dive pose.
func add_fast_fall_animation() -> void:
	var library: AnimationLibrary = animation_player.get_animation_library(&"")
	
	# The library is a resource shared by every instance of player.tscn (and it survives scene
	# reloads), so the second bird and any retry would hit "animation already exists" without this check
	if library.has_animation(FAST_FALL_ANIMATION):
		return
	
	# Animation as long as the blend, holding a single scale value
	var anim := Animation.new()
	anim.length = FAST_FALL_BLEND_TIME
	var track: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("AnimatedSprite2D:scale"))
	anim.track_insert_key(track, 0.0, FAST_FALL_SQUASH_SCALE)
	
	library.add_animation(FAST_FALL_ANIMATION, anim)


func on_game_start() -> void:
	# Pick the physics values for the selected mode.
	# This is done here and not in _ready(), because the mode is only chosen when
	# a start button is pressed (the static mode could be stale during _ready()).
	if GameModeConfig.current_mode == GameModeConfig.GameMode.CLASSIC:
		is_classic_mode = true
		active_jump_velocity = CLASSIC_JUMP_VELOCITY
		active_gravity = CLASSIC_GRAVITY
	else:
		is_classic_mode = false
		active_jump_velocity = JUMP_VELOCITY
		active_gravity = GRAVITY
	
	enable_movement = true
	animation_player.play("falling") # Exit idle animation


func _physics_process(delta: float) -> void:
	
	# Tick the post-respawn immunity (runs only while immune)
	if immune:
		update_immunity(delta)
	
	# Check if movement is enabled
	if enable_movement:
		
		# Fast fall (NORMAL mode only). Held key = dive. Dead birds and the start menu never
		# get here because enable_movement is false for them.
		is_fast_falling = not is_classic_mode and Input.is_action_pressed(fall_action)
		
		# On press or release, update the squash animation
		if is_fast_falling != was_fast_falling:
			was_fast_falling = is_fast_falling
			update_fall_squash()
		
		# 1.0 normally, FAST_FALL_GRAVITY_MULTIPLIER while diving.
		# Used for both gravity and sprite rotation speed below.
		var fast_fall_factor: float = FAST_FALL_GRAVITY_MULTIPLIER if is_fast_falling else 1.0
	
		# Add the gravity (straight down), scaled up over time by the spawner and by fast fall
		velocity += Vector2.DOWN * active_gravity * delta * pipe_spawner.get_gravity_multiplier() * fast_fall_factor

		# Rotate sprite (faster while diving). The cap stays the same, a dive only reaches it sooner.
		if animated_sprite.rotation_degrees < SPRITE_ROTATION_MAX:
			animated_sprite.rotation_degrees += SPRITE_ROTATION_SPEED * fast_fall_factor * delta
		elif animated_sprite.rotation_degrees > SPRITE_ROTATION_MAX:
			animated_sprite.rotation_degrees = SPRITE_ROTATION_MAX

		# Handle jump.
		var jump_pressed: bool = Input.is_action_just_pressed(jumpAction)
		
		# In CLASSIC mode the gamepad triggers still jump. In NORMAL mode they are used for fast fall.
		if is_classic_mode:
			jump_pressed = jump_pressed or Input.is_action_just_pressed(classic_jump_action)
		
		if jump_pressed:
			jump()

		# Move player
		move_and_slide()
		
		# Handle collisions with other players
		for i in get_slide_collision_count():
			var col_obj = get_slide_collision(i) # Get object at index i
			if col_obj.get_collider() is player: # Check if this is a player
				
				# Check which player this is
				if is_player_1: # Top player
					
					# Add force to this player
					velocity += Vector2.UP * player_collide_force
					
					# Play sound
					collide_sound.play()
					
				break


# Switches the squash animation when the fall key is pressed or released.
# If the flap squash is playing it is left alone, and _on_sprite_animation_finished()
# picks the right animation when the flap ends (at most 0.4s later).
func update_fall_squash() -> void:
	# Do not cut off the flap squash
	if animated_sprite.animation == "jump" and animated_sprite.is_playing():
		return
	
	if is_fast_falling:
		# Ease into the dive pose
		animation_player.play(FAST_FALL_ANIMATION, FAST_FALL_BLEND_TIME)
	else:
		# Ease back to the normal falling squash instead of snapping to scale (1, 1)
		animation_player.play("falling", FAST_FALL_BLEND_TIME)


func jump() -> void:
	# Set velocity (uses the mode's jump velocity, scaled up over time by the spawner)
	velocity.y = active_jump_velocity * pipe_spawner.get_jump_multiplier()
	
	# Rotate sprite
	animated_sprite.rotation_degrees = SPRITE_ROTATION_MIN
	
	# Start flap animation
	animated_sprite.stop()
	animated_sprite.play("jump")
	animation_player.play("jump")
	
	# Play flap sound
	flap_sound.play()
	
	# Shake camera
	camera.shake_camera(player_jump_shake_intensity, player_jump_shake_time)


# Called when player touches killzone
func on_player_died(killzone_type: KillzoneType) -> void:
	
	# Ignore repeat triggers (for example touching two killzones in one frame)
	if is_dead:
		return
	
	# Immunity only protects against giraffes. The floor (SNOW) always kills.
	if immune and killzone_type == KillzoneType.GIRAFFE:
		return
	
	# Mark as dead and cancel any immunity (also un-hides a blinking sprite)
	is_dead = true
	immune = false
	animated_sprite.visible = true
	
	# A dead bird is not diving. Reset so a respawn starts from a clean state.
	is_fast_falling = false
	was_fast_falling = false
	
	# Check which type of killzone this is
	if killzone_type == KillzoneType.GIRAFFE:
		
		# Start particles
		player_explosion.get_node("FireParticles").emitting = true
		player_explosion.get_node("SmokeParticles").emitting = true
		
	elif killzone_type == KillzoneType.SNOW:
		
		# Start particles
		player_explosion.get_node("SnowParticles").emitting = true
	
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
	
	# Disable movement
	enable_movement = false
	
	# Tell game manager that a player died
	game_manager.on_player_died(is_player_1)
	
	# Shake camera
	camera.shake_camera(player_death_shake_intensity, player_death_shake_time)


# Brings this bird back to life at the given world position.
# Called by the game manager after the alive player collects a heart.
func respawn(spawn_position: Vector2) -> void:
	is_dead = false
	
	# Replace the turkey. The old one was reparented to the scene root and is
	# still flying around, so free it and create a fresh hidden one for the next death.
	if is_instance_valid(turkey):
		turkey.queue_free()
	turkey = TURKEY_SCENE.instantiate() as Sprite2D
	add_child(turkey)
	turkey.position = TURKEY_LOCAL_POSITION
	
	# Move to the spawn position and stop any leftover motion
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	# Show the sprite again
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	animated_sprite.visible = true
	
	# The hitbox itself is switched back on at the END of this function, after the
	# physics server has applied the new position (see the awaits below)
	collision.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Start immunity BEFORE collision is re-enabled, so a giraffe overlapping the
	# spawn point cannot kill the bird in the first frame
	immune = true
	immunity_time_left = immunity_duration
	blink_time_left = blink_interval
	
	# Allow movement again, then do a small hop so the bird does not drop straight down.
	# NOTE: if the fall key is already held, the bird starts diving on the next physics
	# frame (there is deliberately no release latch), which can crush this hop.
	enable_movement = true
	jump()
	velocity.y *= respawn_hop_factor
	
	# FIX: wait two physics frames before turning the hitbox back on.
	# Teleporting a CharacterBody2D does not take effect in the physics server immediately.
	# If the hitbox is enabled right away, the physics server briefly sees it at the OLD
	# position (where the bird died). If that was the floor, the floor killzone fires and
	# kills the bird at once, even though it is far away by then.
	# Immunity is already running, and giraffes cannot hurt the bird while it is immune.
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Safety: skip if the scene was left or the bird died again while waiting
	if not is_inside_tree() or is_dead:
		return
	collision.disabled = false


# Counts down immunity and makes the sprite blink. Called every physics frame while immune.
func update_immunity(delta: float) -> void:
	immunity_time_left -= delta
	blink_time_left -= delta
	
	# Immunity is over
	if immunity_time_left <= 0:
		end_immunity()
		return
	
	# Toggle the sprite on and off at a steady interval
	if blink_time_left <= 0:
		blink_time_left += blink_interval
		animated_sprite.visible = not animated_sprite.visible


# Ends immunity. If the bird is inside a giraffe at this moment, it dies on the spot.
func end_immunity() -> void:
	immune = false
	
	# Make sure the sprite can never get stuck hidden
	animated_sprite.visible = true
	
	# Killzones only fire when a body ENTERS them, so a bird that is already inside a
	# giraffe would never be killed. Check for that overlap once, right now.
	if is_overlapping_giraffe():
		on_player_died(KillzoneType.GIRAFFE)


# Returns true if this bird's hitbox currently overlaps a giraffe killzone.
# Must be called from a physics frame (it queries the physics space directly).
func is_overlapping_giraffe() -> bool:
	# Build a query that uses this bird's own hitbox shape and position
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0xFFFFFFFF # All layers. We filter by script below instead.
	
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 32)
	for hit in hits:
		var other: Object = hit["collider"]
		
		# Only count killzone areas. The pipe score areas share the same collision
		# layer, so filtering by script avoids false deaths.
		if other.get_script() == KILLZONE_SCRIPT and int(other.killzone_type) == int(KillzoneType.GIRAFFE):
			return true
	
	return false


func _on_sprite_animation_finished() -> void:
	# Check which animation this is
	if animated_sprite.animation == "jump":
		animated_sprite.play("idle")
		
		# The flap is over, so hand the squash back to the right animation.
		# If the fall key is still held, go straight into the dive pose.
		if is_fast_falling:
			animation_player.play(FAST_FALL_ANIMATION, FAST_FALL_BLEND_TIME)
		else:
			animation_player.play("falling")
