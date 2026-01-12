extends Area2D

enum KillzoneType{
	SNOW,
	GIRAFFE
}

@export var killzone_type: KillzoneType = KillzoneType.GIRAFFE

func _on_body_entered(body: Node2D) -> void:
	# Check if this is actually a player
	if body is player:
		body.on_player_died(killzone_type)
