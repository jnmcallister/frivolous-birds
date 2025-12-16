extends Sprite2D

@onready var pipe_spawner: Node2D = %PipeSpawner

@export var shader: ShaderMaterial

var speed_divisor: float = 500
var shader_time: float = 0
var pipe_speed: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pipe_spawner.speed_increased.connect(increase_speed)
	set_speed(pipe_spawner.get_pipe_speed_default())


func _process(delta: float) -> void:
	shader_time += delta
	shader.set_shader_parameter("custom_time", shader_time * pipe_speed / speed_divisor)


func increase_speed(new_pipe_speed: float) -> void:
	set_speed(new_pipe_speed)


func set_speed(new_pipe_speed: float) -> void:
	#shader.set_shader_parameter("speed", pipe_speed / speed_divisor)
	pipe_speed = new_pipe_speed
	#print(get_shader_offset())
	#shader.set_shader_parameter("offset", get_shader_offset())


func get_shader_offset() -> float:
	return shader.get_shader_parameter("direction").x * Time.get_ticks_msec() * 1000 * shader.get_shader_parameter("speed")
