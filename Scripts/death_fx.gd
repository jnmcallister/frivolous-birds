extends Control

const RESPAWN_FADE_TIME: float = 0.3 # Seconds for the screen FX to fade out when a player respawns

@onready var game_manager: Node2D = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var red_fx: TextureRect = $RedFX
@onready var green_fx: TextureRect = $GreenFX

var red_died_most_recently: bool = false # True when red bird is the most recent death, false when it's green
var fade_tween: Tween # Fade-out used on respawn. Kept so it can be cancelled if a player dies again

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_manager.player_died.connect(on_player_died)
	game_manager.double_speed.connect(on_first_player_died)
	game_manager.game_over.connect(on_second_player_died)
	game_manager.player_respawned.connect(on_player_respawned)


func on_player_died(is_player_1: bool):
	red_died_most_recently = is_player_1


func on_first_player_died():
	# If a respawn fade is still running, cancel it so it cannot fight the new animation
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	if red_died_most_recently:
		animation_player.play("green_show")
	else:
		animation_player.play("red_show")


# A dead player was revived, so fade out whichever screen FX is showing.
# This is done with a tween so no new animation needs to be added in the editor.
func on_player_respawned(_is_player_1: bool):
	# Stop the fade-in animation if it is still running
	animation_player.stop()
	
	# Fade both overlays to transparent at the same time
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(red_fx, "modulate:a", 0.0, RESPAWN_FADE_TIME)
	fade_tween.tween_property(green_fx, "modulate:a", 0.0, RESPAWN_FADE_TIME)


func on_second_player_died():
	if red_died_most_recently:
		animation_player.play("red_hide")
	else:
		animation_player.play("green_hide")
