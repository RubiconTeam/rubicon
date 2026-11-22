@tool
extends AcceptDialog
class_name RubiconAnimationManager

@export var tree: Tree

var character: RubiconCharacter:
	set(value):
		character = value
		reload_character_data()

func reload_character_data() -> void:
	var root: TreeItem = tree.create_item()
	
	if character == null:
		return
	
	for mode: StringName in character.animation_data.keys():
		var mode_item: TreeItem = tree.create_item(root)
		mode_item.set_text(0, mode)
		mode_item.set_editable(0, true)
		mode_item.set_text(1, character.animation_data[mode].id)
		print(mode)
