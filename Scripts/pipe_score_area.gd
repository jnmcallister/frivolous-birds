extends Area2D

signal score_increment

func _on_body_entered(_body: Node2D) -> void:
	score_increment.emit()
