@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_project_setting("rubicon/defaults/note_database", TYPE_STRING, PROPERTY_HINT_FILE, "", "res://note_database.tres")
	
	var note_database_path : String = ProjectSettings.get_setting("rubicon/defaults/note_database")
	if not ResourceLoader.exists(note_database_path):
		ResourceSaver.save(RubiconLevelNoteDatabase.new(), note_database_path)

func add_project_setting(name : String, type : Variant.Type, hint : PropertyHint, hint_string : String = "", default_value : Variant = null, basic : bool = true) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})

	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.set_as_basic(name, basic)