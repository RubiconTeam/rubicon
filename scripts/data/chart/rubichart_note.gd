@tool
class_name RubiChartNote extends Resource

@export var id : String
@export var type : StringName
@export var metadata : Dictionary[String, Variant]

var starting_row : RubiChartRow
var ending_row : RubiChartRow

var chart : RubiChart:
	get:
		return starting_row.section.chart

func get_millisecond_start_position() -> float:
	return starting_row.millisecond_time

func get_millisecond_end_position() -> float:
	if ending_row != null:
		return ending_row.millisecond_time
	
	return get_millisecond_start_position()

func get_graphical_start_position() -> float:
	return RubiChartScrollVelocity.get_graphic_position_at_millisecond(chart.scroll_velocities, get_millisecond_start_position())

func get_graphical_end_position() -> float:
	return RubiChartScrollVelocity.get_graphic_position_at_millisecond(chart.scroll_velocities, get_millisecond_end_position())

func get_graphical_start_position_relative(time : float) -> float:
	return get_graphical_start_position() - RubiChartScrollVelocity.get_graphic_position_at_millisecond(chart.scroll_velocities, time)

func get_graphical_end_position_relative(time : float) -> float:
	return get_graphical_end_position() - RubiChartScrollVelocity.get_graphic_position_at_millisecond(chart.scroll_velocities, time)
