extends RefCounted
class_name RolePreviewResolver

const CourtCoordinates = preload("res://_newhierarchy/simulation/team/roles/CourtCoordinateSystem.gd")
const DefaultSystem = preload("res://_newhierarchy/simulation/team/roles/RoleTacticalSystem.gd")

## This is the bridge between declarative roles and a court preview. It reuses
## the project's legal rotation anchors, but intentionally does not call the
## runtime phase-target API (which contains old hard-coded behaviour).
static func build_phase(rotation: int, phase: String, roles: Array[PlayerRoleDefinition], tactical_system: RoleTacticalSystem = null) -> Array[Dictionary]:
	var system: RoleTacticalSystem = tactical_system if tactical_system != null else DefaultSystem.new()
	var output: Array[Dictionary] = []
	for slot in range(6):
		var physical_position := ((slot + rotation - 1) % 6) + 1
		var role: PlayerRoleDefinition = roles[slot] if slot < roles.size() else null
		var instructions := role.instructions_for(physical_position, rotation) if role != null else {}
		var start: Vector3 = CourtCoordinates.ROTATION_ANCHORS.get(physical_position, Vector3(3.5, 0.0, 0.0))
		var target := _target_for(phase, start, physical_position, instructions, system)
		output.append({
			"slot": slot + 1,
			"physical_position": physical_position,
			"role_name": role.display_name if role != null else "Unassigned",
			"instructions": instructions,
			"start": start,
			"target": target
		})
	return output

static func _target_for(phase: String, start: Vector3, physical: int, i: Dictionary, system: RoleTacticalSystem) -> Vector3:
	var front := CourtCoordinates.is_front_court(physical)
	match phase:
		"receive":
			if bool(i.get("designated_receiver", false)):
				return Vector3(max(start.x, 2.7), 0.0, start.z * 0.82)
			if int(i.get("non_receiver_preparation", 0)) == PlayerRoleDefinition.Preparation.SET_SECOND_BALL:
				return system.second_ball_preparation_target
			if int(i.get("non_receiver_preparation", 0)) == PlayerRoleDefinition.Preparation.ATTACK:
				return _attack_target(start, int(i.get("front_attack_lane", 0)) if front else int(i.get("back_attack_lane", 0)), front, system)
			return start
		"set":
			# A backup is conditional on the primary having received; it must not be
			# rendered as simultaneously occupying the primary setter window.
			if bool(i.get("designated_setter_good_pass", false)):
				return system.setter_target
			return _attack_target(start, int(i.get("front_attack_lane", 0)) if front else int(i.get("back_attack_lane", 0)), front, system)
		"attack":
			return _attack_target(start, int(i.get("front_attack_lane", 0)) if front else int(i.get("back_attack_lane", 0)), front, system)
		"block":
			if front and bool(i.get("designated_front_blocker", false)):
				return system.block_targets.get(int(i.get("block_lane", 0)), start)
			return start
		"defence":
			if not front and bool(i.get("defend_in_back_court", false)):
				return system.defence_targets.get(int(i.get("defensive_slot", 0)), start)
	return start

static func _attack_target(start: Vector3, lane: int, front: bool, system: RoleTacticalSystem) -> Vector3:
	if lane == PlayerRoleDefinition.Lane.NONE:
		return start
	var targets: Dictionary = system.attack_front_targets if front else system.attack_back_targets
	return targets.get(lane, start)
