class_name TeamSystem
extends Resource

const RoleDefinition = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleDefinition.gd")
const TacticalSystem = preload("res://_newhierarchy/simulation/team/roles/RoleTacticalSystem.gd")

@export var schema_version: int = 1
@export var id: String = ""
@export var display_name: String = "New system"
@export_multiline var guide_text: String = ""
@export var first_touch: int = 0
@export var second_touch: int = 1
@export var third_touch: int = 2
@export var player_roles: Array[PlayerRoleDefinition] = []
@export var rotation_roles: Array[PlayerRoleDefinition] = []
@export var tactical_positions: RoleTacticalSystem = TacticalSystem.new()

enum TouchGoal { PASS, SET, ATTACK }

func ensure_id() -> void:
	if id.is_empty():
		id = "%s-%s" % [display_name.to_snake_case(), str(Time.get_ticks_usec())]

func initialize_default_roles() -> void:
	if rotation_roles.size() == 36:
		return
	var legacy_roles := player_roles.duplicate(true)
	rotation_roles.clear()
	player_roles.clear()
	for rotation in range(6):
		for player_index in range(6):
			var role: PlayerRoleDefinition = legacy_roles[player_index].duplicate(true) if legacy_roles.size() == 6 else RoleDefinition.new()
			role.display_name = "Player %s" % char(65 + player_index)
			rotation_roles.append(role)
	player_roles = rotation_roles.slice(0, 6)

func role_for(rotation: int, player_index: int) -> PlayerRoleDefinition:
	initialize_default_roles()
	return rotation_roles[(clampi(rotation, 1, 6) - 1) * 6 + clampi(player_index, 0, 5)]

func roles_for_rotation(rotation: int) -> Array[PlayerRoleDefinition]:
	initialize_default_roles()
	var roles: Array[PlayerRoleDefinition] = []
	var start := (clampi(rotation, 1, 6) - 1) * 6
	for index in range(start, start + 6):
		roles.append(rotation_roles[index])
	return roles

func duplicate_system() -> TeamSystem:
	var copy: TeamSystem = duplicate(true)
	copy.id = ""
	copy.display_name = "%s copy" % display_name
	copy.ensure_id()
	copy.initialize_default_roles()
	return copy
