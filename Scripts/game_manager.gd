extends Node2D

var score: int = 0
var dead_players: int = 0

@onready var score_display: Control = $"../Control/ScoreDisplay"

signal double_speed

func on_score_increment() -> void:
	score += 1
	score_display.update_score(score)


# Called when a player dies
# If there is one player left, double the speed of pipes
# Otherwise, end the game
func on_player_died() -> void:
	# Check how many players are left
	dead_players += 1
	if dead_players == 1:
		# Double the pipe speed
		double_speed.emit()
		
	elif dead_players == 2:
		# TODO - End the game
		pass
