extends RefCounted
class_name RoleLineupValidator

const Preview = preload("res://_newhierarchy/simulation/team/roles/RolePreviewResolver.gd")

static func validate(roles: Array[PlayerRoleDefinition], tactical_system: RoleTacticalSystem = null) -> Array[Dictionary]:
	var findings: Array[Dictionary] = []
	if roles.size() != 6 or roles.has(null):
		findings.append(_finding("Error", "Lineup", 0, "All six player slots need a role before the lineup can be resolved."))
		return findings
	for rotation in range(1, 7):
		var receive := Preview.build_phase(rotation, "receive", roles, tactical_system)
		var setting := Preview.build_phase(rotation, "set", roles, tactical_system)
		_check_setters(rotation, setting, findings)
		_check_receivers(rotation, receive, findings)
		# Attack and block lanes may deliberately contain more than one player.
		# Only simultaneous receive/defence home positions are hard conflicts.
		for phase in ["receive", "defence"]:
			_check_position_collisions(rotation, phase, Preview.build_phase(rotation, phase, roles, tactical_system), findings)
	if findings.is_empty():
		findings.append(_finding("Informational", "Lineup", 0, "All rotations resolve with the supplied responsibilities. Unusual but legal systems are allowed."))
	return findings

static func _check_setters(rotation: int, players: Array[Dictionary], findings: Array[Dictionary]) -> void:
	var primary: Array[String] = []
	var backups: Array[String] = []
	for player in players:
		var i: Dictionary = player.instructions
		if bool(i.get("designated_setter_good_pass", false)): primary.append(player.role_name)
		if bool(i.get("backup_setter_if_primary_receives", false)): backups.append(player.role_name)
	if primary.size() != 1:
		findings.append(_finding("Error", "Setting", rotation, "Expected one designated setter for a good pass; found %d (%s)." % [primary.size(), ", ".join(primary)]))
	if backups.size() > 1:
		findings.append(_finding("Error", "Setting", rotation, "Multiple backup setters create an ambiguous priority: %s." % ", ".join(backups)))
	elif backups.is_empty():
		findings.append(_finding("Warning", "Setting", rotation, "No backup setter is designated if the primary setter receives the first ball."))

static func _check_receivers(rotation: int, players: Array[Dictionary], findings: Array[Dictionary]) -> void:
	var names: Array[String] = []
	for player in players:
		if bool(player.instructions.get("designated_receiver", false)): names.append(player.role_name)
	if names.is_empty():
		findings.append(_finding("Error", "Serve reception", rotation, "No designated receiver is available."))
	elif names.size() == 1:
		findings.append(_finding("Warning", "Serve reception", rotation, "Only %s is designated to receive; this is resolvable but leaves no shared receive responsibility." % names[0]))

static func _check_position_collisions(rotation: int, phase: String, players: Array[Dictionary], findings: Array[Dictionary]) -> void:
	for first in range(players.size()):
		for second in range(first + 1, players.size()):
			var a: Vector3 = players[first].target
			var b: Vector3 = players[second].target
			if a.distance_to(b) < 0.20:
				findings.append(_finding("Error", phase.capitalize(), rotation, "%s and %s have the same resolved court position." % [players[first].role_name, players[second].role_name]))

static func _finding(level: String, phase: String, rotation: int, message: String) -> Dictionary:
	return {"level": level, "phase": phase, "rotation": rotation, "message": message}
