@tool
extends Node
class_name AudioSyncModule

enum SyncTime {
	STEP,
	BEAT,
	MEASURE,
}

@export var enabled:bool = true

@export var check_every:SyncTime = SyncTime.MEASURE:
	set(value):
		check_every = value
		set_sync_time(value)

@export var reference_player:AudioStreamPlayer:
	set(value):
		reference_player = value
		
		if reference_player != null and !players_to_sync.has(reference_player):
			players_to_sync.append(reference_player)
		notify_property_list_changed()

@export var players_to_sync:Array[AudioStreamPlayer]

var desync_threshold:float = 0.015

var _level:RubiconLevel:
	set(value):
		_level = value
		set_sync_time(check_every)

func set_sync_time(new_sync_time:SyncTime):
	if _level == null:
		return
	
	match check_every:
		SyncTime.STEP:
			if _level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.disconnect(check_for_desync)
			
			if _level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.disconnect(check_for_desync)
			
			if !_level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.connect(check_for_desync)
		
		SyncTime.BEAT:
			if _level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.disconnect(check_for_desync)
			
			if _level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.disconnect(check_for_desync)
			
			if !_level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.connect(check_for_desync)
		
		SyncTime.MEASURE:
			if _level.clock.step_change.is_connected(check_for_desync):
				_level.clock.step_change.disconnect(check_for_desync)
			
			if _level.clock.beat_change.is_connected(check_for_desync):
				_level.clock.beat_change.disconnect(check_for_desync)
			
			if !_level.clock.measure_change.is_connected(check_for_desync):
				_level.clock.measure_change.connect(check_for_desync)

func check_for_desync() -> void:
	if _level == null or reference_player == null or !enabled:
		return
	
	var anim_player_time:float = _level.clock.animation_player.current_animation_position
	print("audioplayer time:" + str(reference_player.get_playback_position()), "     animation time:" + str(anim_player_time))
	if abs(reference_player.get_playback_position() - anim_player_time) > desync_threshold:
		print("resynced")
		for player in players_to_sync:
			player.play(5.0)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if _level != null:
				_level = null
			
			var parent : Node = get_parent()
			while parent != null:
				if parent is RubiconLevel:
					_level = parent
					break
				
				parent = parent.get_parent()
