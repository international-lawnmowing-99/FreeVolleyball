extends Resource
class_name PlayerRoleLibrary

@export var schema_version: int = 1
@export var roles: Array[PlayerRoleDefinition] = []

func find_role(role_id: String) -> PlayerRoleDefinition:
	for role in roles:
		if role != null and role.id == role_id:
			return role
	return null

func add_or_replace(role: PlayerRoleDefinition) -> void:
	if role == null:
		return
	role.ensure_id()
	for i in roles.size():
		if roles[i] != null and roles[i].id == role.id:
			roles[i] = role
			return
	roles.append(role)

func remove_role(role: PlayerRoleDefinition) -> void:
	roles.erase(role)
