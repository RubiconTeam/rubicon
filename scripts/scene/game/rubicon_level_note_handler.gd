@tool
@abstract class_name RubiconLevelNoteHandler extends Control

@export var settings : RubiconLevelNoteSettings

@export_group("Spawning", "spawning_")
@export var spawning_bound_maximum : float = 2000.0
@export var spawning_bound_minimum : float = -1000.0

var data : Array[RubiChartNote]
var graphics : Array[RubiconLevelNote]

var note_spawn_start : int = 0
var note_spawn_end : int = 0
var note_hit_index : int = 0

var _controller : RubiconLevelNoteController
var _note_pool : Dictionary[String, Array]

func get_controller() -> RubiconLevelNoteController:
	return _controller

@abstract func get_mode_id() -> StringName
@abstract func get_unique_id() -> StringName

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

func spawn_note(index : int) -> void:
	var note_type : String = data[index].type
	if not _note_pool.has(note_type):
		_note_pool[note_type] = Array()
	
	var graphic : RubiconLevelNote = _note_pool[note_type].pop_back()
	if graphic == null:
		var define_key : String = "%s_%s" % [note_type, get_mode_id()] if not note_type.is_empty() else get_mode_id()
		var skin : RubiconLevelNoteDatabaseValue = get_controller().get_note_database()[define_key]
		var packed : PackedScene = skin.scene
		
		graphic = packed.instantiate()
	
	graphic.initialize(self, index)
	graphic.name = "Note %s" % index
	graphics[index] = graphic
	
	add_child(graphic)
	graphic.owner = self
	sort_graphic(index)

func despawn_note(index : int) -> void:
	var note_type : String = data[index].type
	var graphic : RubiconLevelNote = graphics[index]
	
	remove_child(graphic)
	_note_pool[note_type].append(graphic)
	
	graphics[index] = null

func hit_note(index : int) -> void:
	pass

@abstract func sort_graphic(data_index : int) -> void

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
	while note_hit_index > 0 and data[note_hit_index - 1].get_millisecond_end_position() - millisecond_position > -settings.judgment_window_bad:
		note_hit_index -= 1
	
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
	
	while data[note_hit_index].get_millisecond_start_position() - millisecond_position < -settings.judgment_window_bad:
		# miss idfk
		note_hit_index += 1
	
	if not get_controller().autoplay:
		return
	
	while data[note_hit_index].get_millisecond_start_position() - millisecond_position <= 0:
		# hit for autoplay idk
		note_hit_index += 1

func _property_can_revert(property: StringName) -> bool:
	if property == "settings":
		return true
	
	return false

func _property_get_revert(property : StringName) -> Variant:
	if property == "settings":
		return RubiconLevelNoteSettings.new()
	
	return
