## Song metadata for [RubiconLevel]s. The only value that needs to be set is [member time_changes],
## as the rest are just information for developers to use.
class_name RubiconLevelMetadata
extends Resource

@export var title: String
@export_multiline var description: String
@export var time_changes: Array[RubiconTimeChange]
