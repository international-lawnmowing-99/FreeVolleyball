class_name TeamMatchData
extends RefCounted

var team: TeamData
var court_players: Array[AthleteStats]
var bench_players: Array[AthleteStats]
var sideout_rotations: int = 0

const ROTATION_BASE_POSITIONS := {
	1: Vector3(4.2, 0.0, -3.0),
	2: Vector3(1.4, 0.0, -3.0),
	3: Vector3(1.1, 0.0, 0.0),
	4: Vector3(1.4, 0.0, 3.0),
	5: Vector3(4.2, 0.0, 3.0),
	6: Vector3(4.0, 0.0, 0.0)
}

func _init(_team: TeamData):
	team = _team

	if team.courtPlayers.is_empty():
		team.select_starting_lineup()

	court_players = team.courtPlayers.duplicate()
	bench_players = team.benchPlayers.duplicate()
	_sync_rotation_positions()

func rotate_on_sideout() -> void:
	if court_players.size() < 2:
		return

	# Keep court_players in position order [1..6]. On side-out, team rotates:
	# P2 -> P1 (new server), P3 -> P2 ... P1 -> P6.
	var former_p1: AthleteStats = court_players[0]
	for i in range(court_players.size() - 1):
		court_players[i] = court_players[i + 1]
	court_players[court_players.size() - 1] = former_p1
	sideout_rotations += 1
	_sync_rotation_positions()

func choose_server() -> AthleteStats:
	if court_players.is_empty():
		push_error("No court players available for serving.")
		return null
	return court_players[0]

func get_phase_position_for_player(athlete: AthleteStats, phase: String, team_side: float, highlighted_player: AthleteStats = null, has_ball_control: bool = false) -> Vector3:
	if athlete == null:
		return Vector3.ZERO
	return _phase_court_position(athlete, phase, team_side, highlighted_player, has_ball_control)

func get_libero_on_court() -> AthleteStats:
	for athlete in court_players:
		if athlete.role == Enums.Role.Libero:
			return athlete
	return null

func get_serve_receive_candidates() -> Array[AthleteStats]:
	var primary: Array[AthleteStats] = []
	var secondary: Array[AthleteStats] = []
	for athlete in court_players:
		if athlete.role == Enums.Role.Outside or athlete.role == Enums.Role.Libero or athlete.role == Enums.Role.Opposite:
			primary.append(athlete)
		elif athlete.role != Enums.Role.Middle:
			secondary.append(athlete)

	if not primary.is_empty():
		return primary
	if not secondary.is_empty():
		return secondary
	return court_players.duplicate()

func get_best_receiver() -> AthleteStats:
	var candidates: Array[AthleteStats] = get_serve_receive_candidates()
	if candidates.is_empty():
		return null

	var best: AthleteStats = candidates[0]
	for athlete in candidates:
		if athlete.reception > best.reception:
			best = athlete
	return best

func get_worst_receiver() -> AthleteStats:
	var candidates: Array[AthleteStats] = get_serve_receive_candidates()
	if candidates.is_empty():
		return null

	var worst: AthleteStats = candidates[0]
	for athlete in candidates:
		if athlete.reception < worst.reception:
			worst = athlete
	return worst

func get_best_middle_attacker() -> AthleteStats:
	var best: AthleteStats = null
	var best_score: float = -INF
	for athlete in court_players:
		if athlete.role != Enums.Role.Middle:
			continue
		var score: float = athlete.spike + athlete.spikeHeight * 100.0 * 0.35
		if score > best_score:
			best = athlete
			best_score = score
	return best

func build_phase_context(phase: String, team_side: float, highlighted_player: AthleteStats = null, has_ball_control: bool = false) -> Dictionary:
	var players: Array[Dictionary] = []
	for athlete in court_players:
		var court_position: Vector3 = _phase_court_position(athlete, phase, team_side, highlighted_player, has_ball_control)
		players.append(_serialize_player_context(athlete, court_position, phase, highlighted_player, has_ball_control))

	return {
		"team_name": team.teamName,
		"side_sign": team_side,
		"side_label": "left" if team_side < 0.0 else "right",
		"phase": phase,
		"sideout_rotations": sideout_rotations,
		"players": players
	}

func _sync_rotation_positions() -> void:
	for i in range(court_players.size()):
		court_players[i].rotationPosition = i + 1

func _phase_court_position(athlete: AthleteStats, phase: String, team_side: float, highlighted_player: AthleteStats, has_ball_control: bool) -> Vector3:
	var rotation_position: int = int(clamp(athlete.rotationPosition, 1, 6))
	var base_local: Vector3 = ROTATION_BASE_POSITIONS.get(rotation_position, Vector3(3.0, 0.0, 0.0))
	var local: Vector3 = base_local
	var is_highlighted: bool = athlete == highlighted_player
	var is_front_row: bool = rotation_position >= 2 and rotation_position <= 4

	match phase:
		"serve":
			if is_highlighted:
				local = Vector3(4.9, 0.0, base_local.z)
			else:
				local.x = max(base_local.x - 0.45, 0.9)
		"receive":
			local.x = base_local.x + (0.4 if not is_front_row else 0.15)
			if athlete.role == Enums.Role.Setter:
				local = Vector3(1.2, 0.0, -0.6 if base_local.z < 0.0 else 0.6)
			elif is_highlighted:
				local = Vector3(3.6, 0.0, base_local.z)
		"set":
			if is_highlighted:
				local = Vector3(0.85, 0.0, clamp(base_local.z * 0.3, -1.0, 1.0))
			elif is_front_row:
				local = Vector3(max(base_local.x - 0.55, 0.7), 0.0, base_local.z)
			else:
				local.x = base_local.x + 0.2
		"attack":
			if is_highlighted:
				local = Vector3(0.55, 0.0, base_local.z)
			elif is_front_row:
				local = Vector3(max(base_local.x - 0.75, 0.6), 0.0, base_local.z * 0.9)
			else:
				local.x = base_local.x + 0.35
		"block":
			if is_front_row:
				local = Vector3(0.35, 0.0, base_local.z * 0.7)
			else:
				local = Vector3(base_local.x + 0.2, 0.0, base_local.z * 0.9)
			if is_highlighted:
				local.x = 0.2

	if not has_ball_control and phase in ["receive", "set", "attack"]:
		local.x = min(local.x + 0.25, 4.4)

	return Vector3(local.x * team_side, local.y, local.z)

func _serialize_player_context(athlete: AthleteStats, court_position: Vector3, phase: String, highlighted_player: AthleteStats, has_ball_control: bool) -> Dictionary:
	var role_id: int = int(athlete.role)
	var rotation_position: int = int(athlete.rotationPosition)
	var is_highlighted: bool = athlete == highlighted_player
	var is_front_row: bool = rotation_position >= 2 and rotation_position <= 4
	var stamina: float = float(athlete.stamina)
	var internal_state := {
		"role_id": role_id,
		"role_name": _role_name(role_id),
		"rotation_position": rotation_position,
		"is_front_row": is_front_row,
		"is_back_row": not is_front_row,
		"is_server": rotation_position == 1,
		"is_highlighted": is_highlighted,
		"has_ball_control": has_ball_control,
		"phase_focus": _phase_focus_label(phase, is_highlighted, has_ball_control, is_front_row),
		"phase_readiness": _phase_readiness(athlete, phase, is_front_row),
		"stamina": stamina,
		"fatigue": float(clamp(1.0 - stamina, 0.0, 1.0)),
		"game_read": float(athlete.gameRead),
		"speed": float(athlete.speed),
		"vertical_jump": float(athlete.verticalJump),
		"spike_height": float(athlete.spikeHeight),
		"block_height": float(athlete.blockHeight),
		"skills": {
			"serve": float(athlete.serve),
			"reception": float(athlete.reception),
			"set": float(athlete.set),
			"spike": float(athlete.spike),
			"block": float(athlete.block)
		}
	}

	return {
		"player_name": "%s %s" % [athlete.firstName, athlete.lastName],
		"position": {
			"x": court_position.x,
			"y": court_position.y,
			"z": court_position.z
		},
		"internal_state": internal_state
	}

func _phase_focus_label(phase: String, is_highlighted: bool, has_ball_control: bool, is_front_row: bool) -> String:
	if is_highlighted:
		match phase:
			"serve":
				return "ball_contact"
			"receive":
				return "first_contact"
			"set":
				return "distribution"
			"attack":
				return "terminal_swing"
			"block":
				return "block_contact"

	if has_ball_control:
		match phase:
			"receive":
				return "passing_shape"
			"set":
				return "transition_support"
			"attack":
				return "coverage"

	if phase == "block":
		return "net_press" if is_front_row else "defensive_cover"

	return "base_defence" if is_front_row else "backcourt_balance"

func _phase_readiness(athlete: AthleteStats, phase: String, is_front_row: bool) -> float:
	var primary_skill: float = 50.0
	match phase:
		"serve":
			primary_skill = float(athlete.serve)
		"receive":
			primary_skill = float(athlete.reception)
		"set":
			primary_skill = float(athlete.set)
		"attack":
			primary_skill = float(athlete.spike if is_front_row else athlete.reception)
		"block":
			primary_skill = float(athlete.block if is_front_row else athlete.reception)

	return float(clamp(primary_skill / 100.0 * 0.65 + athlete.gameRead * 0.2 + athlete.stamina * 0.15, 0.0, 1.0))

func _role_name(role_id: int) -> String:
	match role_id:
		Enums.Role.Setter:
			return "setter"
		Enums.Role.Middle:
			return "middle"
		Enums.Role.Outside:
			return "outside"
		Enums.Role.Opposite:
			return "opposite"
		Enums.Role.Libero:
			return "libero"
		_:
			return "unknown"
