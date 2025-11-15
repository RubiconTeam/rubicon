@tool
extends Node2D
class_name RubiconSimpleCharacter2D

@export_group("References")
@export var root_animation_player:AnimationPlayer

#region Editor Animation Handling
@export_storage var animations:Dictionary[StringName,StringName] = {}
var directions:Array[StringName] = ["left", "down", "up", "right"]
var anim_player_list:PackedStringArray:
	get():
		if root_animation_player != null:
			var anims:PackedStringArray = ["None"]
			anims.append_array(root_animation_player.get_animation_list())
			return anims
		return ["None"]

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	properties.append({
		name = "Animation Data",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_GROUP
	})
	
	properties.append({
		name = "Sing",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_SUBGROUP,
		hint_string = "sing_"
	})
	for animation:StringName in directions:
		properties.append({
				name = "sing_"+animation,
				hint = PROPERTY_HINT_ENUM,
				type = TYPE_STRING_NAME,
				usage = PROPERTY_USAGE_DEFAULT,
				hint_string = ",".join(anim_player_list)
			})
	
	properties.append({
		name = "Miss",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_SUBGROUP,
		hint_string = "miss_"
	})
	
	for animation:StringName in directions:
		properties.append({
				name = "miss_"+animation,
				hint = PROPERTY_HINT_ENUM,
				type = TYPE_STRING_NAME,
				usage = PROPERTY_USAGE_DEFAULT,
				hint_string = ",".join(anim_player_list)
			})
	
	return properties

func _get(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if animations[property].is_empty():
			return "None"
		if animations.has(property):
			return animations[property]
		return property_get_revert(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if (property.begins_with("sing_") or property.begins_with("miss_")) and value != null:
		if value.to_lower() == "none":
			animations[property] = ""
			return false
		
		animations[property] = value
		return false
	
	return true

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
	print("hello")
	return property_get_revert(property)
#endregion
