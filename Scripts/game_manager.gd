extends Node2D

var score: int = 0

@onready var score_display: Control = $Control/ScoreDisplay

func on_score_increment() -> void:
	score += 1
	score_display.update_score(score)
