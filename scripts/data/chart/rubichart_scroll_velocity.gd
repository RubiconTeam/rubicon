class_name RubiChartScrollVelocity extends Resource

@export var measure_time : float
@export_range(0, 100, 0.001, "or_greater") var multiplier : float = 1

var millisecond_time : float
var position : float

func initialize(time_changes : Array[RubiconTimeChange]) -> void:
	millisecond_time = RubiconTimeChange.get_millisecond_at_measure(time_changes, measure_time)
	position = millisecond_time

func initialize_with_previous(time_changes : Array[RubiconTimeChange], last_velocity : RubiChartScrollVelocity) -> void:
	initialize(time_changes)
	position = last_velocity.position + (millisecond_time - last_velocity.millisecond_time) * last_velocity.multiplier

static func get_graphic_position_at_millisecond(velocities : Array[RubiChartScrollVelocity], millisecond_time : float) -> float:
	for current in velocities:
		if millisecond_time < current.millisecond_time:
			continue
		
		return current.position + ((millisecond_time - current.millisecond_time) * current.multiplier)
	
	return 0
