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
@export var inputs : RubiconLevelNoteInputMap

var note_handlers : Dictionary[String, RubiconLevelNoteHandler]

var _chart : RubiChart
var _chart_dirty : bool = false

var _level_2d : RubiconLevel2D
var _level_3d : RubiconLevel3D

var _override_note_database : RubiconLevelNoteDatabase
var _internal_note_database : Dictionary[StringName, RubiconLevelNoteDatabaseValue]

func _init() -> void:
	set_process_internal(true)

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
			if _level_2d != null:
				_level_2d.metadata_changed.disconnect(update_chart)
				_level_2d = null
			
			if _level_3d != null:
				_level_3d.metadata_changed.disconnect(update_chart)
				_level_3d = null
			
			var parent : Node = get_parent()
			while parent != null:
				if parent is RubiconLevel2D:
					_level_2d = parent
					_level_2d.metadata_changed.connect(update_chart)
					break
				elif parent is RubiconLevel3D:
					_level_3d = parent
					_level_3d.metadata_changed.connect(update_chart)
					break
				
				parent = parent.get_parent()

func get_note_database() -> Dictionary[StringName, RubiconLevelNoteDatabaseValue]:
	return _internal_note_database

func update_chart() -> void:
	var metadata : RubiconLevelMetadata = get_level_metadata()
	if metadata == null:
		return
	
	_chart.initialize(metadata.time_changes)
	for id in note_handlers:
		note_handlers[id].update_notes()

func get_level_clock() -> RubiconLevelClock:
	if _level_2d != null:
		return _level_2d.clock
	
	if _level_3d != null:
		return _level_3d.clock
	
	return null

func get_level_metadata() -> RubiconLevelMetadata:
	if _level_2d != null:
		return _level_2d.metadata
	
	if _level_3d != null:
		return _level_3d.metadata
	
	return null
