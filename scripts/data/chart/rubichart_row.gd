class_name RubiChartRow extends Resource

@export var offset : int
@export var quant : RubiChart.Quant
@export var starts : Array[RubiChartNote]
@export var ends : Array[RubiChartNote]

var section : RubiChartSection :
	get: 
		return _section
	set(value):
		_section = value
		_measure_time = _section.measure + (offset / float(quant))

var measure_time : float:
	get:
		return _measure_time

var millisecond_time : float:
	get:
		return _millisecond_time

var _section : RubiChartSection
var _measure_time : float
var _millisecond_time : float

func initaliize(time_changes : Array[RubiconTimeChange]) -> void:
	_millisecond_time = RubiconTimeChange.get_millisecond_at_measure(time_changes, measure_time)

func get_note_with_id(id : String, include_ends : bool = false) -> RubiChartNote:
	var note : RubiChartNote = starts.filter(func(x : RubiChartNote) -> bool : return x.id == id).front()
	if note == null and include_ends:
		note = ends.filter(func(x : RubiChartNote) -> bool : return x.id == id).front()
	
	return note

func has_note_with_id(id : String, include_ends : bool = false) -> bool:
	return not starts.filter(func(x : RubiChartNote) -> bool : return x.id == id).is_empty() or (include_ends and not ends.filter(func(x : RubiChartNote) -> bool : return x.id == id).is_empty())
