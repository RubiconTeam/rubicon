@tool
extends Node2D
class_name RubiconSimpleCharacter2D

var note_controller:RubiconLevelNoteController:
	get():
		if _note_controller_path.is_empty() or _note_controller_path == null:
			return null
		
		return get_node(_note_controller_path)
@export_storage var _note_controller_path:NodePath

var anim_player:AnimationPlayer:
	get():
		if _anim_player_path.is_empty() or _anim_player_path == null:
			return null
		
		return get_node(_anim_player_path)
@export_storage var _anim_player_path:NodePath

var is_tree_root:bool:
	get():
		if !is_inside_tree():
			return false
		
		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray
	
	if anim_player == null or _anim_player_path.is_empty():
		warnings.append("No root animation player assigned. Make sure to assign one under References in the character's properties")
	
	if !is_tree_root and (note_controller == null or _note_controller_path.is_empty()):
		warnings.append("Characters require a note controller to work. Make sure to assign one under References in the character's properties")
	
	return warnings

#region Custom Property Handling
@export_storage var animations:Dictionary[StringName,StringName] = {}
var directions:Array[StringName] = [&"left", &"down", &"up", &"right"]
var anim_player_list:PackedStringArray:
	get():
		if anim_player != null:
			var anims:PackedStringArray = [&"None"]
			anims.append_array(anim_player.get_animation_list())
			return anims
		return [&"None"]

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	if anim_player != null:
		properties.append({
			name = &"Animation Data",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		})
		
		properties.append_array(
			[{
			name = &"Sing",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_SUBGROUP,
			hint_string = "sing_"
			}] + get_anim_properties_from_array(directions, "sing_")
			)
		
		properties.append_array(
			[{
			name = &"Miss",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_SUBGROUP,
			hint_string = "miss_"
			}] + get_anim_properties_from_array(directions, "miss_")
			)
	
	properties.append({
		name = &"References",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_GROUP
	})
	
	properties.append({
		name = &"root_animation_player",
		type = TYPE_NODE_PATH,
		hint_string = "AnimationPlayer", 
		usage = PROPERTY_USAGE_EDITOR
	})
	
	if !is_tree_root:
		properties.append({
		name = &"_note_controller",
		type = TYPE_NODE_PATH,
		hint = PROPERTY_HINT_NODE_PATH_VALID_TYPES,
		hint_string = "RubiconLevelNoteController", 
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	return properties

func get_anim_properties_from_array(array:PackedStringArray, prefix:StringName) -> Array[Dictionary]:
	var properties:Array[Dictionary]
	for animation:StringName in array:
		properties.append({
				name = prefix+animation,
				hint = PROPERTY_HINT_ENUM,
				type = TYPE_STRING_NAME,
				usage = PROPERTY_USAGE_EDITOR,
				hint_string = ",".join(anim_player_list)
			})
	return properties

func _get(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if animations[property].is_empty():
			return "None"
		if animations.has(property):
			if !anim_player_list.has(animations[property]):
				return property_get_revert(property)
			return animations[property]
		return property_get_revert(property)
	
	match property:
		&"root_animation_player":
			return _anim_player_path
		&"_note_controller":
			return _note_controller_path
	
	if property == &"root_animation_player":
		return _anim_player_path
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if (property.begins_with("sing_") or property.begins_with("miss_")) and value != null:
		if value.to_lower() == "none":
			animations[property] = ""
			return true
		
		animations[property] = value
		return true
	
	match property:
		&"root_animation_player":
			_anim_player_path = value
			anim_player = get_node(_anim_player_path)
			return true
		&"_note_controller":
			_note_controller_path = value
			return true
	
	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if get(property).to_lower() == "none":
			return false
		
		return true

	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		var split_property:PackedStringArray = property.split("_")
		var dir_idx:int = directions.find(split_property[1])
		var direction:StringName = directions[dir_idx]
		var anim:StringName = "None"
		for _anim:StringName in anim_player_list:
			var anim_lower:StringName = _anim.to_lower()
			if anim_lower.contains(direction) and anim_lower.contains(split_property[0]):
				anim = _anim
				break
		return anim
	return property_get_revert(property)
#endregion
