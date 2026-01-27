@tool
extends EditorContextMenuPlugin

signal popup_menu(paths:PackedStringArray)
const CREATE_SIMPLE_CHARACTER_POPUP = preload("res://addons/rubicon/resources/editor/make_simple_character_dialog.tscn")
#const CREATE_LEVEL_POPUP = preload("")

func _popup_menu(paths: PackedStringArray) -> void:
	popup_menu.emit(paths)

func _create_simple_character(path:String, char_name:String) -> void:
	if char_name.is_empty():
		printerr("Somehow you created a character with an empty name, even tho the UI does not make it possible... wow...")
	
	var template_path:String = ProjectSettings.get_setting("rubicon/defaults/character_template")
	var template_instance:Node
	if !template_path.is_empty() and ResourceLoader.exists(template_path):
		template_instance = load(template_path).instantiate()
		template_instance.name = char_name
	
	var scene:PackedScene = PackedScene.new()
	scene.pack(template_instance if template_instance != null and template_instance is RubiconCharacter else _make_simple_character_tree(char_name))
	var scene_path:String = path+char_name+".tscn"
	ResourceSaver.save(scene, scene_path)

func _make_simple_character_tree(_name:String, sprite_frames_path:String = "", animation_library_path:String = "") -> Node:
	var root:RubiconCharacter = RubiconCharacter.new()
	root.name = _name
	
	if !sprite_frames_path.is_empty():
		var sprite:AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = load(sprite_frames_path)
		root.add_child(sprite)
		if !animation_library_path.is_empty():
			var _anim_player:AnimationPlayer = AnimationPlayer.new()
			_anim_player.add_animation_library(animation_library_path.get_file().get_basename(), load(animation_library_path))
			sprite.add_child(_anim_player)
	
	var root_anim_player:AnimationPlayer = AnimationPlayer.new()
	root_anim_player.name = "RootAnimationPlayer"
	root.add_child(root_anim_player)
	root_anim_player.owner = root
	root.reference_animation_player = root_anim_player
	
	return root

func _create_level_scene() -> void:
	pass
