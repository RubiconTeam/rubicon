@tool
@abstract class_name RubiconLevelNote extends Control

var data_index : int = 0
var missed : bool = false
var is_runtime_note : bool = false

var handler : RubiconLevelNoteHandler:
	get:
		return _handler

var _handler : RubiconLevelNoteHandler
var _cached_owner : Node

func initialize(handler : RubiconLevelNoteHandler, data_index : int) -> void:
	_handler = handler
	self.data_index = data_index
	is_runtime_note = true

func was_hit() -> bool:
	if handler == null:
		return false
	
	return handler.note_hit_index > data_index

func get_hit_result(time_when_hit : float) -> RubiconLevelNoteHitResult:
	var result : RubiconLevelNoteHitResult = RubiconLevelNoteHitResult.new()
	
	return result

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	missed = false

func _should_process() -> bool:
	return _handler != null and _handler._should_process()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if not is_runtime_note:
				return
			
			_cached_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			if not is_runtime_note:
				return
			
			owner = _cached_owner
