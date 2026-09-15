extends SceneTree

const SystemDefinition = preload("res://_newhierarchy/simulation/system/TeamSystem.gd")
const SystemCatalog = preload("res://_newhierarchy/simulation/system/SystemLibrary.gd")
const Validator = preload("res://_newhierarchy/simulation/system/SystemValidator.gd")

func _init() -> void:
	var system := SystemDefinition.new()
	system.initialize_default_roles()
	var blank_findings := Validator.validate(system)
	assert(not blank_findings.is_empty())
	assert(blank_findings.any(func(finding): return finding.area == "Set" and finding.rotation == 1))

	for role in system.player_roles:
		role.receive = true
		role.attack = true
		role.block = true
		role.defend = true
	system.player_roles[0].set_role = true
	assert(Validator.validate(system).is_empty())

	var catalog := SystemCatalog.new()
	catalog.add_system(system)
	var path := "user://system_validator_smoke.tres"
	assert(ResourceSaver.save(catalog, path) == OK)
	var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	assert(loaded is SystemCatalog)
	assert(loaded.systems.size() == 1)
	assert(loaded.systems[0].player_roles.size() == 6)
	print("System validation smoke test passed")
	quit()
