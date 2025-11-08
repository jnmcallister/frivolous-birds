extends Area2D


func _on_body_entered(body: Node2D) -> void:
	# Check if this is actually a player
	if body is player:
		body.on_player_died()
