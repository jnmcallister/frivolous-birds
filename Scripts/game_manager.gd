extends Node2D

enum GameState{
	START_MENU,
	PLAYING,
	GAME_OVER
}

var score: int = 0
var dead_players: int = 0
var game_state: GameState = GameState.START_MENU

@onready var score_display: Control = $"../UI/ScoreDisplay"
@onready var start_menu: Control = $"../UI/StartMenu"
@onready var game_over_menu: Control = $"../UI/GameOverMenu"

signal game_start
signal double_speed

func _ready() -> void:
	game_over_menu.hide()


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
		# End the game
		game_over_menu.show()


func _on_start_button_pressed() -> void:
	game_start.emit()
	start_menu.hide()


func _on_game_over_button_pressed() -> void:
	get_tree().reload_current_scene() # Restart game
