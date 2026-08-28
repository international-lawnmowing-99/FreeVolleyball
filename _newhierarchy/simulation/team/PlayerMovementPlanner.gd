class_name PlayerMovementPlanner
extends RefCounted

const Enums = preload("res://Scripts/World/Enums.gd")

const GRAVITY: float = 9.8
const COURT_HALF_LENGTH: float = 4.5
const SERVICE_LINE_BUFFER: float = 0.12
const NET_BUFFER: float = 0.1

static func initialize_rally_tracking(ctx: RallyState) -> void:
	ctx.movement_time = 0.0
	ctx.player_tracking_states = {}
	_initialize_team_tracking(ctx, ctx.serving_team_match_data, -1.0, true)
	_initialize_team_tracking(ctx, ctx.receiving_team_match_data, 1.0, false)
	ctx.initial_player_tracking_states = _duplicate_tracking_snapshot(ctx.player_tracking_states)

static func advance_phase(
	ctx: RallyState,
	phase: String,
	source_team: TeamData,
	target_team: TeamData,
	outcome: AttemptOutcome,
	end_time: float
) -> void:
	if ctx.player_tracking_states.is_empty():
		initialize_rally_tracking(ctx)

	var start_time: float = ctx.movement_time
	_plan_team_phase(ctx, phase, source_team, _match_data_for(ctx, source_team), _team_side_sign(ctx, source_team), outcome, start_time, end_time, true)
	_plan_team_phase(ctx, phase, target_team, _match_data_for(ctx, target_team), _team_side_sign(ctx, target_team), outcome, start_time, end_time, false)
	ctx.movement_time = end_time

static func _initialize_team_tracking(ctx: RallyState, team_match_data: TeamMatchData, team_side: float, is_serving_team: bool) -> void:
	if team_match_data == null:
		return

	for athlete in team_match_data.court_players:
		var key: String = _tracking_key(team_match_data.team, team_match_data.player_key_for_athlete(athlete))
		var start_position: Vector3 = team_match_data.get_phase_position_for_player(
			athlete,
			"serve" if is_serving_team else "receive",
			team_side,
			athlete if is_serving_team and athlete == team_match_data.get_server() else null,
			is_serving_team and athlete == team_match_data.get_server()
		)

		var state := {
			"team_name": team_match_data.team.teamName,
			"team_side": team_side,
			"player_key": team_match_data.player_key_for_athlete(athlete),
			"player_name": "%s %s" % [athlete.firstName, athlete.lastName],
			"position": start_position,
			"goal_position": start_position,
			"start_position": start_position,
			"phase": "serve_setup" if is_serving_team else "receive_setup",
			"movement_state": "hold_shape",
			"movement_intent": "pre_serve_shape" if is_serving_team else "serve_receive_shape",
			"plan_type": "ground",
			"plan_start_time": 0.0,
			"expected_arrival_time": 0.0,
			"movement_complete": true,
			"time_remaining": 0.0,
			"distance_to_goal": 0.0,
			"is_airborne": false,
			"substeps": []
		}

		if is_serving_team and athlete == team_match_data.get_server():
			_apply_serve_setup_state(state, athlete, team_side, ctx)
		ctx.player_tracking_states[key] = state

static func _plan_team_phase(
	ctx: RallyState,
	phase: String,
	team: TeamData,
	team_match_data: TeamMatchData,
	team_side: float,
	outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if team == null or team_match_data == null:
		return

	for athlete in team_match_data.court_players:
		var state: Dictionary = _ensure_tracking_state(ctx, team_match_data, athlete, team_side)
		match phase:
			"serve":
				_plan_serve_phase(ctx, team_match_data, athlete, state, team_side, outcome, start_time, end_time, is_source_team)
			"receive":
				_plan_receive_phase(ctx, team_match_data, athlete, state, team_side, outcome, start_time, end_time, is_source_team)
			"set":
				_plan_set_phase(ctx, team_match_data, athlete, state, team_side, outcome, start_time, end_time, is_source_team)
			"attack":
				_plan_attack_phase(ctx, team_match_data, athlete, state, team_side, outcome, start_time, end_time, is_source_team)
			"block":
				_plan_block_phase(ctx, team_match_data, athlete, state, team_side, outcome, start_time, end_time, is_source_team)
			_:
				var target_position: Vector3 = team_match_data.get_phase_position_for_player(athlete, "receive", team_side)
				_apply_ground_plan(state, athlete, target_position, phase, "readjust", "rally_balance", start_time, end_time)

static func _plan_serve_phase(
	ctx: RallyState,
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	state: Dictionary,
	team_side: float,
	_outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if is_source_team and athlete == ctx.server:
		var serve_plan: Dictionary = _build_serve_motion_plan(ctx, athlete, team_side)
		_apply_jump_recovery_plan(
			state,
			athlete,
			serve_plan["start_position"],
			serve_plan["takeoff_position"],
			serve_plan["contact_position"],
			serve_plan["landing_position"],
			serve_plan["recovery_position"],
			serve_plan["jump_height"],
			"serve",
			"serve_sequence",
			"serve_and_recover",
			start_time,
			end_time
		)
		return

	if is_source_team:
		var defensive_home: Vector3 = _defensive_target(team_match_data, athlete, team_side)
		_apply_ground_plan(state, athlete, defensive_home, "serve", "serve_cover", "transition_to_defence", start_time, end_time)
		return

	var target_receiver_name: String = str(ctx.serve_target_receiver_name)
	var player_name := "%s %s" % [athlete.firstName, athlete.lastName]
	var is_target_receiver: bool = target_receiver_name != "" and target_receiver_name == player_name
	var receive_target: Vector3
	var movement_state := "receive_shape"
	var movement_intent := "serve_receive_positioning"
	if athlete.role == Enums.Role.Setter:
		receive_target = _setter_window_target(team_match_data, athlete, team_side)
		movement_state = "setter_release"
		movement_intent = "beat_ball_to_window"
	elif is_target_receiver:
		receive_target = Vector3(team_side * abs(ctx.serve_target.x), 0.0, ctx.serve_target.z)
		movement_state = "track_serve_target"
		movement_intent = "receive_first_ball"
	else:
		receive_target = _receive_transition_target(team_match_data, athlete, team_side, Vector3.ZERO, {})
		movement_state = "transition_shape"
		movement_intent = "unfold_sideout_pattern"
	_apply_ground_plan(
		state,
		athlete,
		receive_target,
		"serve",
		movement_state,
		movement_intent,
		start_time,
		end_time
	)

static func _plan_receive_phase(
	ctx: RallyState,
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	state: Dictionary,
	team_side: float,
	outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if is_source_team and outcome.actor == athlete:
		var pass_target: Vector3 = _vector3_from_metadata(outcome.metadata.get("reception_target", {}), ctx.last_pass_target)
		var receive_contact: Vector3 = Vector3(pass_target.x, 0.0, pass_target.z)
		_apply_ground_plan(state, athlete, receive_contact, "receive", "first_contact", "pass_ball", start_time, end_time)
		return

	if is_source_team:
		var transition_target: Vector3 = _receive_transition_target(
			team_match_data,
			athlete,
			team_side,
			ctx.last_pass_target,
			ctx.chosen_set_option
		)
		var movement_state: String = "transition_to_set" if athlete.role == Enums.Role.Setter else "transition_to_attack"
		var movement_intent: String = "setter_window" if athlete.role == Enums.Role.Setter else "attack_timing"
		if athlete != ctx.chosen_set_option.get("attacker", null) and athlete.role != Enums.Role.Setter:
			movement_state = "coverage_balance"
			movement_intent = "preserve_transition_spacing"
		_apply_ground_plan(state, athlete, transition_target, "receive", movement_state, movement_intent, start_time, end_time)
		return

	var defensive_target: Vector3 = _defensive_target(team_match_data, athlete, team_side)
	_apply_ground_plan(state, athlete, defensive_target, "receive", "defensive_read", "read_sideout_shape", start_time, end_time)

static func _plan_set_phase(
	ctx: RallyState,
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	state: Dictionary,
	team_side: float,
	_outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if is_source_team:
		var chosen_attacker: AthleteStats = ctx.chosen_set_option.get("attacker", null)
		var contact_position: Vector3 = ctx.chosen_set_option.get("contact_position", Vector3.ZERO)
		if athlete == chosen_attacker and contact_position != Vector3.ZERO:
			var runup_start: Vector3 = _attack_runup_start(contact_position, team_side, athlete, team_match_data)
			_apply_ground_plan(state, athlete, runup_start, "set", "approach_preparation", "attack_runup_start", start_time, end_time)
			return

		if athlete.role == Enums.Role.Setter:
			var set_origin: Vector3 = ctx.last_pass_target
			if set_origin == Vector3.ZERO:
				set_origin = team_match_data.get_phase_position_for_player(athlete, "set", team_side, athlete, true)
			_apply_ground_plan(state, athlete, Vector3(set_origin.x, 0.0, set_origin.z), "set", "setting_window", "arrive_for_set", start_time, end_time)
			return

		var transition_target: Vector3 = _attack_cover_target(team_match_data, athlete, team_side, ctx.chosen_set_option)
		_apply_ground_plan(state, athlete, transition_target, "set", "off_ball_adjust", "cover_for_attack", start_time, end_time)
		return

	var blocker_target: Vector3 = _block_plan_target(ctx, athlete, team_match_data, team_side)
	var state_name: String = "block_read" if athlete.rotationPosition >= 2 and athlete.rotationPosition <= 4 else "backcourt_shift"
	var intent: String = "close_attack_lane" if athlete.rotationPosition >= 2 and athlete.rotationPosition <= 4 else "dig_read"
	_apply_ground_plan(state, athlete, blocker_target, "set", state_name, intent, start_time, end_time)

static func _plan_attack_phase(
	ctx: RallyState,
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	state: Dictionary,
	team_side: float,
	_outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if is_source_team and athlete == ctx.chosen_set_option.get("attacker", null):
		var contact_position: Vector3 = ctx.chosen_set_option.get("contact_position", Vector3.ZERO)
		var geometry: Dictionary = _build_attack_geometry(state["position"], contact_position, team_side, athlete, team_match_data)
		var recovery_position: Vector3 = team_match_data.get_phase_position_for_player(athlete, "receive", team_side)
		_apply_jump_recovery_plan(
			state,
			athlete,
			geometry["start_position"],
			geometry["takeoff_position"],
			geometry["contact_position"],
			geometry["landing_position"],
			recovery_position,
			geometry["jump_height"],
			"attack",
			"attack_runup_jump",
			"spike_and_cover",
			start_time,
			end_time
		)
		return

	if is_source_team:
		var cover_target: Vector3 = _attack_cover_target(team_match_data, athlete, team_side, ctx.chosen_set_option)
		_apply_ground_plan(state, athlete, cover_target, "attack", "attack_cover", "cover_recycled_ball", start_time, end_time)
		return

	var blocker_target: Vector3 = _block_plan_target(ctx, athlete, team_match_data, team_side)
	var state_name: String = "block_closing" if athlete.rotationPosition >= 2 and athlete.rotationPosition <= 4 else "backcourt_read"
	_apply_ground_plan(state, athlete, blocker_target, "attack", state_name, "react_to_attack_lane", start_time, end_time)

static func _plan_block_phase(
	ctx: RallyState,
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	state: Dictionary,
	team_side: float,
	_outcome: AttemptOutcome,
	start_time: float,
	end_time: float,
	is_source_team: bool
) -> void:
	if is_source_team and athlete == ctx.chosen_blocker:
		var jump_anchor: Vector3 = _block_plan_target(ctx, athlete, team_match_data, team_side)
		var contact_position: Vector3 = ctx.chosen_set_option.get("contact_position", Vector3(jump_anchor.x, max(athlete.blockHeight, 2.4), jump_anchor.z))
		var landing_position: Vector3 = jump_anchor
		var recovery_position: Vector3 = jump_anchor
		_apply_jump_recovery_plan(
			state,
			athlete,
			state["position"],
			jump_anchor,
			Vector3(contact_position.x, athlete.verticalJump, contact_position.z),
			landing_position,
			recovery_position,
			max(athlete.verticalJump, 0.2),
			"block",
			"block_jump",
			"seal_net",
			start_time,
			end_time
		)
		return

	if is_source_team:
		var block_target: Vector3 = _block_plan_target(ctx, athlete, team_match_data, team_side)
		_apply_ground_plan(state, athlete, block_target, "block", "block_support", "cover_block_line", start_time, end_time)
		return

	var emergency_target: Vector3 = team_match_data.get_phase_position_for_player(athlete, "receive", team_side)
	_apply_ground_plan(state, athlete, emergency_target, "block", "defence_after_block", "prepare_for_recycle", start_time, end_time)

static func _apply_serve_setup_state(state: Dictionary, athlete: AthleteStats, team_side: float, ctx: RallyState) -> void:
	var serve_plan: Dictionary = _build_serve_motion_plan(ctx, athlete, team_side)
	state["position"] = serve_plan["start_position"]
	state["goal_position"] = serve_plan["takeoff_position"]
	state["start_position"] = serve_plan["start_position"]
	state["movement_state"] = "pre_serve_walkup"
	state["movement_intent"] = "avoid_foot_fault"
	state["substeps"] = [
		{
			"label": "serve_start",
			"timestamp": 0.0,
			"target_position": _vector3_to_dict(serve_plan["start_position"])
		},
		{
			"label": "serve_takeoff",
			"timestamp": 0.0,
			"target_position": _vector3_to_dict(serve_plan["takeoff_position"])
		}
	]

static func _apply_ground_plan(
	state: Dictionary,
	athlete: AthleteStats,
	target_position: Vector3,
	phase: String,
	movement_state: String,
	movement_intent: String,
	start_time: float,
	end_time: float
) -> void:
	var start_position: Vector3 = state.get("position", target_position)
	var speed: float = max(float(athlete.speed), 0.5)
	var distance: float = start_position.distance_to(target_position)
	var travel_time: float = distance / speed if distance > 0.001 else 0.0
	var elapsed: float = max(end_time - start_time, 0.0)
	var travelled: float = min(distance, speed * elapsed)
	var end_position: Vector3 = start_position.move_toward(target_position, travelled)
	var expected_arrival_time: float = start_time + travel_time

	state["start_position"] = start_position
	state["position"] = end_position
	state["goal_position"] = target_position
	state["phase"] = phase
	state["movement_state"] = movement_state
	state["movement_intent"] = movement_intent
	state["plan_type"] = "ground"
	state["plan_start_time"] = start_time
	state["expected_arrival_time"] = expected_arrival_time
	state["movement_complete"] = distance <= 0.001 or end_time >= expected_arrival_time
	state["time_remaining"] = max(expected_arrival_time - end_time, 0.0)
	state["distance_to_goal"] = end_position.distance_to(target_position)
	state["is_airborne"] = false
	state["substeps"] = [
		{
			"label": movement_state,
			"timestamp": start_time,
			"target_position": _vector3_to_dict(target_position)
		},
		{
			"label": "arrival",
			"timestamp": expected_arrival_time,
			"target_position": _vector3_to_dict(target_position)
		}
	]

static func _apply_jump_recovery_plan(
	state: Dictionary,
	athlete: AthleteStats,
	start_position: Vector3,
	takeoff_position: Vector3,
	contact_position: Vector3,
	landing_position: Vector3,
	recovery_position: Vector3,
	jump_height: float,
	phase: String,
	movement_state: String,
	movement_intent: String,
	start_time: float,
	end_time: float
) -> void:
	var speed: float = max(float(athlete.speed), 0.5)
	var runup_time: float = start_position.distance_to(takeoff_position) / speed
	var jump_peak_time: float = sqrt(max(2.0 * GRAVITY * max(jump_height, 0.01), 0.0)) / GRAVITY
	var takeoff_time: float = start_time + runup_time
	var contact_time: float = takeoff_time + jump_peak_time
	var landing_time: float = contact_time + jump_peak_time
	var recovery_time: float = landing_position.distance_to(recovery_position) / speed
	var recovery_arrival_time: float = landing_time + recovery_time
	var current_time: float = end_time
	var current_position: Vector3 = start_position
	var active_state: String = movement_state
	var is_airborne: bool = false

	if current_time <= takeoff_time:
		current_position = start_position.move_toward(takeoff_position, speed * max(current_time - start_time, 0.0))
		active_state = "runup"
	elif current_time <= contact_time:
		var ratio_up: float = clamp((current_time - takeoff_time) / max(jump_peak_time, 0.01), 0.0, 1.0)
		current_position = takeoff_position.lerp(contact_position, ratio_up)
		current_position.y = jump_height * sin(ratio_up * PI * 0.5)
		active_state = "jump_rise"
		is_airborne = true
	elif current_time <= landing_time:
		var ratio_down: float = clamp((current_time - contact_time) / max(jump_peak_time, 0.01), 0.0, 1.0)
		current_position = contact_position.lerp(landing_position, ratio_down)
		current_position.y = jump_height * cos(ratio_down * PI * 0.5)
		active_state = "jump_descent"
		is_airborne = true
	else:
		current_position = landing_position.move_toward(recovery_position, speed * max(current_time - landing_time, 0.0))
		active_state = "recover"

	state["start_position"] = start_position
	state["position"] = current_position
	state["goal_position"] = recovery_position
	state["phase"] = phase
	state["movement_state"] = active_state
	state["movement_intent"] = movement_intent
	state["plan_type"] = "runup_jump_recover"
	state["plan_start_time"] = start_time
	state["expected_arrival_time"] = recovery_arrival_time
	state["movement_complete"] = current_time >= recovery_arrival_time
	state["time_remaining"] = max(recovery_arrival_time - current_time, 0.0)
	state["distance_to_goal"] = current_position.distance_to(recovery_position)
	state["is_airborne"] = is_airborne
	state["takeoff_time"] = takeoff_time
	state["contact_time"] = contact_time
	state["landing_time"] = landing_time
	state["jump_height"] = jump_height
	state["substeps"] = [
		{
			"label": "runup_start",
			"timestamp": start_time,
			"target_position": _vector3_to_dict(start_position)
		},
		{
			"label": "takeoff",
			"timestamp": takeoff_time,
			"target_position": _vector3_to_dict(takeoff_position)
		},
		{
			"label": "contact",
			"timestamp": contact_time,
			"target_position": _vector3_to_dict(contact_position)
		},
		{
			"label": "landing",
			"timestamp": landing_time,
			"target_position": _vector3_to_dict(landing_position)
		},
		{
			"label": "recovery",
			"timestamp": recovery_arrival_time,
			"target_position": _vector3_to_dict(recovery_position)
		}
	]

static func _build_serve_motion_plan(ctx: RallyState, athlete: AthleteStats, team_side: float) -> Dictionary:
	var serve_target: Vector3 = ctx.serve_target if ctx.serve_target != Vector3.ZERO else Vector3(-team_side * (COURT_HALF_LENGTH - 1.6), 0.0, 0.0)
	var serve_type: String = ctx.serve_type
	var runup_length: float = 0.0
	var horizontal_jump: float = 0.0
	match serve_type:
		"jump":
			runup_length = 2.75
			horizontal_jump = max(float(athlete.verticalJump) * 0.5, 0.55)
		"underarm":
			runup_length = 0.0
			horizontal_jump = 0.0
		_:
			runup_length = 1.25
			horizontal_jump = max(float(athlete.verticalJump) * 0.35, 0.2)

	var contact_x: float = team_side * (COURT_HALF_LENGTH - SERVICE_LINE_BUFFER)
	var contact_z: float = clamp(serve_target.z * 0.25, -3.5, 3.5)
	var contact_position := Vector3(contact_x, 0.0, contact_z)
	var approach_direction := (Vector3(-team_side * COURT_HALF_LENGTH, 0.0, serve_target.z) - contact_position).normalized()
	if approach_direction.length() <= 0.001:
		approach_direction = Vector3(-team_side, 0.0, 0.0)
	var takeoff_position: Vector3 = contact_position - approach_direction * horizontal_jump * 0.5
	var landing_position: Vector3 = contact_position + approach_direction * horizontal_jump * 0.5
	var start_position: Vector3 = takeoff_position - approach_direction * runup_length
	var service_line_limit: float = team_side * COURT_HALF_LENGTH
	if team_side < 0.0:
		start_position.x = min(start_position.x, service_line_limit - 0.15)
		takeoff_position.x = min(takeoff_position.x, service_line_limit - 0.02)
	else:
		start_position.x = max(start_position.x, service_line_limit + 0.15)
		takeoff_position.x = max(takeoff_position.x, service_line_limit + 0.02)
	var recovery_position: Vector3 = _match_data_for(ctx, ctx.serving_team).get_phase_position_for_player(athlete, "block", team_side)

	return {
		"start_position": start_position,
		"takeoff_position": takeoff_position,
		"contact_position": contact_position,
		"landing_position": landing_position,
		"recovery_position": recovery_position,
		"jump_height": max(float(athlete.verticalJump), 0.0)
	}

static func _build_attack_geometry(current_position: Vector3, contact_position: Vector3, team_side: float, athlete: AthleteStats, team_match_data: TeamMatchData = null) -> Dictionary:
	var runup_start: Vector3 = _attack_runup_start(contact_position, team_side, athlete, team_match_data)
	var direction: Vector3 = (contact_position - runup_start)
	direction.y = 0.0
	if direction.length() <= 0.001:
		direction = Vector3(-team_side, 0.0, 0.0)
	direction = direction.normalized()
	var half_jump: float = max(float(athlete.verticalJump) * 0.5, 0.18)
	var takeoff_position: Vector3 = contact_position - direction * half_jump
	var landing_position: Vector3 = contact_position + direction * half_jump
	if team_side < 0.0:
		landing_position.x = min(landing_position.x, -NET_BUFFER)
	else:
		landing_position.x = max(landing_position.x, NET_BUFFER)
	var takeoff_adjusted: Vector3 = contact_position - (landing_position - contact_position)

	return {
		"start_position": current_position,
		"runup_start": runup_start,
		"takeoff_position": takeoff_adjusted,
		"contact_position": Vector3(contact_position.x, 0.0, contact_position.z),
		"landing_position": Vector3(landing_position.x, 0.0, landing_position.z),
		"jump_height": max(float(athlete.verticalJump), 0.2)
	}

static func _attack_runup_start(contact_position: Vector3, team_side: float, athlete: AthleteStats, team_match_data: TeamMatchData = null) -> Vector3:
	if contact_position == Vector3.ZERO:
		return Vector3(team_side * 3.2, 0.0, 0.0)
	if team_match_data != null and team_match_data.team != null and team_match_data.team.teamStrategy != null:
		var local_contact := Vector3(abs(contact_position.x), contact_position.y, contact_position.z)
		return _local_to_world(team_match_data.team.teamStrategy.attack_runup_start_local(local_contact, athlete), team_side)
	return Vector3(
		contact_position.x + team_side * (3.0 + float(athlete.verticalJump) * 0.5),
		0.0,
		contact_position.z
	)

static func _transition_target(team_match_data: TeamMatchData, athlete: AthleteStats, team_side: float, pass_target: Vector3) -> Vector3:
	if athlete.role == Enums.Role.Setter:
		if pass_target != Vector3.ZERO:
			return Vector3(pass_target.x, 0.0, pass_target.z)
		return team_match_data.get_phase_position_for_player(athlete, "set", team_side, athlete, true)
	if athlete.role == Enums.Role.Libero:
		return team_match_data.get_phase_position_for_player(athlete, "receive", team_side)
	var transition_base: Vector3 = team_match_data.get_phase_position_for_player(athlete, "attack", team_side)
	var x_sign: float = -1.0 if transition_base.x < 0.0 else 1.0
	return Vector3(max(abs(transition_base.x), 0.8) * x_sign, 0.0, transition_base.z)

static func _receive_transition_target(
	team_match_data: TeamMatchData,
	athlete: AthleteStats,
	team_side: float,
	pass_target: Vector3,
	chosen_option: Dictionary
) -> Vector3:
	if team_match_data == null or team_match_data.team == null or team_match_data.team.teamStrategy == null:
		return _transition_target(team_match_data, athlete, team_side, pass_target)
	var local_target: Vector3 = team_match_data.team.teamStrategy.receive_transition_local(
		team_match_data,
		athlete,
		pass_target,
		chosen_option
	)
	return _local_to_world(local_target, team_side)

static func _attack_cover_target(team_match_data: TeamMatchData, athlete: AthleteStats, team_side: float, chosen_option: Dictionary) -> Vector3:
	if team_match_data == null:
		return Vector3(team_side * 3.0, 0.0, 0.0)
	if team_match_data.team == null or team_match_data.team.teamStrategy == null:
		return team_match_data.get_phase_position_for_player(athlete, "receive", team_side)
	var local_target: Vector3 = team_match_data.team.teamStrategy.attack_cover_local(athlete, chosen_option)
	return _local_to_world(local_target, team_side)

static func _setter_window_target(team_match_data: TeamMatchData, athlete: AthleteStats, team_side: float) -> Vector3:
	if team_match_data != null and team_match_data.team != null and team_match_data.team.teamStrategy != null:
		return team_match_data.team.teamStrategy.reception_target_for_side(team_side)
	return team_match_data.get_phase_position_for_player(athlete, "set", team_side, athlete, true)

static func _defensive_target(team_match_data: TeamMatchData, athlete: AthleteStats, team_side: float) -> Vector3:
	if team_match_data == null or team_match_data.team == null or team_match_data.team.teamStrategy == null:
		return team_match_data.get_phase_position_for_player(athlete, "block", team_side)
	var local_target: Vector3 = team_match_data.team.teamStrategy.defensive_plan_local_target(athlete, {})
	return _local_to_world(local_target, team_side)

static func _block_plan_target(ctx: RallyState, athlete: AthleteStats, team_match_data: TeamMatchData, team_side: float) -> Vector3:
	if team_match_data != null and team_match_data.team != null and team_match_data.team.teamStrategy != null:
		var local_target: Vector3 = team_match_data.team.teamStrategy.defensive_plan_local_target(athlete, ctx.defensive_positioning_plan)
		return _local_to_world(local_target, team_side)
	for blocker_plan in ctx.defensive_positioning_plan.get("blockers", []):
		if blocker_plan.get("athlete") == athlete:
			return blocker_plan.get("start_position", team_match_data.get_phase_position_for_player(athlete, "block", team_side))
	for backcourt_plan in ctx.defensive_positioning_plan.get("backcourt", []):
		if backcourt_plan.get("athlete") == athlete:
			return backcourt_plan.get("target_position", team_match_data.get_phase_position_for_player(athlete, "block", team_side))
	return team_match_data.get_phase_position_for_player(athlete, "block", team_side)

static func _local_to_world(local_position: Vector3, team_side: float) -> Vector3:
	return Vector3(abs(local_position.x) * team_side, local_position.y, local_position.z)

static func _ensure_tracking_state(ctx: RallyState, team_match_data: TeamMatchData, athlete: AthleteStats, team_side: float) -> Dictionary:
	var key: String = _tracking_key(team_match_data.team, team_match_data.player_key_for_athlete(athlete))
	if not ctx.player_tracking_states.has(key):
		ctx.player_tracking_states[key] = {
			"team_name": team_match_data.team.teamName,
			"team_side": team_side,
			"player_key": team_match_data.player_key_for_athlete(athlete),
			"player_name": "%s %s" % [athlete.firstName, athlete.lastName],
			"position": team_match_data.get_phase_position_for_player(athlete, "receive", team_side),
			"goal_position": team_match_data.get_phase_position_for_player(athlete, "receive", team_side),
			"start_position": team_match_data.get_phase_position_for_player(athlete, "receive", team_side),
			"phase": "bootstrap",
			"movement_state": "hold_shape",
			"movement_intent": "bootstrap",
			"plan_type": "ground",
			"plan_start_time": ctx.movement_time,
			"expected_arrival_time": ctx.movement_time,
			"movement_complete": true,
			"time_remaining": 0.0,
			"distance_to_goal": 0.0,
			"is_airborne": false,
			"substeps": []
		}
	return ctx.player_tracking_states[key]

static func _duplicate_tracking_snapshot(states: Dictionary) -> Dictionary:
	var duplicate: Dictionary = {}
	for key in states.keys():
		duplicate[key] = states[key].duplicate(true)
	return duplicate

static func _tracking_key(team: TeamData, player_key: String) -> String:
	return "%s::%s" % [team.teamName if team != null else "UnknownTeam", player_key]

static func _vector3_to_dict(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}

static func _team_side_sign(ctx: RallyState, team: TeamData) -> float:
	if team == null:
		return 1.0
	if team == ctx.serving_team:
		return -1.0
	return 1.0

static func _match_data_for(ctx: RallyState, team: TeamData) -> TeamMatchData:
	if team == ctx.serving_team:
		return ctx.serving_team_match_data
	if team == ctx.receiving_team:
		return ctx.receiving_team_match_data
	if team == ctx.attacker:
		return ctx.attacker_match_data
	if team == ctx.defender:
		return ctx.defender_match_data
	return null

static func _vector3_from_metadata(serialized: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if typeof(serialized) != TYPE_DICTIONARY:
		return fallback
	return Vector3(
		float(serialized.get("x", fallback.x)),
		float(serialized.get("y", fallback.y)),
		float(serialized.get("z", fallback.z))
	)
