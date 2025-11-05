@tool
class_name RubiconLevelNoteController extends Control

@export var chart : RubiChart:
	get:
		return _chart
	set(val):
		_chart = val
		_chart_dirty = true

@export var noteskin : RubiconLevelNoteskin

@export var autoplay : bool = false
@export var inputs : RubiconLevelNoteInputMap

var note_handlers : Dictionary[String, RubiconLevelNoteHandler]

var _chart : RubiChart
var _chart_dirty : bool = false

var _level_2d : RubiconLevel2D
var _level_3d : RubiconLevel3D

func _init() -> void:
	set_process_internal(true)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_INTERNAL_PROCESS:
			if _chart_dirty:
				if _chart != null:
					update_chart()
				
				_chart_dirty = false
		NOTIFICATION_PARENTED:
			_level_2d = null
			_level_3d = null
			
			var parent : Node = get_parent()
			while parent != null:
				if parent is RubiconLevel2D:
					_level_2d = parent
					break
				elif parent is RubiconLevel3D:
					_level_3d = parent
					break
				
				parent = parent.get_parent()

func update_chart() -> void:
	var metadata : RubiconLevelMetadata = get_level_metadata()
	if metadata == null:
		printerr("Your chart was not initialized due to missing metadata!")
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
