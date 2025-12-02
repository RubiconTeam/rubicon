@tool
extends EditorPlugin
class_name RubiconPlugin

const CREATE_CONTEXT_MENU_PLUGIN = preload("res://addons/rubicon/scripts/create_context_menu_plugin.gd")
var _instance:EditorContextMenuPlugin

func _enter_tree() -> void:
	add_project_setting("rubicon/defaults/note_database", TYPE_STRING, PROPERTY_HINT_FILE, "*.tres,*.res", "res://note_database.tres")
	add_project_setting("rubicon/defaults/character_template", TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn", "")
	
	var note_database_path : String = ProjectSettings.get_setting("rubicon/defaults/note_database")
	if not ResourceLoader.exists(note_database_path):
		ResourceSaver.save(RubiconLevelNoteDatabase.new(), note_database_path)
	
	_instance = CREATE_CONTEXT_MENU_PLUGIN.new()
	_instance.connect("popup_menu", _popup_menu)
	
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE, _instance)

func _exit_tree() -> void:
	remove_context_menu_plugin(_instance)

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

func _popup_menu(paths:PackedStringArray) -> void:
	var scene_icon:Texture2D = EditorInterface.get_editor_theme().get_icon(&"PackedScene",&"EditorIcons")
	var create_simple_character_callable:Callable = Callable(self, "_create_popup").bind(_instance.CREATE_SIMPLE_CHARACTER_POPUP, _instance._create_simple_character)
	
	_instance.add_context_menu_item("Character... (Simple)", create_simple_character_callable, scene_icon)

func _create_popup(paths:PackedStringArray, popup_scene:PackedScene, confirm_call:Callable) -> void:
	var screen_scale:float = DisplayServer.screen_get_scale()
	var instance:ConfirmationDialog = popup_scene.instantiate()
	instance.base_path = paths[0]
	instance.content_scale_factor = screen_scale
	add_child(instance)
	instance.popup_centered(instance.size * DisplayServer.screen_get_scale())
	instance.confirmed.connect(func(): confirm_call.call(instance.base_path, instance._name))
