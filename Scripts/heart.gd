# A collectible heart that rides inside a pipe gap (NORMAL mode only).
# The pipe spawner adds this as a child of a pipe's PipeSegmentHolder, so it
# scrolls and bobs together with the pipe automatically.
# When the alive player touches it, it emits "collected", plays a sound, spawns a
# colored particle burst, and removes itself. The game manager handles the respawn.

class_name Heart
extends Area2D

# Emitted once when the alive player touches the heart.
# is_red is true if this heart revives the red bird (player 1).
signal collected(is_red: bool)

# Same x position at which pipes get recycled (see pipe_movement.gd).
# If the heart gets this far left it was never collected, so it is removed.
const RESPAWN_X_POS: float = -1500

# Placeholder visuals/audio. Swap these out when your real art exists.
const PICKUP_SFX: AudioStream = preload("res://Assets/SFX/popping-01.wav")
const PARTICLE_TEXTURE: Texture2D = preload("res://Assets/Art/Particles/particle_circle.png")

const RED_COLOR: Color = Color(1.0, 0.2, 0.25)
const GREEN_COLOR: Color = Color(0.3, 0.9, 0.35)

# Particle burst tuning. Expect to tweak these by eye.
const BURST_AMOUNT: int = 60
const BURST_LIFETIME: float = 0.7

# Set by the pipe spawner BEFORE the heart is added to the scene.
# True = red heart (revives player 1), false = green heart (revives player 2).
var is_red: bool = true

# Guards against double collection if two bodies enter in the same frame
var was_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Placeholder tint so you can tell the colors apart.
	# Remove this line once your animated sprites are already colored.
	modulate = RED_COLOR if is_red else GREEN_COLOR


func _physics_process(_delta: float) -> void:
	# The heart was never collected and has scrolled off the left side, so remove it
	if global_position.x <= RESPAWN_X_POS:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if was_collected:
		return
	
	# Only a living player can collect it. A dead player has its collision
	# disabled, so this is a second safety check.
	if body is player and not body.is_dead:
		was_collected = true
		
		# Pickup feedback (spawned on the scene root so it outlives this node)
		play_pickup_fx()
		
		# Tell listeners (the game manager) that the heart was collected
		collected.emit(is_red)
		
		queue_free()


# Spawns a one-shot sound and a one-shot particle burst on the scene root.
# They are NOT children of the heart, because the heart is a child of a moving
# pipe and is freed immediately.
func play_pickup_fx() -> void:
	var fx_root: Node = get_tree().current_scene
	var tint: Color = RED_COLOR if is_red else GREEN_COLOR
	
	# --- Sound ---
	# Duplicate the stream and turn looping off, so the sound can never loop forever
	# (this wav is also used for the slider drag sound, which may be set to loop)
	var sfx_stream: AudioStream = PICKUP_SFX.duplicate()
	if sfx_stream is AudioStreamWAV:
		sfx_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = sfx_stream
	sfx_player.bus = &"sfx"
	fx_root.add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free) # Clean up when done
	sfx_player.play()
	
	# --- Particle burst ---
	var burst := CPUParticles2D.new()
	burst.texture = PARTICLE_TEXTURE
	burst.amount = BURST_AMOUNT
	burst.lifetime = BURST_LIFETIME
	burst.one_shot = true
	burst.explosiveness = 0.95 # Nearly all particles emit at once
	burst.spread = 180.0 # Full circle
	burst.gravity = Vector2(0, 600)
	burst.initial_velocity_min = 150.0
	burst.initial_velocity_max = 600.0
	burst.scale_amount_min = 0.25
	burst.scale_amount_max = 0.6
	burst.color = tint
	burst.z_index = 20 # Draw above pipes and birds
	
	# Fade particles out over their lifetime (multiplies with the color above)
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	burst.color_ramp = fade
	
	fx_root.add_child(burst)
	burst.global_position = global_position
	burst.finished.connect(burst.queue_free) # Clean up when done
	burst.emitting = true
