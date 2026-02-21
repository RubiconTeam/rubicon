@tool
class_name RubiconCharacter extends Node

@export var animation_player:AnimationPlayer:
	set(value):
		animation_player = value
		notify_property_list_changed()
		update_configuration_warnings()

@export var level_note_controller : RubiconLevelNoteController:
	set(value):
		if is_tree_root and level_note_controller == null:
			printerr("Not recommended to assign a Note Controller on a character's scene (unless you know what you're doing!)")
		
		if value != level_note_controller and level_note_controller != null:
			
			if level_note_controller.note_changed.is_connected(note_changed):
				level_note_controller.note_changed.disconnect(note_changed)
			if level_note_controller.release.is_connected(_handler_released):
				level_note_controller.release.disconnect(_handler_released)
			var clock:RubiconLevelClock = level_note_controller.get_level_clock()
			if clock.step_change.is_connected(step_change):
				clock.step_change.disconnect(step_change)
			
		level_note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()
			
		if level_note_controller != null:
			level_note_controller.note_changed.connect(note_changed)
			level_note_controller.release.connect(_handler_released)
			level_note_controller.get_level_clock().step_change.connect(step_change)

@export_group("Animation Settings", "animation_")
@export var animation_steps_until_dance : int = 4
@export var animation_force_dance:bool = true
@export var animation_should_dance:bool = true
@export var animation_should_sing:bool = true

@export var animation_hold_type:CharacterHoldType = CharacterHoldType.STEP_REPEAT:
	set(value):
		animation_hold_type = value
		notify_property_list_changed()
@export_storage var animation_repeat_loop_point:float = 0.125
@export_storage var animation_step_time_value:float = 1

@export var state:CharacterState = CharacterState.STATE_DANCING

var _last_result:RubiconLevelNoteHitResult
var _last_sing_anim:StringName
var _released_note:bool = true
var _last_dance_step:int

enum CharacterHoldType {
	## Characters will play hold notes once, as if it wasn't a hold note.
	NONE,
	## Characters will freeze on the first frame, playing the rest of if when the note is released.
	FREEZE,
	## Characters will repeat the animation each time current_animation_position goes over repeat_loop_point.
	REPEAT,
	## Characters will repeat the animation every step, executed in step_change().
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

func note_changed(result:RubiconLevelNoteHitResult, has_ending_row:bool = false) -> void:
	if state == CharacterState.STATE_OVERRIDE or !_valid_controller():
		return
	
	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		state = CharacterState.STATE_RESTING
		return
	
	if animation_should_sing:
		_last_result = result
		_last_sing_anim = get_anim_alias_from_result(_last_result)
		
		_released_note = result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS
		
		match result.scoring_hit:
			RubiconLevelNoteHitResult.Hit.HIT_INCOMPLETE:
				play(_last_sing_anim, true)
				state = CharacterState.STATE_HOLDING
			
			RubiconLevelNoteHitResult.Hit.HIT_COMPLETE:
				state = CharacterState.STATE_SINGING
				if has_ending_row and animation_hold_type != CharacterHoldType.FREEZE:
					return
				
				play(_last_sing_anim, true)

const PLACEHOLDER_DANCE_ANIM = "dance_idle"
func _process(delta: float) -> void:
	if state == CharacterState.STATE_HOLDING:
		match animation_hold_type:
			CharacterHoldType.NONE:
				state = CharacterState.STATE_RESTING
			CharacterHoldType.FREEZE:
				play(_last_sing_anim, true)
				animation_player.pause()
				state = CharacterState.STATE_RESTING
			CharacterHoldType.REPEAT:
				if animation_player.current_animation_position > animation_repeat_loop_point:
					play(_last_sing_anim, true)

func step_change() -> void:
	if level_note_controller == null or animation_player == null:
		return
	
	if state == CharacterState.STATE_HOLDING and animation_hold_type == CharacterHoldType.STEP_REPEAT:
		# TODO: execute accordingly to step_time_value
		play(_last_sing_anim, true)
	
	if animation_should_dance:
		var cur_step:int = floori(level_note_controller.get_level_clock().time_step)
		if abs(cur_step - _last_dance_step) >= animation_steps_until_dance:
			state = CharacterState.STATE_DANCING
		
		if state == CharacterState.STATE_DANCING:
			if animation_player.is_playing() and animation_player.current_animation == PLACEHOLDER_DANCE_ANIM and !animation_force_dance:
				return
			
			_last_dance_step = cur_step
			state = CharacterState.STATE_RESTING
			play(PLACEHOLDER_DANCE_ANIM, true)

func _handler_released() -> void:
	pass
	#_released_note = true

func play(anim_name:StringName, warn_missing_animation:bool = false) -> void:
	if animation_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return
	
	if !animation_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr('No animation "'+anim_name+'" found in character: ' + scene_file_path.get_file())
		return
	
	animation_player.stop()
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)

func get_anim_alias_from_result(result:RubiconLevelNoteHitResult) -> StringName:
	var current_id : StringName = result.handler.get_unique_id()
	var mode_aliases:Dictionary[StringName, StringName] = get(result.handler.get_mode_id().to_lower() + "_anim_aliases")
	if mode_aliases == null or mode_aliases.is_empty():
		printerr("Couldn't get animation alias list for mode: " + result.handler.get_mode_id().to_lower())
		return &""
	if !mode_aliases.has(current_id):
		printerr("Couldn't find alias for animation: %s" % [current_id])
		return &""
	
	var current_anim : StringName = animations[mode_aliases[current_id]]
	#temporary
	if result.scoring_rating == RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS:
		current_anim = &"dance_idle"
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

	return warnings

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	match animation_hold_type:
		CharacterHoldType.REPEAT:
			properties.append({
				name = &"Animation Settings",
				type = TYPE_NIL,
				usage = PROPERTY_USAGE_GROUP,
				hint_string = "animation_",
			})
			
			properties.append({
				name = &"animation_repeat_loop_point",
				type = TYPE_FLOAT,
				usage = PROPERTY_USAGE_EDITOR
			})
		CharacterHoldType.STEP_REPEAT:
			properties.append({
				name = &"Animation Settings",
				type = TYPE_NIL,
				usage = PROPERTY_USAGE_GROUP,
				hint_string = "animation_",
			})
			
			properties.append({
				name = &"animation_step_time_value",
				type = TYPE_FLOAT,
				usage = PROPERTY_USAGE_EDITOR
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
