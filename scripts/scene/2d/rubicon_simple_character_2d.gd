@tool
class_name RubiconSimpleCharacter2D extends Node2D

@export var steps_until_idle : int = 4
@export var should_dance:bool = true
@export var should_sing:bool = true

@export_group("References", "reference_")
@export var reference_animation_player:AnimationPlayer:
	set(value):
		reference_animation_player = value
		notify_property_list_changed()
		update_configuration_warnings()

@export var reference_note_controller : RubiconLevelNoteController:
	set(value):
		reference_note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()
		
		if reference_note_controller != null:
			reference_note_controller.connect("note_hit", note_hit)

var camera_point:Marker2D:
	get():
		if camera_point_path.is_empty() or camera_point_path == null:
			return null
		update_configuration_warnings()
		return get_node(camera_point_path)

var camera_point_path:NodePath
var camera_point_offset:Vector2

var dancing:bool
var singing:bool

var _results_cache : Array[RubiconLevelNoteHitResult]

func _should_process() -> bool:
	return reference_note_controller != null and reference_note_controller.get_level_clock() != null

func _process(delta: float) -> void:
	if not _should_process():
		return
	
	var current_result : RubiconLevelNoteHitResult
	var clock : RubiconLevelClock = reference_note_controller.get_level_clock()
	for handler_id in reference_note_controller.note_handlers:
		var handler : RubiconLevelNoteHandler = reference_note_controller.note_handlers[handler_id]
		var handler_result : RubiconLevelNoteHitResult = handler.results[handler.note_hit_index] # Get current note holding
		if handler.note_hit_index > 0 and (handler_result == null or handler_result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE):
			handler_result = handler.results[handler.note_hit_index - 1] # Get last note hit
		
		# Invalid
		if handler_result == null or handler_result.time_when_hit > clock.time_milliseconds:
			continue

		if current_result == null or handler_result.time_when_hit > current_result.time_when_hit:
			current_result = handler_result
	
	# Idling
	if current_result == null:
		_handle_dancing()
		return

	match current_result.scoring_hit:
		RubiconLevelNoteHitResult.Hit.HIT_NONE:
			_handle_dancing()
		RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			_handle_singing(current_result)
		RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
			_handle_singing(current_result)

			var data : RubiChartNote = current_result.handler.data[current_result.data_index]
			var millisecond_to_idle_at : float = RubiconTimeChange.get_millisecond_at_step(clock.get_time_changes(), RubiconTimeChange.get_step_at_millisecond(clock.get_time_changes(), data.get_millisecond_end_position()) + steps_until_idle)
			if current_result.handler.data[current_result.data_index].get_millisecond_end_position() > millisecond_to_idle_at:
				_handle_dancing()

func _handle_dancing() -> void:
	pass

func _handle_singing(current_result : RubiconLevelNoteHitResult) -> void:
	var current_id : StringName = current_result.handler.get_unique_id()
	reference_animation_player.current_animation = animations[anim_aliases[current_id]]

func note_hit(id:StringName, rating:RubiconLevelNoteHitResult.Judgment) -> void:
	return
	sing(animations[anim_aliases[id]])

func dance() -> void:
	if singing:
		return

func sing(anim:StringName) -> void:
	singing = true
	play(anim, true)

# will work on properties and overriding n shit later
func play(anim_name:StringName, force:bool = true, warn_missing_animation:bool = false) -> void:
	if reference_animation_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return
	
	if !reference_animation_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr('No animation "'+anim_name+'" found in character: ' + scene_file_path.get_file())
		return
	
	if reference_animation_player.is_playing() and !force:
		return
	
	reference_animation_player.play(anim_name)
	reference_animation_player.seek(0.0)

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
	
	if reference_animation_player == null:
		warnings.append(tr("No root animation player assigned. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and reference_note_controller == null:
		warnings.append(tr("Characters require a note controller to work. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and (camera_point == null or camera_point_path.is_empty()):
		warnings.append(tr("No camera point assigned. Cameras will ignore the character when supposed to aim at it."))
	
	return warnings


@export_storage var animations:Dictionary[StringName,StringName] = {}
var directions:Array[StringName] = [&"left", &"down", &"up", &"right"]
var anim_aliases:Dictionary[StringName, StringName] = {"mania_lane0": "sing_left", "mania_lane1": "sing_down", "mania_lane2": "sing_up", "mania_lane3": "sing_right"}
var anim_player_list:PackedStringArray:
	get():
		if reference_animation_player != null:
			var anims:PackedStringArray = [&"None"]
			anims.append_array(reference_animation_player.get_animation_list())
			return anims
		return [&"None"]

@export_storage var modes:Array[StringName] = [&"mania"]
var _new_mode_name:StringName = &""
var _add_mode:Callable = add_mode
var _remove_mode:Callable = remove_mode

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	if !is_tree_root:
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
	
	if reference_animation_player != null:
		properties.append({
			name = &"Animation Setup",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		})
			
		properties.append({
			name = &"_add_mode",
			type = TYPE_CALLABLE,
			hint = PROPERTY_HINT_TOOL_BUTTON,
			usage = PROPERTY_USAGE_EDITOR,
			hint_string = "Add New Game Mode,Add"
		})
		
		properties.append({
			name = &"_new_mode_name",
			type = TYPE_STRING_NAME,
			hint = PROPERTY_HINT_TYPE_STRING,
			usage = PROPERTY_USAGE_EDITOR
		})
	
		if !modes.is_empty():
			for mode:StringName in modes:
				properties.append({
					name = mode.capitalize(),
					type = TYPE_NIL,
					usage = PROPERTY_USAGE_CATEGORY
				})
				
				properties.append({
					name = &"_remove_mode_"+mode,
					type = TYPE_CALLABLE,
					hint = PROPERTY_HINT_TOOL_BUTTON,
					usage = PROPERTY_USAGE_EDITOR,
					hint_string = "Remove Game Mode,Remove"
				})
				
				properties.append_array([{
					name = &"Sing",
					type = TYPE_NIL,
					usage = PROPERTY_USAGE_SUBGROUP,
					hint_string = "sing_"
					}] + get_anim_properties_from_array(directions, "sing_")
				)
				
				properties.append_array([{
					name = &"Miss",
					type = TYPE_NIL,
					usage = PROPERTY_USAGE_SUBGROUP,
					hint_string = "miss_"
					}] + get_anim_properties_from_array(directions, "miss_")
				)
	#elif modes.is_empty():
		#modes.append(&"mania")
		#notify_property_list_changed()
	
	return properties

func add_mode() -> void:
	if modes.find(_new_mode_name) != -1 or _new_mode_name.is_empty():
		return
	
	modes.append(_new_mode_name)
	_new_mode_name = &""
	notify_property_list_changed()

func remove_mode(mode_name:StringName) -> void:
	var mode_idx:int = modes.find(mode_name)
	modes.pop_at(mode_idx)
	notify_property_list_changed()

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
	
	if property.begins_with("_remove_mode_"):
		var split_name:PackedStringArray = property.split("_", false, 2)
		var callable = Callable(self, "remove_mode").bind(split_name[2])
		return callable
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if (property.begins_with("sing_") or property.begins_with("miss_")) and value != null:
		if value.to_lower() == "none":
			animations[property] = ""
			return true
		
		animations[property] = value
		return true
	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if get(property).to_lower() == &"none":
			return false
		return true
	
	#if property == &"_note_controller" and (note_controller_path != null or !note_controller_path.is_empty()):
		#return true
	
	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		var dir_idx:int = directions.find(property.get_slice("_", 1))
		var direction:StringName = directions[dir_idx]
		var anim:StringName = &"None"
		for _anim:StringName in anim_player_list:
			var anim_lower:StringName = _anim.to_lower()
			if anim_lower.contains(direction) and anim_lower.contains(property.get_slice("_", 0)):
				anim = _anim
				break
		return anim
	
	#if property == &"_note_controller":
		#if !is_tree_root:
			#return null
		##return find_child()
	
	if property == &"_camera_point":
		if !is_tree_root:
			return null
		return find_child("*oint")
	
	return property_get_revert(property)
#endregion
