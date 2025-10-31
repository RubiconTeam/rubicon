@tool
class_name RubiconLevel3D extends Node3D

@export var metadata : RubiconLevelMetadata

var clock : RubiconLevelClock

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	
	if metadata == null:
		warnings.append(tr("Metadata file is null or could not be found. Rubicon levels need metadata to function."))
	elif metadata.time_changes.is_empty():
		warnings.append(tr("Metadata doesn't contain any time changes! Rubicon levels require at least one time change to function."))
	
	if clock == null:
		warnings.append(tr("Rubicon levels need a RubiconLevelClock child to function!"))
	
	return warnings
