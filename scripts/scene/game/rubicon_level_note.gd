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
	var result : RubiconLevelNoteHitResult = get_hit_result()
	if result == null:
		return false
	
	return result.scoring_hit != RubiconLevelNoteHitResult.Hit.HIT_NONE

func was_missed() -> bool:
	var result : RubiconLevelNoteHitResult = get_hit_result()
	if result == null:
		return false
	
	return result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS

func get_hit_result() -> RubiconLevelNoteHitResult:
	return _handler.results[data_index] if _handler != null and _handler.note_hit_index > data_index else null

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
