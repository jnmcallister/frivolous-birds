extends Control

@onready var game_manager: Node2D = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var red_died_most_recently: bool = false # True when red bird is the most recent death, false when it's green

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_manager.player_died.connect(on_player_died)
	game_manager.double_speed.connect(on_first_player_died)
	game_manager.game_over.connect(on_second_player_died)


func on_player_died(is_player_1: bool):
	red_died_most_recently = is_player_1


func on_first_player_died():
	if red_died_most_recently:
		animation_player.play("green_show")
	else:
		animation_player.play("red_show")


func on_second_player_died():
	if red_died_most_recently:
		animation_player.play("red_hide")
	else:
		animation_player.play("green_hide")
