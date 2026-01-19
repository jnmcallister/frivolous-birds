extends Node2D

enum GameState{
	START_MENU,
	PLAYING,
	GAME_OVER
}

var score: int = 0
var dead_players: int = 0
var game_state: GameState = GameState.START_MENU
var allow_jump_from_start: bool = false # If true, players can press either jump button in the start menu to start the game
var allow_quick_restart: bool = false # If true, pressing space in game over menu will restart the game

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

var preloaded_scene = preload("res://Scenes/game.tscn")

# Time freeze FX
var player_first_death_time_freeze: float = 0.12 # Duration of time freeze after player first dies
var player_second_death_time_freeze: float = 0.8 # Duration of time freeze after player second dies
var player_death_time_slowdown: float = 0.05 # How fast should time move during time freeze

const PLAYER_1_JUMP_ACTION: String = "jumpP1"
const PLAYER_2_JUMP_ACTION: String = "jumpP2"
const RESTART_ACTION: String = "restart"

@onready var top_area: Area2D = $"../Environment/TopArea"
@onready var score_display: Control = $"../UI/ScoreDisplay"
@onready var taunt_label: RichTextLabel = $"../UI/TauntText/TauntLabel"
@onready var taunt_timer: Timer = $"../UI/TauntText/TauntTimer"
@onready var time_freezer: Node = %TimeFreezer
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound

# Buttons
@onready var start_button: Button = $"../UI/StartMenu/StartButton"
@onready var game_over_button: Button = $"../UI/GameOverMenu/GameOverButton"
@onready var settings_button: Button = $"../UI/StartMenu/SettingsButton"

# Menus
@onready var start_menu: Control = $"../UI/StartMenu"
@onready var game_over_menu: Control = $"../UI/GameOverMenu"
@onready var settings_menu: Control = $"../UI/SettingsMenu"

# Menu things
@onready var game_over_anim_player: AnimationPlayer = $"../UI/GameOverMenu/GameOverAnimPlayer"
@onready var game_over_wait_timer: Timer = $"../UI/GameOverMenu/GameOverWaitTimer"
@onready var version_number_text: Label = $"../UI/StartMenu/VersionNumber"

signal game_start
signal double_speed
signal game_over
signal player_died(is_player_1: bool)

func _ready() -> void:
	# Hide menus
	game_over_menu.hide()
	taunt_label.hide()
	settings_menu.hide()
	
	# Connect signals
	settings_menu.get_node("SettingsBackButton").pressed.connect(_on_settings_back_button_pressed)
	
	# Select start button as default
	start_button.grab_focus()
	
	# Set version number
	version_number_text.text = "Version " + ProjectSettings.get_setting("application/config/version")


func _input(event: InputEvent) -> void:
	# Start menu hotkeys
	if game_state == GameState.START_MENU:
		
		# Allow player to press either jump button to start the game
		if allow_jump_from_start:
			if event.is_action_pressed(PLAYER_1_JUMP_ACTION) or event.is_action_pressed(PLAYER_2_JUMP_ACTION):
				start_game()
	
	# Game over screen hotkeys
	if game_state == GameState.GAME_OVER:
		
		# Allow player to press a key to quickly restart
		if allow_quick_restart:
			if event.is_action_pressed(RESTART_ACTION):
				restart_game()


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
func on_player_died(is_player_1: bool) -> void:
	# Send signal
	player_died.emit(is_player_1)
	
	# Check how many players are left
	dead_players += 1
	if dead_players == 1:
		# Double the pipe speed
		double_speed.emit()
		
		# Freeze time
		time_freezer.freeze_time(player_first_death_time_freeze, player_death_time_slowdown)
		
	elif dead_players == 2:
		
		# End the game
		end_game()
		


func start_game() -> void:
	game_start.emit()
	start_menu.hide()
	game_state = GameState.PLAYING


# Call when the game is over
func end_game() -> void:
	# Freeze time
	time_freezer.freeze_time(player_second_death_time_freeze, player_death_time_slowdown)
	
	# Play SFX
	game_over_sound.play()
	
	# Show game over menu (after delay)
	game_over_wait_timer.start() # Wait before playing fade in animation and showing menu
	
	# Communicate that it's game over
	game_over.emit()
	game_state = GameState.GAME_OVER


func _on_start_button_pressed() -> void:
	start_game()


func _on_settings_button_pressed() -> void:
	# Show settings menu only
	settings_menu.show()
	start_menu.hide()
	
	# Focus on back button
	settings_menu.get_node("SettingsBackButton").grab_focus()


func _on_settings_back_button_pressed() -> void:
	# Hide settings menu
	settings_menu.hide()
	start_menu.show()
	
	# Focus on start menu settings button
	settings_button.grab_focus()


func restart_game() -> void:
	
	# Reset time scale
	Engine.time_scale = 1
	
	# Reload scene using preloaded scene
	get_tree().change_scene_to_packed(preloaded_scene)


func _on_game_over_button_pressed() -> void:
	restart_game()


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


func _on_game_over_wait_timer_timeout() -> void:
	game_over_menu.show()
	game_over_anim_player.play("fade_in") # Play animation
	game_over_button.grab_focus()
