@tool
## Character class that plays determined animations from an [AnimationPlayer] based on note results and song time.[br][br]
## Characters require a [RubiconLevelNoteController] and are purely independent, as all of their logic is found in this class.
class_name RubiconCharacter
extends Node

## The main [AnimationPlayer], used to play singing and dancing animations. It is needed for characters to work.
@export var animation_player:AnimationPlayer:
	set(value):
		if value == animation_player:
			return

		if value != animation_player and animation_player != null:
			if animation_player.animation_finished.is_connected(note_changed):
				level_note_controller.note_changed.disconnect(note_changed)

			if animation_player.animation_changed.is_connected(update_animation_player):
				animation_player.animation_changed.disconnect(update_animation_player)

		animation_player = value

		if animation_player != null:
			animation_player.animation_changed.connect(update_animation_player)

		notify_property_list_changed()
		update_configuration_warnings()

## The [RubiconLevelNoteController] that the character attaches to.[br]
## It is needed for characters to sing and dance, since it makes use of this controller's clock and signals to display animations.[br][br]
## This property will not show if this [RubiconCharacter] is the root of the scene.
@export var level_note_controller : RubiconLevelNoteController:
	set(value):
		if value == level_note_controller:
			return
		
		if is_tree_root and level_note_controller == null:
			printerr("Not recommended to assign a Note Controller on a character's scene (unless you know what you're doing!)")
		
		if level_note_controller != null:
			if level_note_controller.note_changed.is_connected(note_changed):
				level_note_controller.note_changed.disconnect(note_changed)
			
			if level_note_controller.handler_just_pressed.is_connected(_handler_pressed):
				level_note_controller.handler_just_pressed.disconnect(_handler_pressed)
			
			if level_note_controller.handler_just_released.is_connected(_handler_released):
				level_note_controller.handler_just_released.disconnect(_handler_released)
			
			var clock:RubiconLevelClock = level_note_controller.get_level_clock()
			if clock.step_change.is_connected(step_change):
				clock.step_change.disconnect(step_change)
			if clock.time_change_set.is_connected(_clock_time_change_set):
				clock.time_change_set.disconnect(_clock_time_change_set)
			if clock.animation_player.animation_started.is_connected(song_started):
				clock.animation_player.animation_started.disconnect(song_started)
			
			note_controller_connected.emit(false)
			if note_controller_index != -1:
				level_note_controller._remove_character_from_list(note_controller_index)
		
		level_note_controller = value
		notify_property_list_changed()
		update_configuration_warnings()
		
		if level_note_controller != null:
			level_note_controller.note_changed.connect(note_changed)
			
			_handlers_pressed.clear()
			level_note_controller.handler_just_pressed.connect(_handler_pressed)
			level_note_controller.handler_just_released.connect(_handler_released)
			
			var clock:RubiconLevelClock = level_note_controller.get_level_clock()
			clock.step_change.connect(step_change)
			clock.time_change_set.connect(_clock_time_change_set)
			clock.animation_player.animation_started.connect(song_started)
			
			note_controller_connected.emit(true)
			note_controller_index = level_note_controller._add_character_to_list(self)

@export_group("Singing", "singing_")
## Enables or disables character singing.[br][br]
## Disabling this will fully stop the singing logic by preventing the character from going into [enum STATE_SINGING], which may increase performance if disabled when not needed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var singing_should_sing:bool = true

## Amount of steps the character will take to transition from singing to dancing. [br][br]
## This is not only visual since it also delays the character from going into [enum STATE_RESTING]
@export var singing_sing_to_dance_interval:int = 4

## Changes the animation that the character displays on [enum STATE_HOLDING].
@export var singing_hold_type:CharacterHoldType = CharacterHoldType.REPEAT:
	set(value):
		if value == singing_hold_type:
			return
		
		singing_hold_type = value
		notify_property_list_changed()

## Loop point in the animation on the [enum REPEAT] hold type.[br][br]
## This property will only show when [member singing_hold_type] is [enum REPEAT]
@export var singing_repeat_loop_point:float = 0.125

## Step interval on the [enum STEP_REPEAT] hold type.[br][br]
## This property will only show when [member singing_hold_type] is [enum STEP_REPEAT]
@export var singing_step_time_value:int = 2

@export_group("Dancing", "dancing_")

## Enables or disables character dancing.[br][br]
## Disabling this will fully stop the dancing logic by preventing the character from going into [enum STATE_DANCING], which may increase performance if disabled when not needed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var dancing_should_dance:bool = true

## The measure interval which the character will trigger its dancing state. This value is converted into steps internally[br][br]
## For example, 0.5 = twice a measure (or every 2 beats)
@export var dancing_measure_step: float = 0.5:
	set(value):
		if is_equal_approx(dancing_measure_step, value):
			return
		
		dancing_measure_step = value
		_clock_time_change_set()
	get:
		return dancing_measure_step

## Forces the dancing animation to cancel the previous one if its not finished.[br][br]
## This does not affect singing or holding animations.
@export var dancing_force_dance:bool = true

## The list of dance animations that will play in a sequence every [member dancing_measure_step].
@export var dancing_animations:Array[StringName] = []:
	set(value):
		if value == dancing_animations:
			return

		dancing_animations = value
		_dance_anim_size = dancing_animations.size()
		_dance_anim_index = 0

@export_group("Transitions", "transition_")
## If the same animation is played, retain the queue that it had previously. (Example: utilizing [AnimationPlayer]'s auto transitions)
@export var transition_retain_animation_queue : bool = false

## Used for some sprites that may look "glitchy" when an animation is queued and not updated the same frame. (Main Example: gdanimate sprites which seem to have an issue with this specifically).
@export var transition_update_queued_animations : bool = false

@export_group("Advanced", "advanced_")
## Prevents [enum CharacterState.STATE_HOLDING] from being overriden by other hold notes reaching their end. If unsure, keep on
@export var advanced_prevent_hold_state_override: bool = true

## Controls the behavior when [enum CharacterState.STATE_SINGING] tries to override [enum CharacterState.STATE_HOLDING].[br][br]
## This is different from [enum advanced_prevent_hold_state_override] as it controls singing requests from overriding this state.
@export var advanced_state_override_behavior: HoldOverrideBehavior = HoldOverrideBehavior.KEEP_STATE

#@export_tool_button("Open Animation Manager", "Edit") var _animation_manager_button: Callable = open_animation_manager

## Character animations for each mode.[br][br]
## Use the Animation Manager instead of modifying this variable.
@export_storage var animations: Dictionary[StringName,StringName] = {}

## Animation data holding groups and aliases. [br][br]
## Preferably, edit this variable through the Animation Manager instead of code.
@export_storage var animation_data: Dictionary[StringName, Dictionary] = {
	mania = {
		id = &"mania_lane",
		lane_amount = 4,
		groups = {
			sing = {
				mania_lane0_sing = &"sing_left",
				mania_lane1_sing = &"sing_down",
				mania_lane2_sing = &"sing_up",
				mania_lane3_sing = &"sing_right",
			},
			miss = {
				mania_lane0_miss = &"miss_left",
				mania_lane1_miss = &"miss_down",
				mania_lane2_miss = &"miss_up",
				mania_lane3_miss = &"miss_right",
			},
		}
	}
}:
	set(value):
		animation_data = value
		refresh_animation_groups()
		notify_property_list_changed()

## Default note directions in 4K Mania used to predict animation names
const default_mania_directions: Array[StringName] = [&"left", &"down", &"up", &"right"]

## Gets all animations in [member animation_player] and adds [NONE] as a first.
var anim_player_list:PackedStringArray:
	get():
		if animation_player != null:
			var anims:PackedStringArray = [no_animation_name]
			anims.append_array(animation_player.get_animation_list())
			return anims
		return [no_animation_name]

var no_animation_name: StringName = &"[NONE]"

## Current character state.
var state: CharacterState = CharacterState.STATE_DANCING

## The index of this character connected to its note controller.
var note_controller_index: int = -1

var anim_groups: Dictionary[StringName, StringName] = {}

var _last_result:RubiconLevelNoteHitResult
var _last_sing_anim: StringName
var _last_sing_step: int

var _dance_step_offset: int = 0
var _dance_step_interval: int = 8
var _last_dance_step: int

var _dance_anim_index: int
var _dance_anim_size: int

var _handlers_pressed: Dictionary[StringName, bool]

enum CharacterHoldType {
	## Character will play hold notes once, as if it wasn't a hold note.
	NONE,
	## Character will freeze on the first frame, playing the rest of if when the note is released.
	FREEZE,
	## Character will repeat the animation each time current_animation_position goes over repeat_loop_point.
	REPEAT,
	## Character will repeat the animation every step, executed in step_change().
	STEP_REPEAT,
}

enum CharacterState {
	## Character is waiting to trigger [enum STATE_DANCING], but will listen to [enum STATE_SINGING] or [enum STATE_HOLDING].
	STATE_RESTING,
	
	## Next dancing animation in the sequence will play.[br][br]
	## This state does not wait until the right time to play the animation, as that calculation is done in [enum STATE_RESTING].
	STATE_DANCING,
	
	## Triggered by [method note_changed].[br][br]
	## Character will play its singing animation according to the note result, and the animation in [member animations]
	STATE_SINGING,
	
	## Triggered by [method note_changed].[br][br]
	## Character's note result singing animation will repeat according to [member singing_hold_type].
	STATE_HOLDING,
	
	## Overrides all states, will stop all character logic.[br][br]
	## This is never triggered organically and only exists as an utility for developers.
	STATE_OVERRIDE,
}

enum HoldOverrideBehavior {
	## [enum CharacterState.STATE_SINGING] will override [enum CharacterState.STATE_HOLDING] when its active. May result in hold animations getting cut shorter or not playing at all.
	NONE,
	## [enum CharacterState.STATE_SINGING] will not override [enum CharacterState.STATE_HOLDING] if its active. May result in sing animations being ignored.
	PREVENT,
	## Note hits will keep [enum CharacterState.STATE_HOLDING], but replace it with the new hit animation. May result in inaccuracy on the animation displayed, but more accuracy on the type of note being hit.
	KEEP_STATE
}

## Emitted when a note controller is either connected or not connected.
signal note_controller_connected(value: bool)

## Checks if [member level_note_controller] is a valid instance.
func _valid_controller() -> bool:
	return level_note_controller != null and level_note_controller.get_level_clock() != null

## Checks for [method _valid_controller] and if [member animation_player] is valid.
func _valid_references() -> bool:
	return _valid_controller() and animation_player != null

## Function connected to [member level_note_controller]'s [signal RubiconLevelNoteController.note_changed] signal.[br][br]
## Handles singing and holding states, and what animations need to be played based on the result.
func note_changed(result:RubiconLevelNoteHitResult, has_ending_row:bool = false) -> void:
	if not singing_should_sing or state == CharacterState.STATE_OVERRIDE or !_valid_controller():
		return
	
	if result.scoring_hit == RubiconLevelNoteHitResult.Hit.HIT_NONE:
		state = CharacterState.STATE_RESTING
		return
	
	# Very long condition so i separated it a bit
	if advanced_prevent_hold_state_override:
		if (result.scoring_hit == result.Hit.HIT_COMPLETE
		and state == CharacterState.STATE_HOLDING
		and has_ending_row and result.handler.get_unique_id() != _last_result.handler.get_unique_id()
		and _last_result.scoring_hit == _last_result.Hit.HIT_INCOMPLETE):
			return
	
	if advanced_state_override_behavior == HoldOverrideBehavior.PREVENT:
		if state == CharacterState.STATE_HOLDING and (result.scoring_hit == result.Hit.HIT_COMPLETE and !has_ending_row):
			return
	
	_last_result = result
	_last_sing_anim = get_anim_from_result(_last_result)
	_last_sing_step = floori(level_note_controller.get_level_clock().time_step)
	
	if (advanced_state_override_behavior == HoldOverrideBehavior.KEEP_STATE
	and state == CharacterState.STATE_HOLDING
	and !has_ending_row):
		play(_last_sing_anim, !_last_sing_anim.is_empty())
		return
	
	if result.scoring_rating == result.Judgment.JUDGMENT_MISS:
		play(_last_sing_anim, !_last_sing_anim.is_empty())
		state = CharacterState.STATE_SINGING
		return
	
	match result.scoring_hit:
		result.Hit.HIT_INCOMPLETE:
			play(_last_sing_anim, !_last_sing_anim.is_empty())
			state = CharacterState.STATE_HOLDING

			if singing_hold_type == CharacterHoldType.FREEZE:
				play(_last_sing_anim, !_last_sing_anim.is_empty())
				animation_player.pause()

		result.Hit.HIT_COMPLETE:
			state = CharacterState.STATE_SINGING
			if has_ending_row and singing_hold_type != CharacterHoldType.FREEZE:
				return

			play(_last_sing_anim, !_last_sing_anim.is_empty())

func _process(delta: float) -> void:
	if !_valid_references():
		return

	if singing_should_sing:
		if state == CharacterState.STATE_SINGING:
			var cur_step:int = floori(level_note_controller.get_level_clock().time_step)
			if abs(cur_step - _last_sing_step) >= singing_sing_to_dance_interval:
				state = CharacterState.STATE_RESTING

		if state == CharacterState.STATE_HOLDING and singing_hold_type == CharacterHoldType.REPEAT:
			if animation_player.is_playing() and animation_player.current_animation_position > singing_repeat_loop_point:
				play(_last_sing_anim, !_last_sing_anim.is_empty())

	if dancing_should_dance and state == CharacterState.STATE_DANCING:
		if animation_player.is_playing() and dancing_animations.has(animation_player.current_animation) and !dancing_force_dance:
			return

		_last_dance_step = floori(level_note_controller.get_level_clock().time_step)
		state = CharacterState.STATE_RESTING
		_dance()

## Function connected to the [member level_note_controller]'s clock and handles both dancing and [enum STEP_REPEAT] hold type.
func step_change(step: int) -> void:
	if !_valid_references():
		return

	if singing_should_sing and state == CharacterState.STATE_HOLDING and singing_hold_type == CharacterHoldType.STEP_REPEAT:
		if singing_step_time_value < 1:
			singing_step_time_value = 1
		
		var steps_since_initial:int = step - _last_sing_step
		var modulo:int = steps_since_initial % singing_step_time_value
		if steps_since_initial >= singing_step_time_value and modulo == 0:
			play(_last_sing_anim, !_last_sing_anim.is_empty())

	if _should_dance():
		if state == CharacterState.STATE_RESTING:
			if (step - _dance_step_offset) % _dance_step_interval == 0:
				state = CharacterState.STATE_DANCING

func song_started(anim_name:StringName) -> void:
	_dance_anim_index = 0
	if state != CharacterState.STATE_OVERRIDE:
		state = CharacterState.STATE_DANCING

func _handler_pressed(id: StringName) -> void:
	_handlers_pressed[id] = true

func _handler_released(id: StringName) -> void:
	_handlers_pressed[id] = false

## Plays the next dance animation in the sequence if [member dancing_should_dance] is enabled.
func _dance() -> void:
	if dancing_animations.is_empty():
		return

	var anim:StringName = dancing_animations[_dance_anim_index]
	if !anim.is_empty() and anim != no_animation_name:
		play(anim, !anim.is_empty())

	_dance_anim_index = wrapi(_dance_anim_index + 1, 0, _dance_anim_size)

## Plays an animation if [member animation_player] is valid and the animation exists in it.[br][br]
## If [member transition_retain_animation_queue] is enabled, this function will keep the animation queue after playing it.
func play(anim_name:StringName, warn_missing_animation:bool = false) -> void:
	if animation_player == null:
		printerr("Animation Player is null in character " + scene_file_path.get_file())
		return

	if !animation_player.has_animation(anim_name):
		if warn_missing_animation:
			printerr('No animation "'+anim_name+'" found in character: ' + scene_file_path.get_file())
		return

	var same_animation_queue : Array[StringName]
	if transition_retain_animation_queue and animation_player.current_animation == anim_name:
		same_animation_queue = animation_player.get_queue()
	
	animation_player.stop()
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)

	if transition_retain_animation_queue and not same_animation_queue.is_empty():
		for queued_animation in same_animation_queue:
			animation_player.queue(queued_animation)

## Returns the final animation name for the [member animation_player] to play based on [param result].
func get_anim_from_result(result:RubiconLevelNoteHitResult) -> StringName:
	var note_id: StringName = result.handler.get_unique_id()
	# TODO: Find a better way of knowing the animation suffix.
	# May require some rework on the animation data.
	var anim_suffix: StringName = &"sing" if result.scoring_rating != RubiconLevelNoteHitResult.Judgment.JUDGMENT_MISS else &"miss"
	
	var animation_name: StringName = &"%s_%s" % [note_id, anim_suffix]
	
	if !animations.has(animation_name):
		printerr("Animation %s not found in the characters animations. Try resetting the animations in the inspector" % [animation_name])
	var current_anim: StringName = animations[animation_name]
	
	return current_anim

func update_animation_player(_old: StringName, _new: StringName) -> void:
	if not transition_update_queued_animations:
		return

	if animation_player:
		animation_player.seek(0.0, true)

func _should_dance() -> bool:
	if dancing_should_dance:
		if !level_note_controller.should_autoplay() and _handlers_pressed.values().has(true):
			for handler: int in _handlers_pressed.values().size():
				if _handlers_pressed.values()[handler]:
					var note_handler: RubiconLevelNoteHandler = level_note_controller.note_handlers.values()[handler]
					
					# behavior only for mania, as its hard to know if a note is hit on a generic handler
					# plus the behavior is very specific to mania
					if note_handler.get_mode_id() == &"mania" and note_handler.lane_state == 2: # < not gonna be left like this!! just a temporary thing
						return false
		
		return true
	return false

func _clock_time_change_set() -> void:
	if not _valid_controller():
		return

	var clock: RubiconLevelClock = level_note_controller.get_level_clock()
	var time_change: RubiconTimeChange = clock._last_time_change
	if not time_change:
		return

	_dance_step_offset = RubiconTimeChange.get_step_at_measure(clock.get_time_changes(), time_change.measure)

	_recalculate_dance_step()

func _recalculate_dance_step() -> void:
	if not _valid_controller():
		return

	var clock: RubiconLevelClock = level_note_controller.get_level_clock()
	var time_change: RubiconTimeChange = clock._last_time_change
	_dance_step_interval = floori(time_change.time_signature_numerator * time_change.time_signature_denominator * dancing_measure_step)

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

	if animation_player == null:
		warnings.append(tr(&"No root animation player assigned. Make sure to assign one under the character's properties"))

	if !is_tree_root and level_note_controller == null:
		warnings.append(tr(&"Characters require a note controller to work. Make sure to assign one under the character's properties"))

	if dancing_should_dance and dancing_animations.is_empty():
		warnings.append(tr(&"There is no current dance animation. Define it in Dancing > Animations"))

	#if animations.has(null) or animations.has(&""):
		#warnings.append(tr(&"One or more animations are null. Set them up on the character's properties."))

	return warnings

func _validate_property(property: Dictionary) -> void:
	match property.name:
		&"dancing_animations":
			if animation_player != null:
				property.usage = PROPERTY_USAGE_DEFAULT
				property.hint = PROPERTY_HINT_TYPE_STRING
				property.hint_string = "%d/%d:%s" % [TYPE_STRING_NAME, PROPERTY_HINT_ENUM, ",".join(anim_player_list)]
			else:
				property.usage = PROPERTY_USAGE_STORAGE
		
		&"singing_repeat_loop_point":
			property.usage = PROPERTY_USAGE_DEFAULT if singing_hold_type == CharacterHoldType.REPEAT else PROPERTY_USAGE_STORAGE
		
		&"singing_step_time_value":
			property.usage = PROPERTY_USAGE_DEFAULT if singing_hold_type == CharacterHoldType.STEP_REPEAT else PROPERTY_USAGE_STORAGE
		
		&"level_note_controller":
			if animation_player and !is_tree_root:
				property.usage = PROPERTY_USAGE_DEFAULT
				return
			
			property.usage = PROPERTY_USAGE_STORAGE


func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary]
	
	if animation_player != null:
		if !animation_data.is_empty():
			for mode: StringName in animation_data.keys():
				var mode_id: String = animation_data[mode].id
				properties.append({
					name = mode.capitalize(),
					type = TYPE_NIL,
					usage = PROPERTY_USAGE_CATEGORY
				})
				
				var anim_data: Dictionary = animation_data[mode]
				if anim_data.has("lane_amount") and anim_data.has("groups"):
					var lane_amount: int = anim_data.lane_amount
					var groups: Dictionary = anim_data.groups
					
					for group: String in groups.keys():
						properties.append({
							name = group.capitalize(),
							type = TYPE_NIL,
							usage = PROPERTY_USAGE_GROUP,
							hint_string = "%s_" % [group.to_lower()]
						})
						
						for lane: int in lane_amount:
							var anim_id: StringName = &"%s%s_%s" % [mode_id, lane, group]
							var final_anim_name: StringName = groups[group][anim_id] if groups[group].has(anim_id) else anim_id

							if !animations.has(anim_id):
								animations[anim_id] = &""
								
								# small failsafe to not break characters before this commit. will probably be removed at some point
								if animations.has(final_anim_name):
									animations[anim_id] = final_anim_name
									animations.erase(final_anim_name)
									print("Found and removed old animation, please save the scene even if there's no prompt to.")
							
							properties.append({
								name = final_anim_name,
								hint = PROPERTY_HINT_ENUM,
								type = TYPE_STRING_NAME,
								usage = PROPERTY_USAGE_EDITOR,
								hint_string = ",".join(anim_player_list)
							})

	return properties

func refresh_animation_groups() -> void:
	for mode: StringName in animation_data.keys():
		var anim_data: Dictionary = animation_data[mode]
		if !anim_data.has("groups") or !anim_data.has("lane_amount"):
			continue
		
		var groups: Dictionary = anim_data.groups
		var mode_id: String = animation_data[mode].id
		for group: String in groups.keys():
			for lane: int in anim_data.lane_amount:
				var anim_id: StringName = &"%s%s_%s" % [mode_id, lane, group]
				var final_anim_name: StringName = groups[group][anim_id] if groups[group].has(anim_id) else anim_id
				anim_groups[final_anim_name] = anim_id

## Opens the Animation Manager window and assigns itself to it.
func open_animation_manager() -> void:
	if !Engine.is_editor_hint():
		return
	
	#RubiconPlugin.instance.animation_manager_instance.character = self
	#RubiconPlugin.instance.animation_manager_instance.show()

func _get(property: StringName) -> Variant:
	if anim_groups.has(property):
		var anim_id: StringName = anim_groups[property]
		if !animations.has(anim_id):
			return no_animation_name
		else:
			if anim_player_list.has(animations[anim_id]):
				return animations[anim_id]
		return property_get_revert(property)
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if anim_groups.has(property):
		var anim_id: StringName = anim_groups[property]
		if value == null:
			animations[anim_id] = no_animation_name
		
		if get(property) == value:
			return true
		
		if value.to_lower() == no_animation_name:
			animations[anim_id] = ""
			return true
		
		animations[anim_id] = value
		return true
	
	if property == &"singing_step_time_value" or property == &"singing_step_time":
		if value <= 0:
			value = 1
		
		singing_step_time_value = value
		return true
	
	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		if get(property).to_lower() == no_animation_name.to_lower():
			return false
		return true
	
	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("sing_") or property.begins_with("miss_"):
		var dir_idx:int = default_mania_directions.find(property.get_slice("_", 1))
		var direction:StringName = default_mania_directions[dir_idx]
		var anim:StringName = no_animation_name
		for _anim:StringName in anim_player_list:
			var anim_lower:StringName = _anim.to_lower()
			if anim_lower.contains(direction) and anim_lower.contains(property.get_slice("_", 0)):
				anim = _anim
				break
		return anim
	
	return null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			refresh_animation_groups()

#endregion
