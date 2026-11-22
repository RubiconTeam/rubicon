@tool
extends Control

@export var icon_name: StringName:
	set(value):
		icon_name = value
		update_icon()

func update_icon() -> void:
	if "icon" in self or "texture" in self:
		if Engine.is_editor_hint() and EditorInterface.get_editor_theme().has_icon(icon_name, &"EditorIcons"):
			set("icon" if "icon" in self else "texture", EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons"))

func _notification(what: int) -> void:
	if !Engine.is_editor_hint():
		return
	
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if "icon" in self or "texture" in self:
				set("icon" if "icon" in self else "texture", null)
		NOTIFICATION_EDITOR_POST_SAVE:
			update_icon()
