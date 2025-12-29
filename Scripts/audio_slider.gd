extends HSlider

@export var bus_name: String

var bus_index: int

func _ready() -> void:
	# Get index of bus (bus functions use indicies instead of strings)
	bus_index = AudioServer.get_bus_index(bus_name)
	
	# Connect signal
	value_changed.connect(_on_value_changed)
	
	# Set initial value of slider
	value = db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)

func _on_value_changed(val: float) -> void:
	# Set volume of bus to slider value
	AudioServer.set_bus_volume_db(
		bus_index, linear_to_db(val)
	)
