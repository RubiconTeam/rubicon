class_name RubiconLevelNoteskin extends Resource

@export var skins : Dictionary[String, PackedScene]

func instantiate_skin_for_mode(mode : String) -> RubiconLevelNoteGraphic:
	if not skins.has(mode):
		printerr("Could not find skin for mode %s!" % mode)
		return null
	
	return skins.get(mode)
