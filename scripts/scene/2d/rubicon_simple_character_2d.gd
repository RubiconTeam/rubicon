@tool
class_name RubiconSimpleCharacter2D extends Node2D

@export var steps_until_idle : int = 4
@export var should_dance:bool = true
@export var should_sing:bool = true

@export var hold_type:CharacterHoldType = CharacterHoldType.FREEZE:
	set(value):
		hold_type = value
		notify_property_list_changed()
@export_storage var repeat_loop_point:float = 0.125
@export_storage var step_time_value:float = 1

@export var animation_player:AnimationPlayer:
	set(value):
		animation_player = value
		notify_property_list_changed()
		update_configuration_warnings()

@export_group("Level-only References", "level_")
@export var level_note_controller : RubiconLevelNoteController:
	set(value):
		if is_tree_root and level_note_controller == null:
			printerr("Not recommended to assign a Note Controller on a character's scene (unless you know what you're doing!)")
		
		level_note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()
		
		if level_note_controller != null:
			level_note_controller.connect("note_changed", note_changed)

var camera_point:Marker2D:
	get():
		if camera_point_path.is_empty() or camera_point_path == null:
			return null
		update_configuration_warnings()
		return get_node(camera_point_path)

var camera_point_path:NodePath
var camera_point_offset:Vector2

var state:CharacterState

var _last_result : RubiconLevelNoteHitResult
var _last_sing_anim : StringName
var _hold_anim_timer : float

enum CharacterHoldType {
	NONE,
	FREEZE,
	REPEAT,
	STEP_REPEAT,
}

enum CharacterState {
	STATE_RESTING,
	STATE_DANCING,
	STATE_SINGING,
	STATE_HOLDING,
	STATE_OVERRIDE,
}

func _valid_controller() -> bool:
	return level_note_controller != null and level_note_controller.get_level_clock() != null

#func _process(delta: float) -> void:
	#if not _valid_controller():
		#return
	#
	#var current_result : RubiconLevelNoteHitResult
	#var clock : RubiconLevelClock = level_note_controller.get_level_clock()
	#for handler_id in level_note_controller.note_handlers:
		#var handler : RubiconLevelNoteHandler = level_note_controller.note_handlers[handler_id]
		#var handler_result : RubiconLevelNoteHitResult = handler.results[handler.note_hit_index] # Get current note holding
		#if handler.note_hit_index > 0 and (handler_result == null or handler_result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE):
			#handler_result = handler.results[handler.note_hit_index - 1] # Get last note hit
		#
		## Invalid
		#if handler_result == null or handler_result.time_when_hit > clock.time_milliseconds:
			#continue
#
		#if current_result == null or handler_result.time_when_hit > current_result.time_when_hit:
			#current_result = handler_result
	#
	## Idling
	#if current_result == null:
		#_handle_dancing()
		#return
#
	#match current_result.scoring_hit:
		#RubiconLevelNoteHitResult.Hit.HIT_NONE:
			#_handle_dancing()
		#RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
			#_handle_singing(current_result)
		#RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
			#_handle_singing(current_result)
#
			#var data : RubiChartNote = current_result.handler.data[current_result.data_index]
			#var millisecond_to_idle_at : float = RubiconTimeChange.get_millisecond_at_step(clock.get_time_changes(), RubiconTimeChange.get_step_at_millisecond(clock.get_time_changes(), data.get_millisecond_end_position()) + steps_until_idle)
			#if current_result.handler.data[current_result.data_index].get_millisecond_end_position() > millisecond_to_idle_at:
				#_handle_dancing()

func note_changed(result:RubiconLevelNoteHitResult) -> void:
	if state == CharacterState.STATE_OVERRIDE:
		return
	
	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		state = CharacterState.STATE_RESTING
		print("resting")
		return
	
	if should_sing:
		_last_result = result
		_last_sing_anim = get_anim_alias_from_result(_last_result)
		match result.scoring_hit:
			RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
				state = CharacterState.STATE_HOLDING
				_hold_anim_timer = 0
				_sing()
				print("started holding")
			
			RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
				state = CharacterState.STATE_SINGING
				print("singing")
				_sing()

func _process(delta: float) -> void:
	if state == CharacterState.STATE_HOLDING:
		match hold_type:
			CharacterHoldType.NONE:
				_sing()
				state = CharacterState.STATE_RESTING
			CharacterHoldType.FREEZE:
				_sing()
				animation_player.pause()
				state = CharacterState.STATE_RESTING
				print("please freeze")
			CharacterHoldType.REPEAT:
				_hold_anim_timer += delta
				if _hold_anim_timer > repeat_loop_point:
					_sing()
					_hold_anim_timer = 0
			CharacterHoldType.STEP_REPEAT:
				_hold_anim_timer += delta
				#if _hold_anim_timer > RubiconTimeChange.
			#

func _handle_dancing() -> void:
	return
	state = CharacterState.STATE_DANCING

func _sing() -> void:
	play(_last_sing_anim, true)

func _handle_hold_animation() -> void:
	match hold_type:
		CharacterHoldType.NONE:
			return
		CharacterHoldType.FREEZE:
			var cur_anim:StringName = animation_player.current_animation
			if cur_anim != _last_sing_anim or animation_player.current_animation_position > 0:
				animation_player.current_animation = _last_sing_anim
				animation_player.seek(0)
				animation_player.pause()
		CharacterHoldType.REPEAT:
			var time_distance:float = (level_note_controller.get_level_clock().time_milliseconds - _last_result.time_when_hit) * 0.001 
			var anim_length:float = animation_player.current_animation_length
			var wrapped_time_distance:float = wrapf(time_distance, 0, repeat_loop_point if repeat_loop_point <= anim_length else anim_length)
			animation_player.seek(wrapped_time_distance * animation_player.speed_scale, true)

func dance() -> void:
	pass

func play(anim_name:StringName, warn_missing_animation:bool = false) -> void:
	if animation_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return
	
	if !animation_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr('No animation "'+anim_name+'" found in character: ' + scene_file_path.get_file())
		return
	
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)

func get_anim_alias_from_result(result:RubiconLevelNoteHitResult) -> StringName:
	var current_id : StringName = result.handler.get_unique_id()
	var mode_aliases:Dictionary[StringName, StringName] = get(result.handler.get_mode_id().to_lower() + "_anim_aliases")
	print(result.handler.get_mode_id().to_lower() + "_anim_aliases")
	if mode_aliases == null or mode_aliases.is_empty():
		printerr("Couldn't get animation alias list for mode: " + result.handler.get_mode_id().to_lower())
		return &""
	if !mode_aliases.has(current_id):
		printerr("Couldn't find alias for animation: %s" % [current_id])
		return &""
	
	var current_anim : StringName = animations[mode_aliases[current_id]]
	return current_anim

#region Custom Property Handling
var is_tree_root:bool:
	get():
		if !is_inside_tree():
			return false
		
		if get_tree() != null and self == get_tree().edited_scene_root:
			return true
		return false

@export_storage var animations:Dictionary[StringName,StringName] = {}
var anim_player_list:PackedStringArray:
	get():
		if animation_player != null:
			var anims:PackedStringArray = [&"None"]
			anims.append_array(animation_player.get_animation_list())
			return anims
		return [&"None"]

@export_storage var modes:Array[StringName] = [&"mania"]
var _new_mode_name:StringName = &"":
	set(value):
		_new_mode_name = value.to_lower()
var _add_mode:Callable = add_mode
var _remove_mode:Callable = remove_mode
var _add_animation_group:Callable = add_animation_group

# Defaults for mania, as it is the targeted mode.
@export_storage var mania_anim_aliases:Dictionary[StringName, StringName] = {"mania_lane0": "sing_left", "mania_lane1": "sing_down", "mania_lane2": "sing_up", "mania_lane3": "sing_right", "mania_lane0_miss": "miss_left", "mania_lane1_miss": "miss_down", "mania_lane2_miss": "miss_up", "mania_lane3_miss": "miss_right"}
@export_storage var mania_anim_groups:Dictionary[StringName, int] = {"sing": 4}#, "miss": 4}
# default 4k directions for anim predictions (for >4k you'll have to set them up yourself, i unfortunately cant predict your brain)
var mania_directions:Array[StringName] = [&"left", &"down", &"up", &"right"]

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray
	
	if animation_player == null:
		warnings.append(tr("No root animation player assigned. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and level_note_controller == null:
		warnings.append(tr("Characters require a note controller to work. Make sure to assign one under the character's properties"))
	
	if !is_tree_root and (camera_point == null or camera_point_path.is_empty()):
		warnings.append(tr("No camera point assigned. Cameras will ignore the character when supposed to aim at it."))
	
	return warnings

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	match hold_type:
		CharacterHoldType.REPEAT:
			properties.append({
				name = &"repeat_loop_point",
				type = TYPE_FLOAT,
				usage = PROPERTY_USAGE_EDITOR
			})
		CharacterHoldType.STEP_REPEAT:
			properties.append({
				name = &"step_time_value",
				type = TYPE_FLOAT,
				usage = PROPERTY_USAGE_EDITOR
			})
	
	
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
	
	if animation_player != null:
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
					hint_string = "Remove %s,Remove" % [mode.capitalize()]
				})
				
				properties.append({
					name = &"Add Animation Groups",
					type = TYPE_NIL,
					usage = PROPERTY_USAGE_GROUP
				})
				
				properties.append({
					name = &"_add_animation_group",
					type = TYPE_CALLABLE,
					hint = PROPERTY_HINT_TOOL_BUTTON,
					usage = PROPERTY_USAGE_EDITOR,
					hint_string = "Add Animation Group,Add"
				})
				
				var mode_groups:Dictionary[StringName, int] = get("%s_anim_groups" % [mode])
				for i:int in mode_groups.size():
					var group_name:StringName = mode_groups.keys()[i]
					var group_prefix:StringName = "%s_" % [group_name.to_lower()]
					properties.append({
						name = group_name.capitalize(),
						type = TYPE_NIL,
						usage = PROPERTY_USAGE_GROUP,
						hint_string = group_prefix
					})
					
					properties.append({
						name = &"Aliases",
						type = TYPE_NIL,
						usage = PROPERTY_USAGE_SUBGROUP,
						hint_string = "alias_"
					})
					
					for group_size:int in mode_groups[group_name]:
						properties.append({
							name = &"alias_%s_lane%s" % [mode, str(group_size)],
							type = TYPE_STRING_NAME,
							hint = PROPERTY_HINT_TYPE_STRING,
							usage = PROPERTY_USAGE_EDITOR
						})
					
					for group_size:int in mode_groups[group_name]:
						var anim_id:StringName = &"%s_lane%s" % [mode, str(group_size)]
						properties.append({
							name = mania_anim_aliases[anim_id] if mania_anim_aliases.has(anim_id) else anim_id,
							hint = PROPERTY_HINT_ENUM,
							type = TYPE_STRING_NAME,
							usage = PROPERTY_USAGE_EDITOR,
							hint_string = ",".join(anim_player_list)
						})
	
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

func add_animation_group() -> void:
	pass

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
	
	#match property:
		#&"repeat_loop_point":
			#if repeat_loop_point == 0.125:
				#return false
			#return true
		#&"step_time_value":
			#if step_time_value == 1:
				#return false
			#return true
	
	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		var dir_idx:int = mania_directions.find(property.get_slice("_", 1))
		var direction:StringName = mania_directions[dir_idx]
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
	
	match property:
		&"_camera_point":
			if !is_tree_root:
				return null
			return find_child("*oint")
		#&"repeat_loop_point":
			#return 0.125
		#&"step_time_value":
			#return 1
	
	return property_get_revert(property)
#endregion
