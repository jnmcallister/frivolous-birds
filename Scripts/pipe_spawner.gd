extends Node2D


# Get pipes
const PIPE_SCENE_TRIPLE = preload("res://Scenes/triple_pipe.tscn")
const PIPE_SCENE_DOUBLE = preload("res://Scenes/double_pipe.tscn")
const PIPE_SCENE_SINGLE = preload("res://Scenes/single_pipe.tscn")

const pipe_death_speed_multiplier: float = 3 # How much to multiply pipe speed when player dies
const pipe_death_rate_divisor: float = 3 # How much to divide spawn rate when player dies
const pipe_speed_multiplier: float = 1.1 # How much to multiply pipe speed after speed increase timer is up
const pipe_rate_divisor: float = 1.1 # How much to divide spawn rate after speed increase timer is up
const gravity_multiplier_increase = 1.05 # How much to increase the gravity multiplier after speed increase timer is up
const jump_multipler_increase = 1.025 # How much to increase player jump velocity after speed increase timer is up
const pipe_speed_default = -400 # Default speed of pipes before it's increased
const y_move_chance_start: float = 0.1 # Chance a newly spawned pipe moves vertically
const y_move_chance_multiplier: float = 1.1 # Chance multiplier on each speed increase tick
const y_move_chance_max: float = 0.6 # Chance never goes above this
const y_speed_start: float = 100 # Starting peak vertical speed (px/s) of moving pipes
const y_speed_multiplier: float = 1.1 # Vertical speed multiplier on each speed increase tick
const y_speed_max: float = 350 # Vertical speed never goes above this

var pipe_elevation_max: float = 130 # Lowest height the pipes can spawn at
var pipe_elevation_min: float = -140 # Highest height the pipes can spawn at
var free_pipes: Array[Node2D] = []
var all_pipes: Array[Node2D] = [] # Array of all pipes
var triple_pipe_count: int = 8
var double_pipe_count: int = 2
var single_pipe_count: int = 1
var pipe_speed: float = pipe_speed_default
var gravity_multipler: float = 1 # Multiplier for player gravity
var jump_multiplier: float = 1 # Multiplier for player jump velocity
var y_move_chance: float = y_move_chance_start # Current chance a spawned pipe moves vertically
var y_speed: float = y_speed_start # Current peak vertical speed given to moving pipes

@onready var spawn_timer: Timer = $SpawnTimer
@onready var speed_increase_timer: Timer = $SpeedIncreaseTimer
@onready var game_manager: Node2D = %GameManager

signal speed_increased(new_speed: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_manager.game_start.connect(start_spawning)
	game_manager.double_speed.connect(multiply_pipe_speed)
	game_manager.game_over.connect(on_game_over)


func start_spawning() -> void:
	spawn_timer.start()
	speed_increase_timer.start()
	instantiate_pipes()
	spawn_pipe()


# Instantiates several pipes and adds them to free_pipes queue
func instantiate_pipes() -> void:
	# Add triple pipes
	for i in range(triple_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_TRIPLE)
	
	# Add double pipes
	for i in range(double_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_DOUBLE)
	
	# Add single pipes
	for i in range(single_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_SINGLE)


# Instantiates a new pipe and adds it to free_pipes queue
func instantiate_new_pipe(pipe: Resource) -> void:
	# Instantiate pipe
	var new_pipe = pipe.instantiate()
	
	# Set as child of this spawner
	add_child(new_pipe)
	
	# Make pipe remove itself when it reaches end of screen
	new_pipe.get_node("PipeSegmentHolder").respawn_pipe.connect(remove_pipe)
	
	# Signal to game manager to increase score when player crosses line
	new_pipe.get_node("PipeSegmentHolder/PipeScoreArea").score_increment.connect(game_manager.on_score_increment)
	
	# Add to queue and pipes array
	free_pipes.push_back(new_pipe)
	all_pipes.push_back(new_pipe)


# Puts a pipe on the right side of the screen
# This is different from create_pipe(), which instantiates a new pipe
func spawn_pipe() -> void:
	# Check if there is a pipe available
	if free_pipes.size() > 0:
		# Add random pipe from list
		var random_index = randi_range(0, free_pipes.size() - 1)
		initialize_pipe(free_pipes[random_index])
		
		# Remove pipe from list
		free_pipes.remove_at(random_index)
	
	# If there is no pipe available, instantiate new ones
	else:
		instantiate_pipes()


func _on_spawn_timer_timeout() -> void:
	spawn_pipe()


func initialize_pipe(pipe_node: Node2D) -> void:
	# Set y position randomly
	pipe_node.position.y = randf_range(pipe_elevation_min, pipe_elevation_max)
	
	# Start movement
	var holder = pipe_node.get_node("PipeSegmentHolder")
	holder.set_move_pipe(true)
	holder.set_pipe_speed(pipe_speed)
	
	# Roll once per spawn to see if this pipe bobs up and down
	if randf() < y_move_chance:
		# Random starting phase so neighboring pipes are out of sync
		holder.start_y_motion(y_speed, randf_range(0.0, TAU))
	else:
		holder.stop_y_motion()
	
	# Call initialize pipe function if it exists
	var pipe_script = pipe_node.get_script()
	if pipe_script:
		pipe_node.init_pipe()


# Removes pipe from scene and adds it to the free_pipes array
func remove_pipe(pipe_node: Node2D) -> void:
	# Stop pipe movement
	pipe_node.set_move_pipe(false)
	
	# Reset vertical motion so the recycled pipe starts clean
	pipe_node.stop_y_motion()
	
	# Set position to offscreen (where it will start moving again)
	pipe_node.global_position.x = global_position.x
	
	# Add this to queue
	var pipe_parent = pipe_node.get_parent()
	free_pipes.push_back(pipe_parent)


# Multiplies pipe speed and spawn rate after a player dies
func multiply_pipe_speed() -> void:
	# Increase pipe speed and spawn rate
	pipe_speed *= pipe_death_speed_multiplier
	spawn_timer.wait_time /= pipe_death_rate_divisor
	
	# Reset spawn timer
	spawn_timer.start()
	
	# Iterate through all pipes and speed them up
	for pipe in all_pipes:
		pipe.get_node("PipeSegmentHolder").set_pipe_speed(pipe_speed)
	
	# Send signal
	speed_increased.emit(pipe_speed)


func _on_speed_increase_timer_timeout() -> void:
	# Increase pipe speed and spawn rate, and player gravity and jump velocity
	pipe_speed *= pipe_speed_multiplier
	spawn_timer.wait_time /= pipe_rate_divisor
	gravity_multipler *= gravity_multiplier_increase
	jump_multiplier *= jump_multipler_increase
	
	# Increase chance and speed of vertical movement (both capped)
	y_move_chance = minf(y_move_chance * y_move_chance_multiplier, y_move_chance_max)
	y_speed = minf(y_speed * y_speed_multiplier, y_speed_max)
	
	# Iterate through all pipes and speed them up
	for pipe in all_pipes:
		var holder = pipe.get_node("PipeSegmentHolder")
		holder.set_pipe_speed(pipe_speed)
		
		# Only speed up pipes already bobbing. Stationary pipes stay stationary
		if holder.is_moving_vertically():
			holder.set_y_speed(y_speed)
	
	# Send signal
	speed_increased.emit(pipe_speed)


func get_gravity_multiplier() -> float:
	return gravity_multipler


func get_jump_multiplier() -> float:
	return jump_multiplier


func on_game_over() -> void:
	speed_increase_timer.stop()


func get_pipe_speed_default() -> float:
	return pipe_speed_default
