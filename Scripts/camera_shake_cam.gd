extends Camera2D

var shake_intensity: float = 0
var active_shake_intensity: float = 0
var shake_time: float = 0
var active_shake_time: float = 0

var noise: FastNoiseLite = FastNoiseLite.new()

var init_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	init_offset = offset


func _physics_process(delta: float) -> void:
	
	# Check if screen shake should occur
	if active_shake_time > 0:
		
		# Calculate and apply offset
		var new_offset = Vector2(
			noise.get_noise_2d(active_shake_time, 0) * active_shake_intensity,
			noise.get_noise_2d(0, active_shake_time) * active_shake_intensity
		) + init_offset
		#offset = lerp(new_offset, init_offset, active_shake_time / shake_time)
		offset = new_offset
		
		# Decrease intensity over time
		active_shake_intensity = lerpf(0, shake_intensity, active_shake_time / shake_time)
		
		# Decrease shake time
		active_shake_time -= delta
		
		if active_shake_time <= 0: # Shake is over, reset values
			shake_intensity = 0
			active_shake_intensity = 0
			shake_time = 0
			active_shake_time = 0
			offset = init_offset


# Send a camera shake request
# Any requests with an intensity lower than the current intensity will be ignored
func shake_camera(intensity: float, time: float):
	
	# Ignore request if it's too small
	if intensity < shake_intensity:
		return
	
	# Create noise
	randomize()
	noise.seed = randi()
	noise.frequency = 2
	
	# Set intensity and time variables
	shake_intensity = intensity
	active_shake_intensity = intensity
	shake_time = time
	active_shake_time = time
