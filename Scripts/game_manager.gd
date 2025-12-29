extends Node2D

enum GameState{
	START_MENU,
	PLAYING,
	GAME_OVER
}

var score: int = 0
var dead_players: int = 0
var game_state: GameState = GameState.START_MENU

var taunts: Array[String] = ["you're not a good person you know", 
"You think you're all clever with your \"i can fly above the obstacles\" nonsense",
"dirty cheater",
"Did you really think I wouldn't think of this?",
"This isn't even increasing your score!",
"loserhead",
"why are you still doing this?",
"oh I get it. you want to see all my dialogue",
"well, it's almost over. it's gonna loop after this one",
"you're not a good person you know",
"You think you're all clever with your \"i'm gonna watch him cycle through his dialogue again\" nonsense",
"stupid idiot",
"alright that's it, i'm decreasing your score",
"monkey brain",
"this dialogue's gonna cycle again for real, and it's gonna keep decreasing your score",
"alright, bye bye!",
"you're not a good person you know",
"just kidding, okay for real this time"]
var current_taunt: int = 0
var decrease_score_taunt: int = 12 # What line of dialogue should the player's score decrease
var decrease_score_amount: int = 9999 # How much should the player's score decrease
var taunt_mode: bool = false # Becomes true when player starts flying above the pipes

@onready var top_area: Area2D = $"../Environment/TopArea"
@onready var score_display: Control = $"../UI/ScoreDisplay"
@onready var taunt_label: RichTextLabel = $"../UI/TauntText/TauntLabel"
@onready var taunt_timer: Timer = $"../UI/TauntText/TauntTimer"

# Menus
@onready var start_menu: Control = $"../UI/StartMenu"
@onready var game_over_menu: Control = $"../UI/GameOverMenu"
@onready var settings_menu: Control = $"../UI/SettingsMenu"

signal game_start
signal double_speed
signal game_over

func _ready() -> void:
	game_over_menu.hide()
	taunt_label.hide()
	settings_menu.hide()


func on_score_increment() -> void:
	if !taunt_mode:
		score += 1
		score_display.update_score(score)


func on_score_decrease(amount: int) -> void:
	score -= amount
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
		game_over.emit()


func _on_start_button_pressed() -> void:
	game_start.emit()
	start_menu.hide()


func _on_settings_button_pressed() -> void:
	settings_menu.show()


func _on_settings_back_button_pressed() -> void:
	settings_menu.hide()


func _on_game_over_button_pressed() -> void:
	get_tree().reload_current_scene() # Restart game


func _on_top_area_cheating_taunt() -> void:
	# Start taunt mode (stop increasing score)
	taunt_mode = true
	
	# Show taunt text
	taunt_label.show()
	taunt_label.text = taunts[current_taunt]
	
	# Start taunt timer (cycles through array)
	taunt_timer.start()


func _on_taunt_timer_timeout() -> void:
	# Show different taunt text
	current_taunt += 1
	if current_taunt >= taunts.size():
		current_taunt = 0 # Reset
	taunt_label.text = taunts[current_taunt]
	
	# Check if the player's score needs to be decreased from cheating for too long
	if current_taunt == decrease_score_taunt:
		on_score_decrease(decrease_score_amount)
