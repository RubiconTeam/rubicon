class_name RubiconLevelMetadata extends Resource

@export var title : String
@export_multiline var description : String
@export var time_changes : Array[RubiconTimeChange]
@export_file("*.tscn", "*.scn") var scene_path : String
