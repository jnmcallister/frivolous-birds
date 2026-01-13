# Freeze time for a set amount of time

extends Node

@onready var freeze_timer: Timer = $FreezeTimer

# Freezes time for the amount of time set.
# Slowdown is the time scale to run at. Recommended is somewhere between 0 and 0.1
func freeze_time(duration: float, slowdown: float):
	# Start timer. When timer is done, time will unfreeze
	freeze_timer.wait_time = duration
	freeze_timer.start()
	
	# Freeze time
	Engine.time_scale = slowdown


func _on_freeze_timer_timeout() -> void:
	# Unfreeze time
	Engine.time_scale = 1
