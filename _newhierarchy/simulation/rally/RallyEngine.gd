extends RefCounted

class_name RallyEngine

var rng:RandomNumberGenerator
var workflow_log: SimulationEventLog

const COURT_HALF_LENGTH: float = 4.5
const NET_HEIGHT: float = 2.43
const CONTACT_HEIGHT_MARGIN: float = 0.35
const TOUCH_TIME_STEP: float = 0.35

func _init(_rng, _workflow_log: SimulationEventLog = null) -> void:
	rng = _rng
	workflow_log = _workflow_log

func Resolve(ctx: RallyState) -> RallyState:
	_log_phase(ctx, "serve", "Choosing serving strategy for this rally.", ctx.serving_team, ctx.server)
	_choose_serving_strategy(ctx)
	_log_phase(ctx, "receive", "Choosing receive-side attacking strategy.", ctx.receiving_team)
	var current_result = _resolve_serve(ctx)

	while not current_result.is_terminal:
		_log_phase(ctx, "receive", "Choosing serve receiver.", current_result.defender)
		current_result = _resolve_pass(current_result)
		if current_result.is_terminal: break

		_log_phase(ctx, "pass", "Passing team assessing setter access and attack timing.", current_result.defender)
		_log_phase(ctx, "pass", "Defending team assessing likely set threats.", current_result.attacker)
		_log_phase(ctx, "set", "Choosing set option.", current_result.defender)
		current_result = _resolve_set(current_result)
		if current_result.is_terminal: break

		_log_phase(ctx, "attack", "Attackers reacting to the actual set trajectory.", current_result.defender)
		_log_phase(ctx, "defence", "Defending team reacting to set.", current_result.attacker)
		_log_phase(ctx, "attack", "Attacker assessing defence and attack type.", current_result.defender)
		current_result = _resolve_attack(current_result)
		if current_result.is_terminal: break

		current_result = _resolve_block(current_result)
		if current_result.is_terminal: break

		_log_phase(ctx, "rally", "Resolving continuation after block phase.")
		current_result = _resolve_defence_phase(current_result)
		if current_result.is_terminal: break

	_log_rally_end(current_result)
	return current_result

func _resolve_serve(ctx: RallyState) -> RallyState:
	_log_phase(ctx, "serve", "Executing serve.", ctx.serving_team, ctx.server)
	var server: AthleteStats = ctx.server
	if server == null and ctx.serving_team_match_data != null:
		server = ctx.serving_team_match_data.choose_server()
	if server == null:
		server = ctx.serving_team.choose_server()
	var attempt := ServeAttempt.new(server, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "serve", ctx.serving_team, ctx.defender)
	_log_action(ctx, "SERVE", outcome, ctx.serving_team)

	return ctx

func _resolve_pass(ctx: RallyState) -> RallyState:
	var passer = ctx.defender.teamStrategy.choose_passer(ctx.defender_match_data, rng)
	_log_phase(ctx, "pass", "Executing pass.", ctx.defender, passer)
	var attempt := PassAttempt.new(passer, ctx, rng)

	var outcome := attempt.resolve()

	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "receive", ctx.defender, ctx.attacker)
	_log_action(ctx, "RECEIVE", outcome, ctx.defender)

	return ctx

func _resolve_set(ctx:RallyState) -> RallyState:
	var setter = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	_log_phase(ctx, "set", "Executing set.", ctx.defender, setter)
	var attempt := SetAttempt.new(setter, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "set", ctx.defender, ctx.attacker)
	_log_action(ctx, "SET", outcome, ctx.defender)

	return ctx

func _resolve_attack(ctx:RallyState) -> RallyState:
	var attacker = ctx.defender.teamStrategy.choose_attacker(ctx.defender_match_data, rng)
	_log_phase(ctx, "attack", "Executing spike.", ctx.defender, attacker)
	var attempt := AttackAttempt.new(attacker, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "attack", ctx.defender, ctx.attacker)
	_log_action(ctx, "SPIKE", outcome, ctx.defender)

	return ctx

func _resolve_block(ctx:RallyState) -> RallyState:
	var blocker = ctx.attacker.teamStrategy.choose_blocker(ctx.attacker_match_data, rng)
	_log_phase(ctx, "block", "Executing block.", ctx.attacker, blocker)
	var attempt := BlockAttempt.new(blocker, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "block", ctx.attacker, ctx.defender)
	_log_action(ctx, "BLOCK ATTEMPT", outcome, ctx.attacker)

	return ctx

func _resolve_defence_phase(ctx:RallyState) -> RallyState:
	var previous_attacker: TeamData = ctx.attacker
	var previous_attacker_match_data: TeamMatchData = ctx.attacker_match_data
	ctx.attacker = ctx.defender
	ctx.attacker_match_data = ctx.defender_match_data
	ctx.defender = previous_attacker
	ctx.defender_match_data = previous_attacker_match_data
	return ctx

func _apply_outcome(ctx: RallyState, outcome: AttemptOutcome) -> void:
	if outcome.terminal:
		ctx.is_terminal = true
		ctx.point_winner = outcome.point_winner

func _log_action(ctx: RallyState, action: String, outcome: AttemptOutcome, team: TeamData) -> void:
	var athlete_name := _athlete_name(outcome.actor)
	var result := str(outcome.metadata.get("result", ""))
	_emit_step(ctx,
		"[Rally %d] %s | %s: %s (%s)"
		% [ctx.rally_number, team.teamName, athlete_name, action, result]
	)

func _log_rally_end(ctx: RallyState) -> void:
	_emit_step(ctx, "[Rally %d] RALLY END: %s wins point" % [ctx.rally_number, ctx.point_winner.teamName])

func _athlete_name(athlete: AthleteStats) -> String:
	if athlete == null:
		return "Unknown Athlete"

	return "%s %s" % [athlete.firstName, athlete.lastName]

func _record_ball_touch(ctx: RallyState, outcome: AttemptOutcome, phase: String, source_team: TeamData, target_team: TeamData) -> void:
	ctx.touch_count += 1
	var snapshot := _build_ball_snapshot(ctx, outcome, phase, source_team, target_team)
	ctx.ball_position = snapshot["position"]
	ctx.ball_velocity = snapshot["velocity"]
	ctx.ball_topspin = snapshot["topspin"]
	ctx.ball_time = snapshot["timestamp"]
	var phase_context: Dictionary = _build_phase_context_snapshot(ctx, phase, outcome, source_team, target_team)
	ctx.phase_context = phase_context
	ctx.phase_context_history.append(phase_context.duplicate(true))
	outcome.metadata["ball_snapshot"] = _serialize_ball_snapshot(snapshot)
	outcome.metadata["phase_context"] = phase_context.duplicate(true)
	ctx.event_log.add_ball_touch(_serialize_ball_snapshot(snapshot))
	ctx.event_log.add_context_snapshot(phase_context.duplicate(true))

	_emit_step(ctx,
		"[Rally %d] BALL %s | pos=%s vel=%s topspin=%.3f"
		% [
			ctx.rally_number,
			phase.to_upper(),
			str(snapshot["position"]),
			str(snapshot["velocity"]),
			snapshot["topspin"]
		]
	)

func _build_ball_snapshot(ctx: RallyState, outcome: AttemptOutcome, phase: String, source_team: TeamData, target_team: TeamData) -> Dictionary:
	var source_side: float = _team_side_sign(ctx, source_team)
	var target_side: float = _team_side_sign(ctx, target_team)
	var trajectory: Dictionary = _phase_trajectory(phase)
	var position: Vector3 = Vector3(
		source_side * float(trajectory["source_x"]),
		float(trajectory["height"]),
		float(trajectory["z"])
	)
	var target_position: Vector3 = Vector3(
		target_side * float(trajectory["target_x"]),
		float(trajectory["target_height"]),
		float(trajectory["target_z"])
	)
	var travel_time: float = float(trajectory["travel_time"])
	var velocity: Vector3 = (target_position - position) / max(travel_time, 0.01)
	var topspin: float = _phase_topspin(phase, outcome)

	if phase == "block" and str(outcome.metadata.get("result", "")) == "stuff_block":
		velocity = Vector3(-velocity.x * 0.55, max(velocity.y * 0.2, -2.0), velocity.z * 0.25)

	return {
		"touch_index": ctx.touch_count,
		"phase": phase,
		"actor_name": _athlete_name(outcome.actor),
		"team_name": source_team.teamName if source_team != null else "",
		"position": position,
		"velocity": velocity,
		"topspin": topspin,
		"timestamp": ctx.ball_time + TOUCH_TIME_STEP,
		"result": str(outcome.metadata.get("result", ""))
	}

func _build_phase_context_snapshot(ctx: RallyState, phase: String, outcome: AttemptOutcome, source_team: TeamData, target_team: TeamData) -> Dictionary:
	var source_match_data: TeamMatchData = _match_data_for_team(ctx, source_team)
	var target_match_data: TeamMatchData = _match_data_for_team(ctx, target_team)
	var source_side: float = _team_side_sign(ctx, source_team)
	var target_side: float = _team_side_sign(ctx, target_team)
	var source_context: Dictionary = {}
	var target_context: Dictionary = {}

	if source_match_data != null:
		source_context = source_match_data.build_phase_context(phase, source_side, outcome.actor, true)
	if target_match_data != null:
		target_context = target_match_data.build_phase_context(phase, target_side, outcome.actor, false)

	var position: Vector3 = ctx.ball_position
	var velocity: Vector3 = ctx.ball_velocity
	return {
		"touch_index": ctx.touch_count,
		"phase": phase,
		"actor_name": _athlete_name(outcome.actor),
		"timestamp": ctx.ball_time,
		"ball_state": {
			"position": {"x": position.x, "y": position.y, "z": position.z},
			"velocity": {"x": velocity.x, "y": velocity.y, "z": velocity.z},
			"topspin": ctx.ball_topspin
		},
		"teams": [source_context, target_context]
	}

func _phase_trajectory(phase: String) -> Dictionary:
	match phase:
		"serve":
			return {
				"source_x": COURT_HALF_LENGTH - 0.2,
				"height": 2.7,
				"z": rng.randf_range(-3.5, 3.5),
				"target_x": COURT_HALF_LENGTH - 1.6,
				"target_height": 1.05,
				"target_z": rng.randf_range(-3.2, 3.2),
				"travel_time": 0.78
			}
		"receive":
			return {
				"source_x": COURT_HALF_LENGTH - 1.8,
				"height": 0.95,
				"z": rng.randf_range(-3.0, 3.0),
				"target_x": 1.4,
				"target_height": 2.3,
				"target_z": rng.randf_range(-1.0, 1.0),
				"travel_time": 0.62
			}
		"set":
			return {
				"source_x": 1.1,
				"height": 2.35,
				"z": rng.randf_range(-1.0, 1.0),
				"target_x": 0.6,
				"target_height": 3.05,
				"target_z": rng.randf_range(-4.0, 4.0),
				"travel_time": 0.54
			}
		"attack":
			return {
				"source_x": 0.8,
				"height": 3.15,
				"z": rng.randf_range(-4.2, 4.2),
				"target_x": COURT_HALF_LENGTH - 1.1,
				"target_height": 0.9,
				"target_z": rng.randf_range(-3.8, 3.8),
				"travel_time": 0.38
			}
		"block":
			return {
				"source_x": 0.15,
				"height": NET_HEIGHT + CONTACT_HEIGHT_MARGIN,
				"z": rng.randf_range(-2.7, 2.7),
				"target_x": 1.4,
				"target_height": 1.4,
				"target_z": rng.randf_range(-2.5, 2.5),
				"travel_time": 0.24
			}
		_:
			return {
				"source_x": 0.0,
				"height": 0.0,
				"z": 0.0,
				"target_x": 0.0,
				"target_height": 0.0,
				"target_z": 0.0,
				"travel_time": 0.5
			}

func _phase_topspin(phase: String, outcome: AttemptOutcome) -> float:
	var skill_value: float = 50.0
	match phase:
		"serve":
			skill_value = float(outcome.actor.serve)
		"receive":
			skill_value = float(outcome.actor.reception)
		"set":
			skill_value = float(outcome.actor.set)
		"attack":
			skill_value = float(outcome.actor.spike)
		"block":
			skill_value = float(outcome.actor.block)

	var normalized_skill: float = float(clamp(skill_value / 100.0, 0.0, 1.2))
	match phase:
		"serve":
			return float(clamp(4.0 + normalized_skill * 8.0 + rng.randf_range(-0.5, 0.5), 2.5, 13.0))
		"receive":
			return float(clamp(0.4 + (1.0 - normalized_skill) * 1.1 + rng.randf_range(-0.15, 0.15), 0.0, 2.0))
		"set":
			return float(clamp(0.25 + (1.0 - normalized_skill) * 0.8 + rng.randf_range(-0.1, 0.1), 0.0, 1.4))
		"attack":
			return float(clamp(7.0 + normalized_skill * 11.0 + rng.randf_range(-0.8, 0.8), 5.0, 20.0))
		"block":
			var result := str(outcome.metadata.get("result", ""))
			if result == "stuff_block":
				return float(clamp(1.4 + normalized_skill * 2.0 + rng.randf_range(-0.2, 0.2), 0.8, 4.0))
			if result == "soft_touch_continues":
				return float(clamp(0.5 + normalized_skill * 1.3 + rng.randf_range(-0.2, 0.2), 0.2, 2.4))
			return 0.0
		_:
			return 0.0

func _team_side_sign(ctx: RallyState, team: TeamData) -> float:
	if team == null:
		return 1.0
	if team == ctx.serving_team:
		return -1.0
	return 1.0

func _match_data_for_team(ctx: RallyState, team: TeamData) -> TeamMatchData:
	if team == ctx.attacker:
		return ctx.attacker_match_data
	if team == ctx.defender:
		return ctx.defender_match_data
	if team == ctx.serving_team:
		return ctx.serving_team_match_data
	if team == ctx.receiving_team:
		return ctx.receiving_team_match_data
	return null

func _serialize_ball_snapshot(snapshot: Dictionary) -> Dictionary:
	var position: Vector3 = snapshot["position"]
	var velocity: Vector3 = snapshot["velocity"]
	return {
		"touch_index": snapshot["touch_index"],
		"phase": snapshot["phase"],
		"actor_name": snapshot["actor_name"],
		"team_name": snapshot["team_name"],
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"velocity": {"x": velocity.x, "y": velocity.y, "z": velocity.z},
		"topspin": snapshot["topspin"],
		"timestamp": snapshot["timestamp"],
		"result": snapshot["result"]
	}

func _choose_serving_strategy(ctx: RallyState) -> void:
	if ctx.serving_team == null or ctx.serving_team.teamStrategy == null:
		return

	if ctx.server == null and ctx.serving_team_match_data != null:
		ctx.server = ctx.serving_team_match_data.choose_server()
	if ctx.server == null:
		ctx.server = ctx.serving_team.choose_server()
	if ctx.server == null:
		return

	var plan: Dictionary = ctx.serving_team.teamStrategy.choose_serve_plan(
		ctx.server,
		ctx.serving_team_match_data,
		ctx.receiving_team_match_data,
		rng
	)
	ctx.serve_target = plan.get("target", Vector3.ZERO)
	ctx.serve_type = str(plan.get("serve_type", "float"))
	ctx.serve_aggression = str(plan.get("aggression", "moderate"))
	ctx.serve_target_strategy = str(plan.get("strategy", ""))
	ctx.serve_target_receiver_name = str(plan.get("target_player_name", ""))
	ctx.serve_target_reception = float(plan.get("target_player_reception", 0.0))

	var target_summary := "target=%s type=%s aggression=%s strategy=%s" % [
		str(ctx.serve_target),
		ctx.serve_type,
		ctx.serve_aggression,
		ctx.serve_target_strategy
	]
	if ctx.serve_target_receiver_name != "":
		target_summary += " receiver=%s" % ctx.serve_target_receiver_name
	_emit_step(ctx, "[Sim][serve] Serve plan locked in | %s" % target_summary)

func _log_phase(ctx: RallyState, phase: String, message: String, team: TeamData = null, athlete: AthleteStats = null) -> void:
	if ctx != null and workflow_log != null and workflow_log.verbosity >= SimulationEventLog.Verbosity.BASIC:
		var team_name := "N/A"
		var athlete_name := "N/A"
		if team != null:
			team_name = team.teamName
		if athlete != null:
			athlete_name = "%s %s" % [athlete.firstName, athlete.lastName]
		_emit_step(ctx, "[Sim][%s] %s | Team=%s | Player=%s" % [phase, message, team_name, athlete_name])

	if workflow_log == null:
		return
	workflow_log.log(phase, message, team, athlete)

func _emit_step(ctx: RallyState, message: String) -> void:
	if ctx != null:
		ctx.step_messages.append(message)
	print(message)
