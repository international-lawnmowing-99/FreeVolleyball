extends Resource
class_name SystemLibrary

@export var schema_version: int = 1
@export var systems: Array[TeamSystem] = []

func find_system(system_id: String) -> TeamSystem:
	for system in systems:
		if system != null and system.id == system_id:
			return system
	return null

func add_system(system: TeamSystem) -> void:
	if system == null:
		return
	system.ensure_id()
	for index in systems.size():
		if systems[index] != null and systems[index].id == system.id:
			systems[index] = system
			return
	systems.append(system)

func add_or_replace(system: TeamSystem) -> void:
	if system == null:
		return
	system.ensure_id()
	for index in systems.size():
		if systems[index] != null and systems[index].id == system.id:
			systems[index] = system
			return
	systems.append(system)

func remove_system(system: TeamSystem) -> void:
	systems.erase(system)