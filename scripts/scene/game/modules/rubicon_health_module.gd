@tool
extends Node
class_name RubiconHealthModule

@export var note_controller : RubiconLevelNoteController:
	set(value):
		if value == note_controller:
			return
		
		if value != note_controller and note_controller != null and note_controller.note_changed.is_connected(note_changed):
			note_controller.disconnect("note_changed", note_changed)
			note_controller_connected.emit(false)
		
		note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()
		
		if note_controller != null:
			note_controller.connect("note_changed", note_changed)
			note_controller_connected.emit(true)


@export var min_health:float = 0.0
@export var max_health:float = 100.0
@export var starting_health:float = 50.0

@export var health_gain_mutliplier:float = 1.0
@export var health_lose_mutliplier:float = 1.0

var health:float:
	set(value):
		if value <= min_health:
			health = min_health
			health_changed.emit()
			health_depleted.emit()
			return
		elif value >= max_health:
			health = max_health
			health_changed.emit()
			return
		
		health = value
		health_changed.emit()

@export_group("Health Addition")

@export var perfect_health_addition:float = 3
@export var great_health_addition:float = 2
@export var good_health_addition:float = 1
@export var okay_health_addition:float = -1
@export var bad_health_addition:float = -2
@export var miss_health_addition:float = -8

signal health_changed
signal health_depleted

signal note_controller_connected(connected: bool)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray
	if note_controller == null:
		warnings.append(tr("This health module requires a note controller to function. Make sure to assign one on the inspector"))
	
	return warnings

func _ready() -> void:
	health = starting_health

func note_changed(result:RubiconLevelNoteHitResult, has_ending_row:bool = false) -> void:
	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		return
	
	if result.scoring_rating != RubiconLevelNoteHitResult.Judgment.JUDGMENT_NONE:
		var rating_name:StringName = RubiconLevelNoteHitResult.Judgment.find_key(result.scoring_rating)
		var health_addition:float = get(&"%s_health_addition" % [rating_name.to_lower().erase(0, 9)])
		if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			health_addition *= 0.5

		if health_addition > 0.0:
			health_addition *= health_gain_mutliplier
		else:
			health_addition *= health_lose_mutliplier
		
		health += health_addition

func _validate_property(property: Dictionary) -> void:
	if property.name == &"starting_health":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "%s,%s,0.01" % [min_health, max_health]
	
	if property.name.ends_with("_health_addition"):
			property.usage = PROPERTY_USAGE_DEFAULT if note_controller != null else PROPERTY_USAGE_STORAGE

func _property_can_revert(property: StringName) -> bool:
	if property == &"starting_health" and starting_health != (min_health + max_health) / 2:
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"starting_health":
			return (min_health + max_health) / 2
	
	return null

var _pre_save_health: float = 0.0
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_pre_save_health = health
			health = starting_health
		NOTIFICATION_EDITOR_POST_SAVE:
			health = _pre_save_health
