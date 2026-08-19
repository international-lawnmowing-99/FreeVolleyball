extends RefCounted

class_name RallyEngine

const SetPlayAnalysis = preload("res://_newhierarchy/simulation/tactics/SetPlayAnalysis.gd")
const PlayerMovementPlanner = preload("res://_newhierarchy/simulation/team/PlayerMovementPlanner.gd")

var rng:RandomNumberGenerator
var workflow_log: SimulationEventLog

const COURT_HALF_LENGTH: float = 4.5
const NET_HEIGHT: float = 2.43
const CONTACT_HEIGHT_MARGIN: float = 0.35

func _init(_rng, _workflow_log: SimulationEventLog = null) -> void:
	rng = _rng
	workflow_log = _workflow_log

func Resolve(ctx: RallyState) -> RallyState:
	PlayerMovementPlanner.initialize_rally_tracking(ctx)
	_log_phase(ctx, "pre serve", "Choosing serving strategy for this rally.", ctx.serving_team, ctx.server)
	_choose_serving_strategy(ctx)
	_log_phase(ctx, "pre serve - receiving team", "Choosing serve-receive strategy for this rally.", ctx.serving_team, ctx.server)
	_choose_receiving_strategy(ctx)

	_log_phase(ctx, "receive", "Choosing receive-side attacking strategy.", ctx.receiving_team)
	var current_result:RallyState = _resolve_serve(ctx)

	while not current_result.is_terminal:
		match current_result.next_phase:
			Enums.Phase.Receive:

				_log_phase(ctx, "receive", "Executing receive. Choosing serve receiver/resolving outcome", current_result.defender)
				current_result = _resolve_pass(current_result)
				if current_result.is_terminal: break

			Enums.Phase.Set:
				if current_result.chosen_set_option.is_empty():
					_assess_set_phase(current_result)
				_log_phase(ctx, "pass", "Defending team assessing likely set threats.", current_result.attacker)
				_log_phase(ctx, "set", "Choosing set option.", current_result.defender)
				current_result = _resolve_set(current_result)
				if current_result.is_terminal: break

			Enums.Phase.Attack:
				_log_phase(ctx, "attack", "Attackers reacting to the actual set trajectory.", current_result.defender)
				_log_phase(ctx, "defence", "Defending team reacting to set.", current_result.attacker)
				_log_phase(ctx, "attack", "Attacker assessing defence and attack type.", current_result.defender)
				current_result = _resolve_attack(current_result)
				if current_result.is_terminal: break

			Enums.Phase.Block:
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
		server = ctx.serving_team_match_data.get_server()
	if server == null:
		server = ctx.serving_team.get_server()
	var attempt := ServeAttempt.new(server, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "serve", ctx.serving_team, ctx.defender)
	_log_action(ctx, "SERVE", outcome, ctx.serving_team)

	return ctx

func _resolve_pass(ctx: RallyState) -> RallyState:

	_log_phase(ctx, "prePass", "TODO: consult strategy to decide if attacking (dog-shotting the serve), or setting off the serve is a desirable option")
	if true: #how do we decide this?
		ctx.next_phase = Enums.Phase.Set

	var passer = ctx.defender.teamStrategy.choose_passer(ctx.defender_match_data, rng)
	_log_phase(ctx, "pass", "Executing pass.", ctx.defender, passer)
	var attempt := PassAttempt.new(passer, ctx, rng)

	var outcome := attempt.resolve()

	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	ctx.last_pass_target = _vector3_from_metadata(outcome.metadata.get("reception_target", {}), ctx.last_pass_target)
	ctx.last_pass_band = str(outcome.metadata.get("pass_band", ""))
	ctx.last_pass_quality = float(outcome.pass_quality)
	_assess_set_phase(ctx)
	_record_ball_touch(ctx, outcome, "receive", ctx.defender, ctx.attacker)
	_log_action(ctx, "RECEIVE", outcome, ctx.defender)

	return ctx

func _resolve_set(ctx:RallyState) -> RallyState:

	_log_phase(ctx, "prePass", "TODO: consult strategy to decide if attacking (dumping) is a desirable option")
	if true:
		ctx.next_phase = Enums.Phase.Attack

	var setter = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	if ctx.chosen_set_option.is_empty():
		_assess_set_phase(ctx, setter)
	_log_phase(ctx, "set", "Executing set.", ctx.defender, setter)
	var attempt := SetAttempt.new(setter, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "set", ctx.defender, ctx.attacker)
	_log_action(ctx, "SET", outcome, ctx.defender)

	return ctx

func _resolve_attack(ctx:RallyState) -> RallyState:
	ctx.next_phase = Enums.Phase.Block
	var attacker: AthleteStats = ctx.chosen_set_option.get("attacker", null)
	if attacker == null:
		attacker = ctx.defender.teamStrategy.choose_attacker(ctx.defender_match_data, rng)
	_log_phase(ctx, "attack", "Executing spike.", ctx.defender, attacker)
	var attempt := AttackAttempt.new(attacker, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_record_ball_touch(ctx, outcome, "attack", ctx.defender, ctx.attacker)
	_log_action(ctx, "SPIKE", outcome, ctx.defender)

	return ctx

func _resolve_block(ctx:RallyState) -> RallyState:
	var blocker = ctx.chosen_blocker
	if blocker == null:
		blocker = SetPlayAnalysis.choose_reacting_blocker(ctx.defensive_positioning_plan, ctx.chosen_set_option)
	if blocker == null:
		blocker = ctx.attacker.teamStrategy.choose_blocker(ctx.attacker_match_data, rng)
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
	_reset_sideout_assessment(ctx)
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
	PlayerMovementPlanner.advance_phase(ctx, phase, source_team, target_team, outcome, ctx.ball_time)
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
	if outcome.metadata.has("projected_velocity"):
		return _projected_ball_snapshot(ctx, outcome, phase, source_team)

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
		"result": str(outcome.metadata.get("result", ""))
	}

func _projected_ball_snapshot(ctx: RallyState, outcome: AttemptOutcome, phase: String, source_team: TeamData) -> Dictionary:
	var position: Vector3 = ctx.ball_position
	var velocity: Vector3 = _vector3_from_metadata(outcome.metadata.get("projected_velocity", {}), Vector3.ZERO)
	var target_position: Vector3 = _vector3_from_metadata(outcome.metadata.get("projected_target_position", {}), position)
	var topspin: float = float(outcome.metadata.get("projected_topspin", _phase_topspin(phase, outcome)))

	return {
		"touch_index": ctx.touch_count,
		"phase": phase,
		"actor_name": _athlete_name(outcome.actor),
		"team_name": source_team.teamName if source_team != null else "",
		"position": target_position,
		"velocity": velocity,
		"topspin": topspin,
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
		source_context = source_match_data.build_phase_context(
			phase,
			source_side,
			outcome.actor,
			true,
			ctx.player_tracking_states,
			ctx.ball_time
		)
	if target_match_data != null:
		target_context = target_match_data.build_phase_context(
			phase,
			target_side,
			outcome.actor,
			false,
			ctx.player_tracking_states,
			ctx.ball_time
		)

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

func _assess_set_phase(ctx: RallyState, provided_setter: AthleteStats = null) -> void:
	if ctx == null or ctx.defender == null or ctx.defender_match_data == null:
		return

	var setter: AthleteStats = provided_setter
	if setter == null:
		setter = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	if setter == null:
		return

	var side_sign := _team_side_sign(ctx, ctx.defender)
	var set_origin := ctx.last_pass_target
	if set_origin == Vector3.ZERO:
		set_origin = Vector3(side_sign * 0.5, max(float(setter.jumpSetHeight), 2.4), 0.0)

	ctx.set_options = SetPlayAnalysis.evaluate_attacking_options(
		set_origin,
		side_sign,
		ctx.defender_match_data,
		setter,
		ctx.defender.teamStrategy
	)
	ctx.set_options = _refine_set_options_for_pass(ctx.set_options, ctx.last_pass_band, ctx.last_pass_quality)
	ctx.chosen_set_option = SetPlayAnalysis.choose_attacking_option(ctx.set_options, ctx.defender.teamStrategy, rng)
	ctx.defensive_set_read = SetPlayAnalysis.build_defensive_read(
		ctx.set_options,
		ctx.defender.teamStrategy,
		ctx.attacker.teamStrategy if ctx.attacker != null else null,
		rng
	)
	ctx.defensive_positioning_plan = SetPlayAnalysis.build_defensive_positioning_plan(
		_team_side_sign(ctx, ctx.attacker),
		ctx.attacker_match_data,
		ctx.attacker.teamStrategy if ctx.attacker != null else null,
		ctx.defensive_set_read
	)
	ctx.chosen_blocker = SetPlayAnalysis.choose_reacting_blocker(ctx.defensive_positioning_plan, ctx.chosen_set_option)

	_emit_step(ctx, _set_assessment_summary(ctx))
	_emit_step(ctx, _defensive_read_summary(ctx))

func _set_assessment_summary(ctx: RallyState) -> String:
	if ctx.chosen_set_option.is_empty():
		return "[Rally %d] SET READ | no viable set options found after %s pass" % [ctx.rally_number, ctx.last_pass_band]

	return "[Rally %d] SET READ | %s pass -> %s selected (difficulty=%.2f, time=%.2fs, lane=%s)" % [
		ctx.rally_number,
		ctx.last_pass_band,
		str(ctx.chosen_set_option.get("attacker_name", "")),
		float(ctx.chosen_set_option.get("set_difficulty", 0.0)),
		float(ctx.chosen_set_option.get("set_time", 0.0)),
		str(ctx.chosen_set_option.get("attack_lane", ""))
	]

func _defensive_read_summary(ctx: RallyState) -> String:
	var predicted_primary: Dictionary = ctx.defensive_set_read.get("predicted_primary", {})
	if predicted_primary.is_empty():
		return "[Rally %d] BLOCK PLAN | defence has no clear set read" % [ctx.rally_number]

	var blocker_name := ""
	if ctx.chosen_blocker != null:
		blocker_name = _athlete_name(ctx.chosen_blocker)
	var moving_defenders: int = 0
	for defender_plan in ctx.defensive_positioning_plan.get("backcourt", []):
		if bool(defender_plan.get("should_move", false)):
			moving_defenders += 1

	return "[Rally %d] BLOCK PLAN | read=%s scout=%.2f blocker=%s backcourt_shifts=%d" % [
		ctx.rally_number,
		str(predicted_primary.get("attacker_name", "")),
		float(ctx.defensive_set_read.get("scouting_confidence", 0.0)),
		blocker_name,
		moving_defenders
	]

func _reset_sideout_assessment(ctx: RallyState) -> void:
	ctx.last_pass_target = Vector3.ZERO
	ctx.last_pass_band = ""
	ctx.last_pass_quality = 0.0
	ctx.set_options.clear()
	ctx.chosen_set_option = {}
	ctx.defensive_set_read = {}
	ctx.defensive_positioning_plan = {}
	ctx.chosen_blocker = null
	ctx.available_blockers.clear()
	ctx.available_blocker_plans.clear()

func _refine_set_options_for_pass(options: Array[Dictionary], pass_band: String, pass_quality: float) -> Array[Dictionary]:
	if options.is_empty():
		return options

	var difficulty_limit: float = 1.0
	var back_row_penalty: float = 1.0
	match pass_band:
		"perfect":
			difficulty_limit = 1.0
		"good":
			difficulty_limit = 0.82
			back_row_penalty = 0.92
		"poor":
			difficulty_limit = 0.62
			back_row_penalty = 0.62
		_:
			difficulty_limit = 0.48
			back_row_penalty = 0.5

	var refined: Array[Dictionary] = []
	for option_variant in options:
		var option: Dictionary = option_variant.duplicate(true)
		var difficulty: float = float(option.get("set_difficulty", 1.0))
		var is_back_row: bool = str(option.get("court_bucket", "")) == "back"
		if difficulty > difficulty_limit and refined.size() >= 2:
			continue
		var availability: float = clamp(1.1 - difficulty + pass_quality * 0.55, 0.12, 1.35)
		if is_back_row:
			availability *= back_row_penalty
		option["availability_weight"] = availability
		option["tendency_weight"] = max(float(option.get("tendency_weight", 1.0)) * availability, 0.01)
		refined.append(option)

	if refined.is_empty():
		var fallback: Array[Dictionary] = options.duplicate(true)
		fallback.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("set_difficulty", 1.0)) < float(b.get("set_difficulty", 1.0))
		)
		return fallback.slice(0, min(2, fallback.size()))

	return refined

func _vector3_from_metadata(serialized: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if typeof(serialized) != TYPE_DICTIONARY:
		return fallback
	return Vector3(
		float(serialized.get("x", fallback.x)),
		float(serialized.get("y", fallback.y)),
		float(serialized.get("z", fallback.z))
	)

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



func _choose_receiving_strategy(ctx: RallyState) -> void:
	if ctx.receiving_team == null or ctx.receiving_team.teamStrategy == null:
		return
	_emit_step(ctx, "To do: have the receiving team decide on a serve reception layout")

func _choose_serving_strategy(ctx: RallyState) -> void:
	if ctx.serving_team == null or ctx.serving_team.teamStrategy == null:
		return


	if ctx.server == null and ctx.serving_team_match_data != null:
		ctx.server = ctx.serving_team_match_data.get_server()
	if ctx.server == null:
		ctx.server = ctx.serving_team.get_server()
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
