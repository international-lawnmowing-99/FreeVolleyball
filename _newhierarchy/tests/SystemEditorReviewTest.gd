extends SceneTree

const SystemDefinition = preload("res://_newhierarchy/simulation/system/TeamSystem.gd")
const SystemCatalog = preload("res://_newhierarchy/simulation/system/SystemLibrary.gd")
const Validator = preload("res://_newhierarchy/simulation/system/SystemValidator.gd")

func _init() -> void:
	var five_one := _complete_system(1)
	assert(Validator.validate(five_one).is_empty())

	var four_two := _complete_system(2)
	assert(Validator.validate(four_two).is_empty())

	var bizarre := _complete_system(1)
	bizarre.role_for(1, 0).receive = false
	bizarre.role_for(1, 0).attack = true
	bizarre.role_for(1, 1).set_role = true
	bizarre.role_for(1, 1).receive = false
	bizarre.role_for(1, 1).attack = true
	assert(Validator.validate(bizarre).is_empty())
	bizarre.role_for(1, 0).receive = false
	bizarre.role_for(2, 0).receive = true
	assert(bizarre.role_for(1, 0).receive != bizarre.role_for(2, 0).receive)

	var all_warnings := SystemDefinition.new()
	all_warnings.initialize_default_roles()
	var warning_count := Validator.validate(all_warnings).size()
	assert(warning_count == 30)

	var catalog := SystemCatalog.new()
	var original := _complete_system(1)
	catalog.add_system(original)
	var edited := original.duplicate(true)
	edited.guide_text = "Edited copy"
	edited.role_for(1, 0).receive = false
	catalog.add_or_replace(edited)
	assert(catalog.find_system(original.id).guide_text == "Edited copy")
	assert(original.guide_text != "Edited copy")

	var saved_copy: TeamSystem = edited.duplicate_system()
	saved_copy.guide_text = "Saved as copy"
	catalog.add_or_replace(saved_copy)
	assert(saved_copy.id != edited.id)
	assert(catalog.find_system(edited.id).guide_text == "Edited copy")
	assert(catalog.find_system(saved_copy.id).guide_text == "Saved as copy")
	assert(saved_copy.role_for(1, 0) != edited.role_for(1, 0))
	print("System Editor review configurations passed")
	quit()

func _complete_system(setter_count: int) -> TeamSystem:
	var system := SystemDefinition.new()
	system.initialize_default_roles()
	for rotation in range(1, 7):
		for index in range(6):
			var role := system.role_for(rotation, index)
			role.receive = true
			role.attack = true
			role.block = true
			role.defend = true
		for index in range(setter_count):
			system.role_for(rotation, index).set_role = true
	return system
