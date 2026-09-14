extends Resource
class_name PlayerRolePositionOverride

## A complete instruction snapshot scoped to a physical court position and a
## rotation mask.  Complete snapshots make imported roles deterministic.
@export_range(1, 6) var physical_position: int = 1
@export var rotations: Array[int] = [1, 2, 3, 4, 5, 6]
@export var instructions: Dictionary = {}

func matches(position: int, rotation: int) -> bool:
	return physical_position == position and rotations.has(rotation)

func apply_to(base: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	for key in instructions:
		merged[key] = instructions[key]
	return merged
