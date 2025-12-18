# If a player hangs out here too long, start taunting the player

extends Area2D


signal cheating_taunt

var taunting_activated: bool = false
var players_in_area: int = 0

@onready var delay: Timer = $Delay

func _on_body_entered(body: Node2D) -> void:
	# Check if this is actually a player
	if body is player:
		players_in_area += 1
		if players_in_area >= 1:
			# Start timer
			delay.start()


func _on_delay_timeout() -> void:
	cheating_taunt.emit()
	taunting_activated = true


func _on_body_exited(body: Node2D) -> void:
	# Only start taunting if the player(s) have been here too long
	if body is player:
		players_in_area -= 1
		
		if !taunting_activated:
			delay.stop()
