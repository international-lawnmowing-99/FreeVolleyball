extends Resource
class_name PlayerRoleDefinition

## Reusable player responsibilities.  This deliberately contains no movement,
## transition, or coverage behaviour; a team system resolves those separately.

enum Preparation { NONE, SET_SECOND_BALL, ATTACK }
enum Lane { NONE, LEFT, MIDDLE, RIGHT }
enum DefensiveSlot { NONE, LEFT, MIDDLE, RIGHT }

@export var schema_version: int = 1
@export var id: String = ""
@export var display_name: String = "New role"

@export_group("System responsibilities")
@export var receive: bool = false
@export var set_role: bool = false
@export var attack: bool = false
@export var block: bool = false
@export var defend: bool = false
@export var backup_setter: bool = false
@export_enum("Prepare for next role", "Chill") var non_receive_preparation: int = 0

@export_group("Receive")
@export var designated_receiver: bool = false
@export var non_receiver_preparation: Preparation = Preparation.NONE
@export_group("Set")
@export var designated_setter_good_pass: bool = false
@export var backup_setter_if_primary_receives: bool = false
@export var emergency_setter: bool = false
@export_group("Attack")
@export var front_attack_lane: Lane = Lane.NONE
@export var back_attack_lane: Lane = Lane.NONE
@export_group("Block")
@export var designated_front_blocker: bool = false
@export var block_lane: Lane = Lane.NONE
@export_group("Defence")
@export var defend_in_back_court: bool = false
@export var defensive_slot: DefensiveSlot = DefensiveSlot.NONE

## Physical-position exceptions apply when this role holder occupies a court
## position, not when they started in a particular rotation slot.
@export var position_overrides: Array[PlayerRolePositionOverride] = []

func ensure_id() -> void:
	if id.is_empty():
		id = "%s-%s" % [display_name.to_snake_case(), str(Time.get_ticks_usec())]

func duplicate_role() -> PlayerRoleDefinition:
	var copy: PlayerRoleDefinition = duplicate(true)
	copy.id = ""
	copy.display_name = "%s copy" % display_name
	copy.ensure_id()
	return copy

func instructions_for(physical_position: int, rotation: int) -> Dictionary:
	var result := _base_instructions()
	for override in position_overrides:
		if override != null and override.matches(physical_position, rotation):
			result = override.apply_to(result)
	return result

func _base_instructions() -> Dictionary:
	return {
		"designated_receiver": designated_receiver,
		"non_receiver_preparation": non_receiver_preparation,
		"designated_setter_good_pass": designated_setter_good_pass,
		"backup_setter_if_primary_receives": backup_setter_if_primary_receives,
		"emergency_setter": emergency_setter,
		"front_attack_lane": front_attack_lane,
		"back_attack_lane": back_attack_lane,
		"designated_front_blocker": designated_front_blocker,
		"block_lane": block_lane,
		"defend_in_back_court": defend_in_back_court,
		"defensive_slot": defensive_slot
	}
