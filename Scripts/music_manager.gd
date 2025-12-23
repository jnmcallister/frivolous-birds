extends Node

const BPM_MULTIPLIER = 0.8333 # 150 BPM / 180 BPM

@onready var two_player_stream: AudioStreamPlayer = $TwoPlayerTheme
@onready var one_player_stream: AudioStreamPlayer = $OnePlayerTheme
@onready var game_manager: Node2D = %GameManager

func _ready() -> void:
	# Connect signals
	game_manager.game_start.connect(on_game_start)
	game_manager.double_speed.connect(on_first_player_died)
	game_manager.game_over.connect(on_second_player_died)


func on_game_start() -> void:
	# Start the two player song
	two_player_stream.play()


func on_first_player_died() -> void:
	# Find the time in which the one player song needs to start from
	var start_spot = two_player_stream.get_playback_position() * BPM_MULTIPLIER
	
	# Stop the two player song
	two_player_stream.stop()
	
	# Start the one player song
	one_player_stream.play(start_spot)


func on_second_player_died() -> void:
	# Stop the one player song
	one_player_stream.stop()
