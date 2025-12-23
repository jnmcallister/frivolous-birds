extends Node

const BPM_MULTIPLIER = 0.8333 # 150 BPM / 180 BPM
const PITCH_START = 1.0 # Starting pitch of one player theme when pitching down effect starts
const PITCH_END = 0.4 # Ending pitch of one player theme after pitching down effect ends

@onready var two_player_stream: AudioStreamPlayer = $TwoPlayerTheme
@onready var one_player_stream: AudioStreamPlayer = $OnePlayerTheme
@onready var game_manager: Node2D = %GameManager
@onready var song_slowdown_timer: Timer = $SongSlowdownTimer

var pitching_down: bool = false # Becomes true when both players die. Will pitch down the song for a brief moment

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
	# Start slowdown timer
	# The song will start pitching down until the timer runs out, then it will stop.
	song_slowdown_timer.start()
	pitching_down = true


func _process(_delta: float) -> void:
	# Check if the song should be pitched down
	if pitching_down:
		# Get the new pitch scale
		var new_pitch_scale = lerp(PITCH_END, PITCH_START, song_slowdown_timer.time_left / song_slowdown_timer.wait_time)
		
		one_player_stream.pitch_scale = new_pitch_scale


func _on_song_slowdown_timer_timeout() -> void:
	# Stop the one player song
	#one_player_stream.stop()
	pitching_down = false
