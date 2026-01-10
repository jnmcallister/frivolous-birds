extends HSlider

@export var bus_name: String

var bus_index: int

@onready var slider_click_sound_player: AudioStreamPlayer = $SliderClickSoundPlayer

func _ready() -> void:
	# Get index of bus (bus functions use indicies instead of strings)
	bus_index = AudioServer.get_bus_index(bus_name)
	
	# Connect signal
	value_changed.connect(_on_value_changed)
	
	# Set initial value of slider
	value = db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)
	
	# Set bus of slider click sound player
	slider_click_sound_player.bus = bus_name

func _on_value_changed(val: float) -> void:
	# Set volume of bus to slider value
	AudioServer.set_bus_volume_db(
		bus_index, linear_to_db(val)
	)


func _on_drag_started() -> void:
	# Start playing sounds
	slider_click_sound_player.play()


func _on_drag_ended(_value_changed: bool) -> void:
	# Stop playing sounds
	slider_click_sound_player.stop()
