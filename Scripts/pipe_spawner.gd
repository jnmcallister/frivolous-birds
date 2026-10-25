extends Node2D


# Get pipes
const PIPE_SCENE_TRIPLE = preload("res://Scenes/triple_pipe.tscn")
const PIPE_SCENE_DOUBLE = preload("res://Scenes/double_pipe.tscn")
const PIPE_SCENE_SINGLE = preload("res://Scenes/single_pipe.tscn")

# Collectible heart that revives a dead player (NORMAL mode only)
const HEART_SCENE = preload("res://Scenes/heart.tscn")

# =============================================================================
# NORMAL MODE values. Tune these freely, new features go here.
# =============================================================================
const pipe_death_speed_multiplier: float = 3 # How much to multiply pipe speed when player dies
const pipe_death_rate_divisor: float = 3 # How much to divide spawn rate when player dies
const pipe_speed_multiplier: float = 1.08 # How much to multiply pipe speed after speed increase timer is up
const pipe_rate_divisor: float = 1.08 # How much to divide spawn rate after speed increase timer is up
const gravity_multiplier_increase = 1.055 # How much to increase the gravity multiplier after speed increase timer is up
const jump_multipler_increase = 1.06 # How much to increase player jump velocity after speed increase timer is up
const pipe_speed_default = -400 # Default speed of pipes before it's increased
const pipe_elevation_max: float = 130 # Lowest height the pipes can spawn at
const pipe_elevation_min: float = -140 # Highest height the pipes can spawn at
const triple_pipe_count: int = 8 # Pipe mix: pipes are picked at random from the pool, so counts set how often each type appears
const double_pipe_count: int = 2
const single_pipe_count: int = 1
const pipe_spawn_interval: float = 3.0 # Seconds between pipe spawns at the start
const pipe_speed_increase_interval: float = 5.0 # Seconds between each speed increase

# Vertical pipe movement (NORMAL MODE ONLY, classic never uses these)
const y_move_chance_start: float = 0.08 # Chance a newly spawned pipe moves vertically
const y_move_chance_multiplier: float = 1.2 # Chance multiplier on each speed increase tick
const y_move_chance_max: float = 0.6 # Chance never goes above this
const y_speed_start: float = 150 # Starting peak vertical speed (px/s) of moving pipes
const y_speed_multiplier: float = 1.08 # Vertical speed multiplier on each speed increase tick
const y_speed_max: float = 350 # Vertical speed never goes above this

# =============================================================================
# CLASSIC MODE values. Frozen baseline, do not change.
# Copied from the normal values as they were when classic mode was added.
# =============================================================================
const CLASSIC_PIPE_DEATH_SPEED_MULTIPLIER: float = 3
const CLASSIC_PIPE_DEATH_RATE_DIVISOR: float = 3
const CLASSIC_PIPE_SPEED_MULTIPLIER: float = 1.1
const CLASSIC_PIPE_RATE_DIVISOR: float = 1.1
const CLASSIC_GRAVITY_MULTIPLIER_INCREASE: float = 1.05
const CLASSIC_JUMP_MULTIPLIER_INCREASE: float = 1.025
const CLASSIC_PIPE_SPEED_DEFAULT: float = -400
const CLASSIC_PIPE_ELEVATION_MAX: float = 130
const CLASSIC_PIPE_ELEVATION_MIN: float = -140
const CLASSIC_TRIPLE_PIPE_COUNT: int = 8
const CLASSIC_DOUBLE_PIPE_COUNT: int = 2
const CLASSIC_SINGLE_PIPE_COUNT: int = 1
const CLASSIC_PIPE_SPAWN_INTERVAL: float = 3.0
const CLASSIC_PIPE_SPEED_INCREASE_INTERVAL: float = 5.0

# =============================================================================
# ACTIVE values. These are what the code actually uses while playing.
# They are filled in by apply_mode_settings() when the game starts.
# =============================================================================
var active_pipe_death_speed_multiplier: float = pipe_death_speed_multiplier
var active_pipe_death_rate_divisor: float = pipe_death_rate_divisor
var active_pipe_speed_multiplier: float = pipe_speed_multiplier
var active_pipe_rate_divisor: float = pipe_rate_divisor
var active_gravity_multiplier_increase: float = gravity_multiplier_increase
var active_jump_multiplier_increase: float = jump_multipler_increase
var active_elevation_max: float = pipe_elevation_max
var active_elevation_min: float = pipe_elevation_min
var active_triple_pipe_count: int = triple_pipe_count
var active_double_pipe_count: int = double_pipe_count
var active_single_pipe_count: int = single_pipe_count
var active_spawn_interval: float = pipe_spawn_interval
var active_speed_increase_interval: float = pipe_speed_increase_interval

var free_pipes: Array[Node2D] = []
var all_pipes: Array[Node2D] = [] # Array of all pipes
var pipe_speed: float = pipe_speed_default
var gravity_multipler: float = 1 # Multiplier for player gravity
var jump_multiplier: float = 1 # Multiplier for player jump velocity
var y_move_chance: float = y_move_chance_start # Current chance a spawned pipe moves vertically (normal mode only)
var y_speed: float = y_speed_start # Current peak vertical speed given to moving pipes (normal mode only)

# Heart spawning (NORMAL mode only).
# When pending_heart is true, the next pipe spawned is forced to be a double or
# triple pipe and gets a heart placed in one of its gaps.
var pending_heart: bool = false
var pending_heart_is_red: bool = true # True = red heart (revives player 1), false = green heart

@onready var spawn_timer: Timer = $SpawnTimer
@onready var speed_increase_timer: Timer = $SpeedIncreaseTimer
@onready var game_manager: Node2D = %GameManager

signal speed_increased(new_speed: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_manager.game_start.connect(start_spawning)
	game_manager.double_speed.connect(multiply_pipe_speed)
	game_manager.game_over.connect(on_game_over)
	game_manager.player_respawned.connect(revert_pipe_speed)


# Copies either the classic or the normal values into the active_ variables.
# Called once from start_spawning(), never from _ready(), because the mode is
# only chosen when a start button is pressed.
func apply_mode_settings() -> void:
	if GameModeConfig.current_mode == GameModeConfig.GameMode.CLASSIC:
		pipe_speed = CLASSIC_PIPE_SPEED_DEFAULT
		active_pipe_death_speed_multiplier = CLASSIC_PIPE_DEATH_SPEED_MULTIPLIER
		active_pipe_death_rate_divisor = CLASSIC_PIPE_DEATH_RATE_DIVISOR
		active_pipe_speed_multiplier = CLASSIC_PIPE_SPEED_MULTIPLIER
		active_pipe_rate_divisor = CLASSIC_PIPE_RATE_DIVISOR
		active_gravity_multiplier_increase = CLASSIC_GRAVITY_MULTIPLIER_INCREASE
		active_jump_multiplier_increase = CLASSIC_JUMP_MULTIPLIER_INCREASE
		active_elevation_max = CLASSIC_PIPE_ELEVATION_MAX
		active_elevation_min = CLASSIC_PIPE_ELEVATION_MIN
		active_triple_pipe_count = CLASSIC_TRIPLE_PIPE_COUNT
		active_double_pipe_count = CLASSIC_DOUBLE_PIPE_COUNT
		active_single_pipe_count = CLASSIC_SINGLE_PIPE_COUNT
		active_spawn_interval = CLASSIC_PIPE_SPAWN_INTERVAL
		active_speed_increase_interval = CLASSIC_PIPE_SPEED_INCREASE_INTERVAL
	else:
		pipe_speed = pipe_speed_default
		active_pipe_death_speed_multiplier = pipe_death_speed_multiplier
		active_pipe_death_rate_divisor = pipe_death_rate_divisor
		active_pipe_speed_multiplier = pipe_speed_multiplier
		active_pipe_rate_divisor = pipe_rate_divisor
		active_gravity_multiplier_increase = gravity_multiplier_increase
		active_jump_multiplier_increase = jump_multipler_increase
		active_elevation_max = pipe_elevation_max
		active_elevation_min = pipe_elevation_min
		active_triple_pipe_count = triple_pipe_count
		active_double_pipe_count = double_pipe_count
		active_single_pipe_count = single_pipe_count
		active_spawn_interval = pipe_spawn_interval
		active_speed_increase_interval = pipe_speed_increase_interval


func start_spawning() -> void:
	# Load the values for the selected mode first
	apply_mode_settings()
	
	# Timer wait times come from the script now, so they can differ per mode
	# (the wait_time values saved in pipe_spawner.tscn are overridden here)
	spawn_timer.wait_time = active_spawn_interval
	speed_increase_timer.wait_time = active_speed_increase_interval
	
	spawn_timer.start()
	speed_increase_timer.start()
	instantiate_pipes()
	spawn_pipe()
	
	# Tell listeners (ground, parallax) the real starting speed, since they
	# could only guess at the speed before the mode was chosen
	speed_increased.emit(pipe_speed)


# Instantiates several pipes and adds them to free_pipes queue
func instantiate_pipes() -> void:
	# Add triple pipes
	for i in range(active_triple_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_TRIPLE)
	
	# Add double pipes
	for i in range(active_double_pipe_count):
		instantiate_new_pipe(PIPE_SCENE_DOUBLE)
	
	# Add single pipes
	for i in range(active_single_pipe_count):
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
		var pipe_index: int
		
		if pending_heart:
			# A heart is waiting, so this pipe must have a gap to hold it (double or triple)
			pipe_index = find_heart_capable_pipe_index()
			
			# No double/triple pipe is free right now, so make a new double pipe
			# (it gets added to the end of free_pipes)
			if pipe_index == -1:
				instantiate_new_pipe(PIPE_SCENE_DOUBLE)
				pipe_index = free_pipes.size() - 1
		else:
			# Normal behavior: random pipe from the list
			pipe_index = randi_range(0, free_pipes.size() - 1)
		
		var chosen_pipe: Node2D = free_pipes[pipe_index]
		initialize_pipe(chosen_pipe)
		
		# Remove pipe from list
		free_pipes.remove_at(pipe_index)
		
		# Heart is attached AFTER initialize_pipe, because triple pipes randomize
		# their middle segment height there and the gap positions depend on it
		if pending_heart:
			attach_heart(chosen_pipe)
	
	# If there is no pipe available, instantiate new ones
	else:
		instantiate_pipes()


func _on_spawn_timer_timeout() -> void:
	spawn_pipe()


func initialize_pipe(pipe_node: Node2D) -> void:
	# Set y position randomly
	pipe_node.position.y = randf_range(active_elevation_min, active_elevation_max)
	
	# Start movement
	var holder = pipe_node.get_node("PipeSegmentHolder")
	holder.set_move_pipe(true)
	holder.set_pipe_speed(pipe_speed)
	
	# Vertical bobbing is a NORMAL mode feature. Classic pipes never move vertically.
	# For normal mode, roll once per spawn to see if this pipe bobs up and down
	if GameModeConfig.current_mode != GameModeConfig.GameMode.CLASSIC and randf() < y_move_chance:
		# Random starting phase so neighboring pipes are out of sync
		holder.start_y_motion(y_speed, randf_range(0.0, TAU))
	else:
		holder.stop_y_motion()
	
	# Call initialize pipe function if it exists
	var pipe_script = pipe_node.get_script()
	if pipe_script:
		pipe_node.init_pipe()


# Removes pipe from scene and adds it to the free_pipes array
# NOTE: pipe_node here is actually the PipeSegmentHolder (it emits itself)
func remove_pipe(pipe_node: Node2D) -> void:
	# Stop pipe movement
	pipe_node.set_move_pipe(false)
	
	# Reset vertical motion so the recycled pipe starts clean
	pipe_node.stop_y_motion()
	
	# Remove any heart that was never collected, so it does not come back with the recycled pipe
	free_hearts_on_holder(pipe_node)
	
	# Set position to offscreen (where it will start moving again)
	pipe_node.global_position.x = global_position.x
	
	# Add this to queue
	var pipe_parent = pipe_node.get_parent()
	free_pipes.push_back(pipe_parent)


# Multiplies pipe speed and spawn rate after a player dies
func multiply_pipe_speed() -> void:
	# Increase pipe speed and spawn rate
	pipe_speed *= active_pipe_death_speed_multiplier
	spawn_timer.wait_time /= active_pipe_death_rate_divisor
	
	# Reset spawn timer
	spawn_timer.start()
	
	# Iterate through all pipes and speed them up
	for pipe in all_pipes:
		pipe.get_node("PipeSegmentHolder").set_pipe_speed(pipe_speed)
	
	# Send signal
	speed_increased.emit(pipe_speed)


# Undoes multiply_pipe_speed() when a dead player is respawned.
# Division and multiplication commute, so any speed increase ticks that happened
# in between are preserved correctly.
func revert_pipe_speed(_is_player_1: bool) -> void:
	# Restore the pipe speed and spawn rate from before the death
	pipe_speed /= active_pipe_death_speed_multiplier
	spawn_timer.wait_time *= active_pipe_death_rate_divisor
	
	# Restart the spawn timer so the next pipe is not spawned with a leftover short delay
	spawn_timer.start()
	
	# Iterate through all pipes and slow them down
	for pipe in all_pipes:
		pipe.get_node("PipeSegmentHolder").set_pipe_speed(pipe_speed)
	
	# Send signal (ground and parallax follow this)
	speed_increased.emit(pipe_speed)


func _on_speed_increase_timer_timeout() -> void:
	# Increase pipe speed and spawn rate, and player gravity and jump velocity
	pipe_speed *= active_pipe_speed_multiplier
	spawn_timer.wait_time /= active_pipe_rate_divisor
	gravity_multipler *= active_gravity_multiplier_increase
	jump_multiplier *= active_jump_multiplier_increase
	
	# Vertical movement ramp-up is NORMAL mode only.
	# Increase chance and speed of vertical movement (both capped)
	var vertical_enabled: bool = GameModeConfig.current_mode != GameModeConfig.GameMode.CLASSIC
	if vertical_enabled:
		y_move_chance = minf(y_move_chance * y_move_chance_multiplier, y_move_chance_max)
		y_speed = minf(y_speed * y_speed_multiplier, y_speed_max)
	
	# Iterate through all pipes and speed them up
	for pipe in all_pipes:
		var holder = pipe.get_node("PipeSegmentHolder")
		holder.set_pipe_speed(pipe_speed)
		
		# Only speed up pipes already bobbing. Stationary pipes stay stationary
		if vertical_enabled and holder.is_moving_vertically():
			holder.set_y_speed(y_speed)
	
	# Send signal
	speed_increased.emit(pipe_speed)


func get_gravity_multiplier() -> float:
	return gravity_multipler


func get_jump_multiplier() -> float:
	return jump_multiplier


func on_game_over() -> void:
	speed_increase_timer.stop()
	
	# Both players are dead, so no heart can help anymore
	pending_heart = false
	clear_hearts()


# Used by the ground before a game starts, when no mode has been chosen yet.
# Always the classic default. The real starting speed is sent through the
# speed_increased signal in start_spawning().
func get_pipe_speed_default() -> float:
	return CLASSIC_PIPE_SPEED_DEFAULT


# =============================================================================
# HEART SPAWNING (NORMAL mode only)
# =============================================================================

# Called by the game manager when the heart timer ends.
# The next spawned pipe will be a double or triple pipe that carries the heart.
func queue_heart(is_red: bool) -> void:
	pending_heart = true
	pending_heart_is_red = is_red


# Returns the index (in free_pipes) of a random free pipe that has gaps, or -1 if none.
# Double and triple pipes have a "TopSegment" node. Single pipes do not.
func find_heart_capable_pipe_index() -> int:
	var candidates: Array[int] = []
	for i in range(free_pipes.size()):
		if free_pipes[i].get_node("PipeSegmentHolder").has_node("TopSegment"):
			candidates.append(i)
	
	if candidates.is_empty():
		return -1
	return candidates[randi_range(0, candidates.size() - 1)]


# Creates a heart and places it at the exact center of the correct gap of this pipe.
# Green heart: upper gap. Red heart: lower gap. A double pipe has only one gap, so both use it.
func attach_heart(pipe_node: Node2D) -> void:
	var holder: Node2D = pipe_node.get_node("PipeSegmentHolder")
	var gap_centers: Array[float] = get_gap_centers(holder)
	
	# Safety: no gap found, so keep the heart pending for the next pipe
	if gap_centers.is_empty():
		return
	
	# Gaps are sorted top to bottom, so the first is the upper gap and the last is the lower gap
	var gap_y: float = gap_centers.back() if pending_heart_is_red else gap_centers[0]
	
	var heart: Heart = HEART_SCENE.instantiate()
	heart.is_red = pending_heart_is_red
	heart.position = Vector2(0, gap_y) # Local to the holder, so it follows the pipe
	holder.add_child(heart)
	
	# Tell the game manager when the heart is collected
	heart.collected.connect(game_manager.on_heart_collected)
	
	# The heart is placed, so nothing is pending anymore
	pending_heart = false


# Finds the vertical center of every gap in a pipe, in holder-local coordinates, sorted top to bottom.
# It measures the real killzone sizes instead of using hardcoded numbers, so it stays correct
# if you change segment positions, scale_factor values or the triple pipe's random middle height.
func get_gap_centers(holder: Node2D) -> Array[float]:
	# Collect the vertical span (top edge, bottom edge) of every pipe segment
	var spans: Array[Vector2] = []
	for child in holder.get_children():
		# Pipe segments are Sprite2D nodes (the score area is an Area2D, so it is skipped)
		if child is Sprite2D:
			spans.append(get_segment_span(child))
	
	# Sort top to bottom
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	
	# A gap is the space between the bottom edge of one segment and the top edge of the next
	var centers: Array[float] = []
	for i in range(spans.size() - 1):
		centers.append((spans[i].y + spans[i + 1].x) * 0.5)
	return centers


# Returns Vector2(top_edge, bottom_edge) of a pipe segment's killzone, in holder-local coordinates.
func get_segment_span(segment: Node2D) -> Vector2:
	var killzone_node: Node2D = segment.get_node("Killzone")
	var shape_node: CollisionShape2D = killzone_node.get_node("CollisionShape2D")
	
	# Half height = shape half height x killzone scale x segment scale.
	# absf() because the top segment is flipped (scale.y = -1).
	var shape_height: float = (shape_node.shape as RectangleShape2D).size.y
	var half_height: float = shape_height * 0.5 * absf(killzone_node.scale.y) * absf(segment.scale.y)
	
	return Vector2(segment.position.y - half_height, segment.position.y + half_height)


# Removes every Heart that is a child of the given holder
func free_hearts_on_holder(holder: Node) -> void:
	for child in holder.get_children():
		if child is Heart:
			child.queue_free()


# Removes every heart currently in the world (used when the game ends)
func clear_hearts() -> void:
	for pipe in all_pipes:
		free_hearts_on_holder(pipe.get_node("PipeSegmentHolder"))
