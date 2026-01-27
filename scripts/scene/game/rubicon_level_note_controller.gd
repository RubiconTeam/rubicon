@tool
class_name RubiconLevelNoteController extends Control

@export var chart : RubiChart:
	get:
		return _chart
	set(val):
		_chart = val
		_chart_dirty = true

@export var note_overrides : RubiconLevelNoteDatabase:
	get:
		return _override_note_database
	set(val):
		_override_note_database = val
		_reset_note_database()

@export var autoplay : bool = false
@export var preview_as_autoplay : bool = true
@export var inputs : RubiconLevelNoteInputMap

@export_group("Performance", "performance_")
@export var performance_max_score : float = 1000000
@export var performance_score : float:
	get:
		var total_value : float = 0.0
		var note_count : int = 0
		for key in note_handlers:
			var handler : RubiconLevelNoteHandler = note_handlers[key]
			note_count += handler.data.size()

			for i in handler.note_hit_index:
				total_value += handler.results[i].scoring_value
		
		return (total_value / note_count) * performance_max_score

@export_subgroup("Hits", "performance_hits")
@export var performance_hits_perfect : int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_PERFECT)

@export var performance_hits_great : int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GREAT)

@export var performance_hits_good : int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_GOOD)

@export var performance_hits_okay : int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_OKAY)

@export var performance_hits_bad : int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_BAD)

@export var performance_hits_miss :  int:
	get:
		return _get_result_count_of_rating(RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS)

var note_handlers : Dictionary[String, RubiconLevelNoteHandler]

var _chart : RubiChart
var _chart_dirty : bool = false

var _level : RubiconLevel

var _override_note_database : RubiconLevelNoteDatabase
var _internal_note_database : Dictionary[StringName, RubiconLevelNoteMetadata]

signal note_changed(result:RubiconLevelNoteHitResult, has_ending_row:bool)

func _init() -> void:
	set_process_internal(true)

func get_note_database() -> Dictionary[StringName, RubiconLevelNoteMetadata]:
	return _internal_note_database

func update_chart() -> void:
	var metadata : RubiconLevelMetadata = get_level_metadata()
	if metadata == null:
		return
	
	_chart.initialize(metadata.time_changes)
	for id in note_handlers:
		note_handlers[id].update_notes()

func get_level_clock() -> RubiconLevelClock:
	if _level != null:
		return _level.clock
	
	return null

func get_level_metadata() -> RubiconLevelMetadata:
	if _level != null:
		return _level.metadata
	
	return null

func _get_result_count_of_rating(rating : RubiconLevelNoteHitResult.Judgment) -> int:
	var count : int = 0
	for key in note_handlers:
		var handler : RubiconLevelNoteHandler = note_handlers[key]
		for i in handler.note_hit_index:
			var result : RubiconLevelNoteHitResult = handler.results[i]
			if result.scoring_rating != rating:
				continue
				
			count += 1
		
	return count

func _reset_note_database() -> void:
	_internal_note_database.clear()
	if _override_note_database != null:
		for key in _override_note_database.defines:
			_internal_note_database[key] = _override_note_database.defines[key]
	
	var default_database_path : String = ProjectSettings.get_setting("rubicon/defaults/note_database")
	if default_database_path.is_empty() or not ResourceLoader.exists(default_database_path):
		return
	
	var resource : Resource = ResourceLoader.load(default_database_path)
	if resource is not RubiconLevelNoteDatabase:
		update_chart()
		return
	
	for key in resource.defines:
		if _internal_note_database.has(key):
			continue
		
		_internal_note_database[key] = resource.defines[key]
	
	update_chart()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_INTERNAL_PROCESS:
			if _chart_dirty:
				if _chart != null:
					update_chart()
				
				_chart_dirty = false
		NOTIFICATION_PARENTED:
			if _level != null:
				_level.metadata_changed.disconnect(update_chart)
				_level = null
			
			var parent : Node = get_parent()
			while parent != null:
				if parent is RubiconLevel:
					_level = parent
					_level.metadata_changed.connect(update_chart)
					break
				
				parent = parent.get_parent()

func should_autoplay() -> bool:
	return autoplay or (preview_as_autoplay and Engine.is_editor_hint())

func _input(event: InputEvent) -> void:
	if should_autoplay() or event.is_echo() or inputs == null or not inputs.has_event_registered(event):
		return
	
	var id : StringName = inputs.get_handler_id_for_event(event)
	if not note_handlers.has(id):
		return
	
	var handler : RubiconLevelNoteHandler = note_handlers[id]
	if not handler._should_process():
		return

	if event.is_pressed():
		note_handlers[id]._press(event)
	else:
		note_handlers[id]._release(event)
