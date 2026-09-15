extends RefCounted
class_name SystemValidator

static func validate(system: TeamSystem) -> Array[Dictionary]:
	var findings: Array[Dictionary] = []
	if system == null:
		return findings
	system.initialize_default_roles()
	if system.rotation_roles.size() < 36:
		return findings
	for rotation in range(1, 7):
		var front: Array[String] = []
		var back: Array[String] = []
		var missing_attack: Array[String] = []
		var missing_defence: Array[String] = []
		var missing_block: Array[String] = []
		var receivers: Array[String] = []
		var setters: Array[String] = []
		for slot in range(6):
			var physical := ((slot + rotation - 1) % 6) + 1
			var role: PlayerRoleDefinition = system.role_for(rotation, slot)
			var player_name := role.display_name if role != null else "Player %s" % char(65 + slot)
			if physical >= 2 and physical <= 4:
				front.append(player_name)
				if role == null or not role.attack:
					missing_attack.append(player_name)
				if role == null or not role.block:
					missing_block.append(player_name)
			else:
				back.append(player_name)
				if role == null or not role.defend:
					missing_defence.append(player_name)
			if role != null and role.receive:
				receivers.append(player_name)
			if role != null and role.set_role:
				setters.append(player_name)
		if not missing_attack.is_empty():
			findings.append(_finding(rotation, "Attack", "%s are front-court players without Attack designated. Consider selecting Attack for the players who should take attacking responsibility." % ", ".join(missing_attack)))
		if setters.is_empty():
			findings.append(_finding(rotation, "Set", "No setter is designated in this rotation. Consider selecting Set for the player expected to take the second touch."))
		if not missing_defence.is_empty():
			findings.append(_finding(rotation, "Defend", "%s are back-court players without Defend designated. Consider selecting Defend for the players who should cover the back court." % ", ".join(missing_defence)))
		if not missing_block.is_empty():
			findings.append(_finding(rotation, "Block", "%s are front-court players without Block designated. Consider selecting Block for the players who should block." % ", ".join(missing_block)))
		if receivers.is_empty():
			findings.append(_finding(rotation, "Receive", "No receiver is designated in this rotation. Consider selecting Receive for one or more players who should handle the first touch."))
	return findings

static func _finding(rotation: int, area: String, message: String) -> Dictionary:
	return {"rotation": rotation, "area": area, "message": message}
