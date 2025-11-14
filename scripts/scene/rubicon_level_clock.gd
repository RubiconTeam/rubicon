@tool
class_name RubiconLevelClock extends Node

@export var offset : float = 0.0

@export_group("Time", "time_")
@export var time_milliseconds : float:
	get:
		var is_on_animation : bool = animation_player != null and (not animation_player.assigned_animation.is_empty() or animation_player.is_playing())
		if not is_on_animation:
			return 0
		
		return maxf((_animation_player.current_animation_position + offset) * 1000.0, 0.0)
	set(val):
		var is_on_animation : bool = animation_player != null and (not animation_player.assigned_animation.is_empty() or animation_player.is_playing())
		if not is_on_animation:
			return
		
		_animation_player.seek(val - offset, true)

@export var time_measure : float:
	get:
		return RubiconTimeChange.get_measure_at_millisecond(get_time_changes(), time_milliseconds)
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_measure(get_time_changes(), val)

@export var time_beat : float:
	get:
		return RubiconTimeChange.get_beat_at_millisecond(get_time_changes(), time_milliseconds)
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_beat(get_time_changes(), val)

@export var time_step : float:
	get:
		return RubiconTimeChange.get_step_at_millisecond(get_time_changes(), time_milliseconds)
	set(val):
		time_milliseconds = RubiconTimeChange.get_millisecond_at_step(get_time_changes(), val)

var level_2d : RubiconLevel2D:
	get:
		return _level_2d

var level_3d : RubiconLevel3D:
	get:
		return _level_3d

var animation_player : AnimationPlayer:
	get:
		return _animation_player

var _level_2d : RubiconLevel2D
var _level_3d : RubiconLevel3D
var _animation_player : AnimationPlayer

var _current_frame_time : float
var _relative_time_offset : float

func get_time_precise() -> float:
	return _current_frame_time + (Time.get_unix_time_from_system() - _relative_time_offset) * 1000.0

func get_time_changes() -> Array[RubiconTimeChange]:
	if _level_2d != null and _level_2d.metadata != null:
		return _level_2d.metadata.time_changes
	
	if _level_3d != null and _level_3d.metadata != null:
		return _level_3d.metadata.time_changes
	
	return []

func _validate_property(property: Dictionary) -> void:
	if property.name.begins_with("time_"):
		property.usage = PROPERTY_USAGE_EDITOR

func _process(delta: float) -> void:
	_current_frame_time = time_milliseconds
	_relative_time_offset = Time.get_unix_time_from_system()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if _level_2d != null:
				_level_2d.clock = null
				_level_2d = null
			
			if _level_3d != null:
				_level_3d.clock = null
				_level_3d = null
			
			var parent : Node = get_parent()
			if parent is RubiconLevel2D:
				_level_2d = parent
				
				if _level_2d.clock == null:
					_level_2d.clock = self
				else:
					printerr(tr("WARNING!! Having more than one RubiconLevelClock in a level can lead to problems!"))
				
				return
			
			if parent is RubiconLevel3D:
				_level_3d = parent
				
				if _level_3d.clock == null:
					_level_3d.clock = self
				else:
					printerr(tr("WARNING!! Having more than one RubiconLevelClock in a level can lead to problems!"))
				
				return
			
		NOTIFICATION_CHILD_ORDER_CHANGED:
			_animation_player = null
			for child in get_children():
				if child is AnimationPlayer:
					_animation_player = child
					break

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	
	if level_2d == null and level_3d == null:
		warnings.append(tr("This node relies on being parented to a RubiconLevel! Please parent this node to a RubiconLevel2D or RubiconLevel3D"))
	
	if _animation_player == null:
		warnings.append(tr("No AnimationPlayer child found! The clock relies on its first AnimationPlayer child to function."))
	
	return warnings

static func measure_to_millisecond(measure : float, bpm : float, time_signature_numerator : float) -> float:
	return measure * (60000.0 / (bpm / time_signature_numerator))

static func beats_to_millisecond(beat : float, bpm : float) -> float:
	return beat * (60000.0 / bpm)

static func steps_to_millisecond(step : float, bpm : float, time_signature_denominator : float) -> float:
	return step * (60000.0 / bpm / time_signature_denominator)

static func measure_to_beats(measure : float, time_signature_numerator : float) -> float:
	return measure * time_signature_numerator

static func measure_to_steps(measure : float, time_signature_numerator : float, time_signature_denominator : float) -> float:
	return beats_to_steps(measure_to_beats(measure, time_signature_numerator), time_signature_denominator)

static func beats_to_steps(beats : float, time_signature_denominator : float) -> float:
	return beats * time_signature_denominator

static func beats_to_measures(beats : float, time_signature_numerator : float) -> float:
	return beats / time_signature_numerator

static func steps_to_measures(steps : float, time_signature_numerator : float, time_signature_denominator : float) -> float:
	return steps / (time_signature_numerator * time_signature_denominator)
