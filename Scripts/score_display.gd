extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func update_score(score: int) -> void:
	rich_text_label.text = "Score: " + str(score)
