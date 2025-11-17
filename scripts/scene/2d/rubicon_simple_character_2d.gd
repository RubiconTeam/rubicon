@tool
extends Node2D
class_name RubiconSimpleCharacter2D

@export_group("Character Data")
@export var should_dance:bool = true
@export var should_sing:bool = true

@export_group("References")
@export var anim_player:AnimationPlayer:
	set(value):
		anim_player = value
		notify_property_list_changed()

var note_controller:RubiconLevelNoteController:
	get():
		if note_controller_path.is_empty() or note_controller_path == null:
			return null
		return get_node(note_controller_path)
var note_controller_path:NodePath

var camera_point:Marker2D:
	get():
		if camera_point_path.is_empty() or camera_point_path == null:
			return null
		return get_node(camera_point_path)
var camera_point_path:NodePath
var camera_point_offset:Vector2

var dancing:bool
var singing:bool

func connect_note_controller() -> void:
	if note_controller != null:
		note_controller.connect("note_press", note_press)

func disconnect_note_controller() -> void:
	if note_controller != null:
		note_controller.disconnect("note_press", note_press)

func note_press() -> void:
	pass

func dance() -> void:
	pass

func sing() -> void:
	pass

func play(anim_name:StringName, override_dance:bool = false, override_sing:bool = false, force:bool = true, warn_missing_animation:bool = false) -> void:
	if anim_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return
	
	if !anim_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr('No animation "'+anim_name+'" found in character: ' + scene_file_path.get_file())
		return
	
	if ((singing and !override_sing) or (dancing and !override_dance)):
		return
	
	if anim_player.is_playing() and !force:
		return
	
	anim_player.play(anim_name)
	anim_player.seek(0.0)

#region Custom Property Handling
var is_tree_root:bool:
	get():
		if !is_inside_tree():
			return false
		
		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray
	
	if anim_player == null:
		warnings.append(tr("No root animation player assigned. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and (note_controller == null or note_controller_path.is_empty()):
		warnings.append(tr("Characters require a note controller to work. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and (camera_point == null or camera_point_path.is_empty()):
		warnings.append(tr("No camera point assigned. Cameras will ignore the character when supposed to aim at it."))
	
	return warnings


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
	
	if !is_tree_root:
		properties.append({
			name = &"_note_controller",
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NODE_PATH_VALID_TYPES,
			hint_string = "RubiconLevelNoteController", 
			usage = PROPERTY_USAGE_DEFAULT
		})
		
		properties.append({
			name = &"_camera_point",
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NODE_PATH_VALID_TYPES,
			hint_string = "Marker2D", 
			usage = PROPERTY_USAGE_DEFAULT
		})
		
		properties.append({
			name = &"_camera_point_offset",
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_DEFAULT
		})
	
	properties.append({
		name = &"Animation Data",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_EDITOR
	})
	
	if anim_player != null:
		properties.append({
			name = &"Mania Animation Data",
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
		&"_note_controller":
			return note_controller_path
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if (property.begins_with("sing_") or property.begins_with("miss_")) and value != null:
		if value.to_lower() == "none":
			animations[property] = ""
			return true
		
		animations[property] = value
		return true
	
	match property:
		&"_note_controller":
			if note_controller != null:
				disconnect_note_controller()
			
			if value == null:
				note_controller_path = ""
				return true
			note_controller_path = value
			connect_note_controller()
			return true
		&"_camera_point":
			if value == null:
				camera_point_path = ""
				return true
			camera_point_path = value
			return true
		&"camera_point_offset":
			if value == null:
				
				return true
	
	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if get(property).to_lower() == "none":
			return false
		return true
	
	if property == "_note_controller" and (note_controller_path != null or !note_controller_path.is_empty()):
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
	
	if property == "_note_controller":
		if !is_tree_root:
			return null
		#return find_child()
	
	if property == "_camera_point":
		if !is_tree_root:
			return null
		return find_child("?oint")
	
	return property_get_revert(property)
#endregion
