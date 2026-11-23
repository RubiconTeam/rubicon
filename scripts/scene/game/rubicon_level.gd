@tool
## The main node for levels. Should always have a [RubiconLevelClock] child and [member metadata] assigned.[br][br]
## Many nodes will reference this node to access the clock and it is required for a clock to work.
class_name RubiconLevel
extends Node

@export var metadata : RubiconLevelMetadata:
	get:
		return _metadata
	set(val):
		_metadata = val
		
		if _metadata != null:
			RubiconTimeChange.update(_metadata.time_changes)
		
		changed.emit()

var clock : RubiconLevelClock

var _metadata : RubiconLevelMetadata

signal changed ## Is emitted when anything changes in the level.

func emit_changed() -> void:
	changed.emit()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	
	if metadata == null:
		warnings.append(tr("Metadata file is null or could not be found. Rubicon levels need metadata to function."))
	elif metadata.time_changes.is_empty():
		warnings.append(tr("Metadata doesn't contain any time changes! Rubicon levels require at least one time change to function."))
	
	if clock == null:
		warnings.append(tr("Rubicon levels need a RubiconLevelClock child to function!"))
	
	return warnings
