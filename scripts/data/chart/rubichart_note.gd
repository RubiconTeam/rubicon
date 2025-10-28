class_name RubiChartNote extends Resource

@export var id : String
@export var type : String
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
