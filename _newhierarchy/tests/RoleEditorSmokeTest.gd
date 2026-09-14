extends Node

const Role = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleDefinition.gd")
const Library = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleLibrary.gd")
const Preview = preload("res://_newhierarchy/simulation/team/roles/RolePreviewResolver.gd")
const Validator = preload("res://_newhierarchy/simulation/team/roles/RoleLineupValidator.gd")

func _ready() -> void:
	var library = Library.new()
	var primary = _role("Primary setter")
	primary.designated_receiver = true
	primary.designated_setter_good_pass = true
	primary.front_attack_lane = Role.Lane.RIGHT
	primary.back_attack_lane = Role.Lane.RIGHT
	var backup = _role("Backup")
	backup.designated_receiver = true
	backup.backup_setter_if_primary_receives = true
	backup.front_attack_lane = Role.Lane.LEFT
	var middle = _role("Middle")
	middle.designated_receiver = true
	middle.front_attack_lane = Role.Lane.MIDDLE
	middle.designated_front_blocker = true
	middle.block_lane = Role.Lane.MIDDLE
	var left = _role("Left")
	left.designated_receiver = true
	left.front_attack_lane = Role.Lane.LEFT
	left.back_attack_lane = Role.Lane.LEFT
	var right = _role("Right")
	right.designated_receiver = true
	right.front_attack_lane = Role.Lane.RIGHT
	right.defend_in_back_court = true
	right.defensive_slot = Role.DefensiveSlot.RIGHT
	var defender = _role("Defender")
	defender.designated_receiver = true
	defender.defend_in_back_court = true
	defender.defensive_slot = Role.DefensiveSlot.LEFT
	for role in [primary, backup, middle, left, right, defender]: library.add_or_replace(role)
	var save_path := "res://_newhierarchy/tests/role_editor_smoke.tres"
	assert(ResourceSaver.save(library, save_path) == OK)
	var loaded = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	assert(loaded is PlayerRoleLibrary and loaded.roles.size() == 6)
	var roles: Array[PlayerRoleDefinition] = [primary, backup, middle, left, right, defender]
	# 1. Conventional 5-1: one primary, one conditional backup, shared receive.
	for rotation in range(1, 7):
		for phase in ["receive", "set", "attack", "block", "defence"]:
			assert(Preview.build_phase(rotation, phase, roles).size() == 6)
	var normal := Validator.validate(roles)
	assert(not normal.any(func(f): return f.level == "Error"))
	# 2. Setter prepares a second ball without being a receiver.
	var second_ball_setter := _role("Second ball setter")
	second_ball_setter.non_receiver_preparation = Role.Preparation.SET_SECOND_BALL
	var second_ball := Preview.build_phase(1, "receive", [second_ball_setter, backup, middle, left, right, defender])[0]
	assert(not second_ball.instructions.designated_receiver)
	assert(second_ball.target == RoleTacticalSystem.new().second_ball_preparation_target)
	# 3. A non-receiving middle prepares its attack rather than remaining still.
	var attack_middle := _role("Attack-prep middle")
	attack_middle.non_receiver_preparation = Role.Preparation.ATTACK
	attack_middle.front_attack_lane = Role.Lane.MIDDLE
	var middle_receive := Preview.build_phase(4, "receive", [attack_middle, backup, middle, left, right, defender])[0]
	assert(middle_receive.target != middle_receive.start)
	# 4. Attack lanes can differ by rotation via physical-position overrides.
	var changing_attack := _role("Changing attacker")
	changing_attack.front_attack_lane = Role.Lane.LEFT
	var left_override := PlayerRolePositionOverride.new(); left_override.physical_position = 4; left_override.rotations = [1]; left_override.instructions = changing_attack._base_instructions(); changing_attack.position_overrides.append(left_override)
	var middle_override := PlayerRolePositionOverride.new(); middle_override.physical_position = 4; middle_override.rotations = [2]; middle_override.instructions = changing_attack._base_instructions(); middle_override.instructions["front_attack_lane"] = Role.Lane.MIDDLE; changing_attack.position_overrides.append(middle_override)
	var right_override := PlayerRolePositionOverride.new(); right_override.physical_position = 4; right_override.rotations = [3]; right_override.instructions = changing_attack._base_instructions(); right_override.instructions["front_attack_lane"] = Role.Lane.RIGHT; changing_attack.position_overrides.append(right_override)
	var repeated: Array[PlayerRoleDefinition] = [changing_attack, changing_attack, changing_attack, changing_attack, changing_attack, changing_attack]
	assert(_player_at(Preview.build_phase(1, "attack", repeated), 4).target.z > 3.0)
	assert(abs(_player_at(Preview.build_phase(2, "attack", repeated), 4).target.z) < 0.1)
	assert(_player_at(Preview.build_phase(3, "attack", repeated), 4).target.z < -3.0)
	# 5/6. A physical front-middle setter follows court position 3 across rotations.
	var front_middle := _role("Front-middle setter")
	front_middle.designated_receiver = true
	var fm_instruction := front_middle._base_instructions(); fm_instruction["designated_setter_good_pass"] = true
	var fm_override := PlayerRolePositionOverride.new(); fm_override.physical_position = 3; fm_override.rotations = [1, 2, 3, 4, 5, 6]; fm_override.instructions = fm_instruction; front_middle.position_overrides.append(fm_override)
	var fm_lineup: Array[PlayerRoleDefinition] = [front_middle, front_middle, front_middle, front_middle, front_middle, front_middle]
	assert(not Validator.validate(fm_lineup).any(func(f): return f.level == "Error"))
	for rotation in range(1, 7):
		var setters := Preview.build_phase(rotation, "set", fm_lineup).filter(func(player): return bool(player.instructions.designated_setter_good_pass))
		assert(setters.size() == 1 and setters[0].physical_position == 3)
	var conflict: Array[PlayerRoleDefinition] = roles.duplicate()
	conflict[1] = primary.duplicate_role()
	var conflict_findings := Validator.validate(conflict)
	assert(conflict_findings.any(func(f): return f.level == "Error" and f.phase == "Setting"))
	var unusual: Array[PlayerRoleDefinition] = roles.duplicate()
	unusual[4].front_attack_lane = Role.Lane.MIDDLE
	var unusual_findings := Validator.validate(unusual)
	assert(not unusual_findings.any(func(f): return f.level == "Error"))
	# 7/8. Reopen after an edit; the edited role persists and its sibling does not change.
	primary.display_name = "Edited primary"
	library.add_or_replace(primary)
	assert(ResourceSaver.save(library, save_path) == OK)
	var reopened: PlayerRoleLibrary = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	assert(reopened.find_role(primary.id).display_name == "Edited primary")
	assert(reopened.find_role(middle.id).front_attack_lane == Role.Lane.MIDDLE)
	print("Role editor smoke test passed")
	get_tree().quit()

func _role(name: String) -> PlayerRoleDefinition:
	var role = Role.new()
	role.display_name = name
	role.ensure_id()
	return role

func _player_at(players: Array[Dictionary], physical_position: int) -> Dictionary:
	for player in players:
		if player.physical_position == physical_position:
			return player
	return {}
