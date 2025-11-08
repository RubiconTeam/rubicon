@tool
@abstract class_name RubiconLevelNoteHandler extends Control

@export var settings : RubiconLevelNoteSettings

@export_group("Spawning", "spawning_")
@export var spawning_bound_maximum : float = 2000.0
@export var spawning_bound_minimum : float = -1000.0

var data : Array[RubiChartNote]
var graphics : Array[RubiconLevelNote]
var results : Array[RubiconLevelNoteHitResult]

var note_spawn_start : int = 0
var note_spawn_end : int = 0
var note_hit_index : int = 0

var _controller : RubiconLevelNoteController
var _note_pool : Dictionary[StringName, Array]

func get_controller() -> RubiconLevelNoteController:
	return _controller

@abstract func get_mode_id() -> StringName
@abstract func get_unique_id() -> StringName

@abstract func sort_graphic(data_index : int) -> void

@abstract func _autoplay_process(millisecond_position : float) -> void

func update_notes() -> void:
	if _controller == null:
		return
	
	if _controller.chart == null:
		return
	
	note_spawn_start = 0
	note_spawn_end = 0
	note_hit_index = 0
	for i in data.size():
		if graphics[i] == null:
			continue
		
		despawn_note(i)
	
	data = get_controller().chart.get_notes_of_id(get_unique_id())
	
	graphics.clear()
	graphics.resize(data.size())
	
	results.clear()
	results.resize(data.size())

func spawn_note(index : int) -> void:
	var note_type : StringName = data[index].type
	if not _note_pool.has(note_type):
		_note_pool[note_type] = Array()
	
	var graphic : RubiconLevelNote = _note_pool[note_type].pop_back()
	if graphic == null:
		var define_key : StringName = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
		var skin : RubiconLevelNoteMetadata = get_controller().get_note_database()[define_key]
		var packed : PackedScene = skin.scene
		
		graphic = packed.instantiate()
	
	graphic.initialize(self, index)
	graphic.name = "Note %s" % index
	graphics[index] = graphic
	
	add_child(graphic)
	graphic.owner = self
	sort_graphic(index)

func despawn_note(index : int) -> void:
	var note_type : StringName = data[index].type
	var graphic : RubiconLevelNote = graphics[index]
	
	remove_child(graphic)
	_note_pool[note_type].append(graphic)
	
	graphics[index] = null

func hit_note(index : int, time_when_hit : float, hit_type : RubiconLevelNoteHitResult.Hit) -> void:
	var result : RubiconLevelNoteHitResult
	if results[index] != null:
		result = results[index]
	else:
		result = RubiconLevelNoteHitResult.new()
	
	result.data_index = index
	result.scoring_hit = hit_type
	result.time_when_hit = time_when_hit

	var is_start : bool = (hit_type == RubiconLevelNoteHitResult.Hit.HIT_COMPLETE and data[index].ending_row == null) or (hit_type == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE and data[index].ending_row != null)
	var millisecond_position : float = data[index].get_millisecond_start_position() if is_start else data[index].get_millisecond_end_position()
	result.time_distance = time_when_hit - millisecond_position

	var ratings : Array[RubiconLevelNoteHitResult.Judgment]
	var hit_windows : Array[float]
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT == RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT)
		hit_windows.append(settings.judgment_window_perfect)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT == RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT)
		hit_windows.append(settings.judgment_window_great)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD == RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD)
		hit_windows.append(settings.judgment_window_good)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY == RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY)
		hit_windows.append(settings.judgment_window_okay)
	if settings.judgment_enabled & RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD == RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD:
		ratings.append(RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD)
		hit_windows.append(settings.judgment_window_bad)
	
	var rating : RubiconLevelNoteHitResult.Judgment = RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS
	for i in hit_windows.size():
		if absf(result.time_distance) <= hit_windows[i]:
			rating = ratings[i]
			break
	
	result.scoring_rating = rating
	
	var note_type : StringName = data[index].type
	var define_key : StringName = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
	get_controller().get_note_database()[define_key].note_hit(result)
	results[index] = result

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if _controller != null:
				_controller.note_handlers.erase(get_unique_id())
			
			_controller = null
			
			var parent : Node = get_parent()
			if parent is RubiconLevelNoteController:
				_controller = parent
				_controller.note_handlers[get_unique_id()] = self
				update_notes()

func _should_process() -> bool:
	return not data.is_empty() and settings != null and _controller != null and _controller.get_level_clock() != null

func _process(delta: float) -> void:
	if not _should_process():
		return
	
	var millisecond_position : float = get_controller().get_level_clock().time_milliseconds
	
	# Handle going forward
	while note_spawn_start < data.size() and data[note_spawn_start].get_millisecond_end_position() - millisecond_position < spawning_bound_minimum:
		if graphics[note_spawn_start] != null:
			despawn_note(note_spawn_start)
		
		note_spawn_start += 1
	
	while note_spawn_end < data.size() and data[note_spawn_end].get_millisecond_start_position() - millisecond_position <= spawning_bound_maximum:
		if graphics[note_spawn_end] == null:
			spawn_note(note_spawn_end)
		
		note_spawn_end += 1
	
	# Handle rewinding
	while note_hit_index > 0 and data[note_hit_index - 1].get_millisecond_end_position() - millisecond_position > 0.0:
		note_hit_index -= 1

		if results[note_hit_index] != null:
			print("res")
			results[note_hit_index].reset()
	
	#if data[note_hit_index].ending_row != null and data[note_hit_index].get_millisecond_start_position() - millisecond_position > 0.0:
	#	if results[note_hit_index] != null:
	#		print("res 2")
	#		results[note_hit_index].reset()
	
	while note_spawn_start > 0 and data[note_spawn_start - 1].get_millisecond_end_position() - millisecond_position > spawning_bound_minimum:
		note_spawn_start -= 1
		
		if graphics[note_spawn_start] == null:
			spawn_note(note_spawn_start)
	
	while note_spawn_end - 1 > 0 and data[note_spawn_end - 1].get_millisecond_start_position() - millisecond_position > spawning_bound_maximum:
		note_spawn_end -= 1
		
		if graphics[note_spawn_end] != null:
			despawn_note(note_spawn_end)
	
	if note_hit_index >= data.size():
		return
	
	if get_controller().autoplay:
		_autoplay_process(millisecond_position)
		return
	
	while data[note_hit_index].get_millisecond_start_position() - millisecond_position < -settings.judgment_window_bad:
		hit_note(note_hit_index, millisecond_position, RubiconLevelNoteHitResult.Hit.HIT_COMPLETE) # TODO: Add more forgiving hold notes
		note_hit_index += 1

func _property_can_revert(property: StringName) -> bool:
	if property == "settings":
		return true
	
	return false

func _property_get_revert(property : StringName) -> Variant:
	if property == "settings":
		return RubiconLevelNoteSettings.new()
	
	return
