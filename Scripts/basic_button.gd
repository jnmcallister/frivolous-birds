extends Button

@onready var hover_sound: AudioStreamPlayer = $HoverSound
@onready var button_down_sound: AudioStreamPlayer = $ButtonDownSound
@onready var pressed_sound: AudioStreamPlayer = $PressedSound

func _on_mouse_entered() -> void:
	hover_sound.play()


func _on_button_down() -> void:
	button_down_sound.play()


func _on_pressed() -> void:
	pressed_sound.play()


func _on_focus_entered() -> void:
	if hover_sound:
		hover_sound.play()
