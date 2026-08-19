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

func get_server() -> AthleteStats:
	if court_players.is_empty():
		push_error("No court players available for serving.")
		return null
	return court_players[0]

func player_key_for_athlete(athlete: AthleteStats) -> String:
	if athlete == null:
		return ""
	return "%s %s#%d" % [athlete.firstName, athlete.lastName, int(athlete.rotationPosition)]

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

func build_phase_context(
	phase: String,
	team_side: float,
	highlighted_player: AthleteStats = null,
	has_ball_control: bool = false,
	movement_states: Dictionary = {},
	current_time: float = 0.0
) -> Dictionary:
	var players: Array[Dictionary] = []
	for athlete in court_players:
		var player_key: String = player_key_for_athlete(athlete)
		var tracking_key: String = "%s::%s" % [team.teamName, player_key]
		var movement_state: Dictionary = movement_states.get(tracking_key, {})
		var court_position: Vector3 = movement_state.get(
			"position",
			_phase_court_position(athlete, phase, team_side, highlighted_player, has_ball_control)
		)
		players.append(_serialize_player_context(
			athlete,
			court_position,
			phase,
			highlighted_player,
			has_ball_control,
			movement_state,
			current_time
		))

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
	var local: Vector3 = ROTATION_BASE_POSITIONS.get(int(clamp(athlete.rotationPosition, 1, 6)), Vector3(3.0, 0.0, 0.0))
	if team != null and team.teamStrategy != null:
		local = team.teamStrategy.phase_local_target(
			athlete,
			self,
			phase,
			highlighted_player,
			has_ball_control
		)
	return Vector3(local.x * team_side, local.y, local.z)

func _serialize_player_context(
	athlete: AthleteStats,
	court_position: Vector3,
	phase: String,
	highlighted_player: AthleteStats,
	has_ball_control: bool,
	movement_state: Dictionary = {},
	current_time: float = 0.0
) -> Dictionary:
	var role_id: int = int(athlete.role)
	var rotation_position: int = int(athlete.rotationPosition)
	var is_highlighted: bool = athlete == highlighted_player
	var is_front_row: bool = rotation_position >= 2 and rotation_position <= 4
	var stamina: float = float(athlete.stamina)
	var animation_state := _build_replay_animation_state(athlete, phase, is_highlighted, has_ball_control, is_front_row)
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
	if not movement_state.is_empty():
		internal_state["movement"] = {
			"current_position": {
				"x": court_position.x,
				"y": court_position.y,
				"z": court_position.z
			},
			"goal_position": _vector3_to_dict(movement_state.get("goal_position", court_position)),
			"start_position": _vector3_to_dict(movement_state.get("start_position", court_position)),
			"phase": str(movement_state.get("phase", phase)),
			"state": str(movement_state.get("movement_state", "")),
			"intent": str(movement_state.get("movement_intent", "")),
			"plan_type": str(movement_state.get("plan_type", "ground")),
			"plan_start_time": float(movement_state.get("plan_start_time", current_time)),
			"expected_arrival_time": float(movement_state.get("expected_arrival_time", current_time)),
			"time_remaining": float(movement_state.get("time_remaining", 0.0)),
			"distance_to_goal": float(movement_state.get("distance_to_goal", 0.0)),
			"movement_complete": bool(movement_state.get("movement_complete", true)),
			"is_airborne": bool(movement_state.get("is_airborne", false)),
			"takeoff_time": float(movement_state.get("takeoff_time", -1.0)),
			"contact_time": float(movement_state.get("contact_time", -1.0)),
			"landing_time": float(movement_state.get("landing_time", -1.0)),
			"jump_height": float(movement_state.get("jump_height", 0.0)),
			"substeps": movement_state.get("substeps", []).duplicate(true)
		}

	return {
		"player_key": player_key_for_athlete(athlete),
		"player_name": "%s %s" % [athlete.firstName, athlete.lastName],
		"position": {
			"x": court_position.x,
			"y": court_position.y,
			"z": court_position.z
		},
		"animation": animation_state,
		"internal_state": internal_state
	}

func _build_replay_animation_state(
	athlete: AthleteStats,
	phase: String,
	is_highlighted: bool,
	has_ball_control: bool,
	is_front_row: bool
) -> Dictionary:
	var animation_name := "idle_base_stub"
	var playback_mode := "loop"
	var intent := "hold_shape"

	if is_highlighted:
		match phase:
			"serve":
				animation_name = "serve_contact_stub"
				playback_mode = "one_shot"
				intent = "strike_ball"
			"receive":
				animation_name = "dig_contact_stub"
				playback_mode = "one_shot"
				intent = "absorb_ball"
			"set":
				animation_name = "jump_set_stub"
				playback_mode = "one_shot"
				intent = "distribute_ball"
			"attack":
				animation_name = "spike_contact_stub"
				playback_mode = "one_shot"
				intent = "terminal_attack"
			"block":
				animation_name = "block_press_stub"
				playback_mode = "one_shot"
				intent = "seal_net"
	else:
		match phase:
			"serve":
				animation_name = "serve_receive_shape_stub"
				intent = "prepare_transition"
			"receive":
				animation_name = "receive_ready_stub"
				intent = "form_passing_shape"
			"set":
				animation_name = "approach_adjust_stub" if is_front_row else "coverage_balance_stub"
				intent = "attack_window_adjustment" if is_front_row else "coverage_balance"
			"attack":
				animation_name = "approach_run_stub" if is_front_row else "coverage_read_stub"
				intent = "attack_approach" if is_front_row else "coverage_read"
			"block":
				animation_name = "block_ready_stub" if is_front_row else "defensive_cover_stub"
				intent = "net_press_ready" if is_front_row else "dig_cover"

	if has_ball_control and not is_highlighted:
		animation_name = "transition_support_stub"
		intent = "support_ball_control"

	return {
		"name": animation_name,
		"intent": intent,
		"playback_mode": playback_mode,
		"speed_scale": clamp(0.8 + float(athlete.speed) * 0.08, 0.7, 1.5),
		"is_stub": true,
		"source": "phase_context_heuristic"
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

func _vector3_to_dict(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}
