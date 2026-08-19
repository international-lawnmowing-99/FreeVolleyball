class_name RallyReplayBuilder
extends RefCounted

const REPLAY_FRAME_STEP: float = 0.12
const DEFAULT_BALL_CONTACT_HEIGHT: float = 2.6

static func build(ctx: RallyState) -> Dictionary:
	var replay: Dictionary = ctx.event_log.serialize_for_replay()
	var keyframes: Array[Dictionary] = _build_keyframes(ctx, replay)

	replay["keyframes"] = keyframes
	replay["summary"] = {
		"rally_number": ctx.rally_number,
		"serving_team_name": ctx.serving_team.teamName if ctx.serving_team != null else "",
		"receiving_team_name": ctx.receiving_team.teamName if ctx.receiving_team != null else "",
		"point_winner_name": ctx.point_winner.teamName if ctx.point_winner != null else "",
		"keyframe_count": keyframes.size(),
		"touch_count": ctx.touch_count,
		"has_stub_data": true
	}
	return replay

static func _build_keyframes(ctx: RallyState, replay: Dictionary) -> Array[Dictionary]:
	var keyframes: Array[Dictionary] = []
	var serialized_events: Array = replay.get("events", [])
	var ball_touches: Array = replay.get("ball_touches", [])
	var context_snapshots: Array = replay.get("context_snapshots", [])

	keyframes.append(_build_setup_keyframe(ctx))

	var touch_count: int = min(ball_touches.size(), context_snapshots.size())
	for i in range(touch_count):
		var touch: Dictionary = ball_touches[i]
		var context: Dictionary = context_snapshots[i]
		var event: Dictionary = {}
		if i < serialized_events.size():
			event = serialized_events[i]
		keyframes.append(_build_touch_keyframe(i + 1, touch, context, event))

	if keyframes.size() == 1:
		keyframes.append(_build_terminal_stub_keyframe(ctx))

	return keyframes

static func _build_setup_keyframe(ctx: RallyState) -> Dictionary:
	var highlighted_server: AthleteStats = ctx.server
	if highlighted_server == null and ctx.serving_team_match_data != null:
		highlighted_server = ctx.serving_team_match_data.get_server()
	var serving_side: float = -1.0
	var receiving_side: float = 1.0
	var serving_context: Dictionary = {}
	var receiving_context: Dictionary = {}

	if ctx.serving_team_match_data != null:
		serving_context = ctx.serving_team_match_data.build_phase_context(
			"serve",
			serving_side,
			highlighted_server,
			true,
			ctx.initial_player_tracking_states,
			0.0
		)
	if ctx.receiving_team_match_data != null:
		receiving_context = ctx.receiving_team_match_data.build_phase_context(
			"receive",
			receiving_side,
			highlighted_server,
			false,
			ctx.initial_player_tracking_states,
			0.0
		)

	var ball_position := Vector3(serving_side * 4.9, DEFAULT_BALL_CONTACT_HEIGHT, 0.0)
	if highlighted_server != null and ctx.serving_team_match_data != null:
		var tracking_key := "%s::%s" % [
			ctx.serving_team.teamName if ctx.serving_team != null else "",
			ctx.serving_team_match_data.player_key_for_athlete(highlighted_server)
		]
		var server_tracking: Dictionary = ctx.initial_player_tracking_states.get(tracking_key, {})
		ball_position = server_tracking.get(
			"position",
			ctx.serving_team_match_data.get_phase_position_for_player(highlighted_server, "serve", serving_side, highlighted_server, true)
		)
		ball_position.y = DEFAULT_BALL_CONTACT_HEIGHT

	return {
		"frame_index": 0,
		"keyframe_index": 0,
		"timestamp": 0.0,
		"phase": "serve_setup",
		"is_keyframe": true,
		"source": "setup_stub",
		"ball": {
			"position": _vector3_to_dict(ball_position),
			"velocity": _vector3_to_dict(Vector3.ZERO),
			"topspin": 0.0
		},
		"teams": [serving_context, receiving_context],
		"focus": {
			"actor_name": _athlete_name(highlighted_server),
			"action": "serve_setup",
			"result": "pre_contact"
		},
		"stub_flags": [
			"pre_touch_ball_state",
			"pre_touch_player_animation"
		]
	}

static func _build_touch_keyframe(index: int, touch: Dictionary, context: Dictionary, event: Dictionary) -> Dictionary:
	var ball_state: Dictionary = context.get("ball_state", {})
	if ball_state.is_empty():
		ball_state = {
			"position": touch.get("position", _vector3_to_dict(Vector3.ZERO)),
			"velocity": touch.get("velocity", _vector3_to_dict(Vector3.ZERO)),
			"topspin": touch.get("topspin", 0.0)
		}

	return {
		"frame_index": index,
		"keyframe_index": index,
		"timestamp": float(touch.get("timestamp", context.get("timestamp", 0.0))),
		"phase": str(touch.get("phase", context.get("phase", ""))),
		"is_keyframe": true,
		"source": "simulation_touch",
		"ball": ball_state,
		"teams": context.get("teams", []),
		"focus": {
			"actor_name": str(event.get("actor_name", touch.get("actor_name", "Unknown Athlete"))),
			"action": str(event.get("action", touch.get("phase", ""))),
			"result": str(event.get("result", touch.get("result", "")))
		},
		"stub_flags": [
			"player_animation_assignment_stub"
		]
	}

static func _build_terminal_stub_keyframe(ctx: RallyState) -> Dictionary:
	return {
		"frame_index": 1,
		"keyframe_index": 1,
		"timestamp": REPLAY_FRAME_STEP,
		"phase": "terminal_stub",
		"is_keyframe": true,
		"source": "terminal_stub",
		"ball": {
			"position": _vector3_to_dict(ctx.ball_position),
			"velocity": _vector3_to_dict(ctx.ball_velocity),
			"topspin": ctx.ball_topspin
		},
		"teams": [],
		"focus": {
			"actor_name": "",
			"action": "point_end",
			"result": ctx.point_winner.teamName if ctx.point_winner != null else ""
		},
		"stub_flags": [
			"terminal_replay_stub"
		]
	}

static func _select_animation(previous_animation: Dictionary, target_animation: Dictionary, weight: float) -> Dictionary:
	if weight < 0.5 and not previous_animation.is_empty():
		return previous_animation.duplicate(true)
	if not target_animation.is_empty():
		return target_animation.duplicate(true)
	return previous_animation.duplicate(true)

static func _athlete_name(athlete: AthleteStats) -> String:
	if athlete == null:
		return "Unknown Athlete"
	return "%s %s" % [athlete.firstName, athlete.lastName]

static func _vector3_to_dict(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}

static func _lerp_vector3_dict(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	return {
		"x": lerpf(float(from.get("x", 0.0)), float(to.get("x", 0.0)), weight),
		"y": lerpf(float(from.get("y", 0.0)), float(to.get("y", 0.0)), weight),
		"z": lerpf(float(from.get("z", 0.0)), float(to.get("z", 0.0)), weight)
	}
