@tool
extends Control
class_name RubiconJudgmentDisplay

@export var level_note_controller:RubiconLevelNoteController:
	set(value):
		if value != level_note_controller and level_note_controller != null and level_note_controller.note_changed.is_connected(note_changed):
			level_note_controller.disconnect("note_changed", note_changed)
		
		level_note_controller = value
		update_configuration_warnings()
		
		if level_note_controller != null:
			level_note_controller.connect("note_changed", note_changed)

@export var animation_player:AnimationPlayer

var is_tree_root:bool:
	get():
		if !is_inside_tree():
			return false
		
		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray
	if !is_tree_root and level_note_controller == null:
		warnings.append(tr("This node requires a note controller to display judgments. Make sure to assign one on the inspector"))
	
	return warnings

# temporary code, like note_changed
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			animation_player.play(&"RESET")

# must implement proper functionality, it currently only displays scoring_hit.
func note_changed(result:RubiconLevelNoteHitResult, has_ending_row:bool = false):
	if result == null:
		return
	
	var is_valid_hit: bool = result.scoring_hit == result.Hit.HIT_COMPLETE and !has_ending_row
	var is_starting_hold: bool = result.scoring_hit == result.Hit.HIT_INCOMPLETE and has_ending_row
	
	if !is_valid_hit and !is_starting_hold:
		return
	
	animation_player.play(str(result.Judgment.find_key(result.scoring_rating)).to_lower())
	animation_player.seek(0.0)
