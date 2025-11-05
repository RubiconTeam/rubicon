@tool
class_name RubiconLevelNoteskinValue extends Resource

@export var default : PackedScene
@export var variations : Dictionary[String, PackedScene]

func variation_or_default(variation : String) -> PackedScene:
	if variations.has(variation):
		return variations[variation]
	
	return default
