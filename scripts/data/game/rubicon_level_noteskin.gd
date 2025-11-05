@tool
class_name RubiconLevelNoteskin extends Resource

@export var skins : Dictionary[String, RubiconLevelNoteskinValue]

func get_skin_for_mode(mode : String) -> RubiconLevelNoteskinValue:
	if not skins.has(mode):
		printerr("Could not find skin for mode %s!" % mode)
		return null
	
	return skins.get(mode)
