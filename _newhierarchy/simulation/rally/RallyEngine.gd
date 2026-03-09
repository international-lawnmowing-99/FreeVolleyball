extends RefCounted

class_name RallyEngine

var rng:RandomNumberGenerator

func _init(_rng) -> void:
	rng = _rng

func Resolve(ctx: RallyState) -> RallyState:
	var current_result = _resolve_serve(ctx)

	while not current_result.is_terminal:
		current_result = _resolve_pass(current_result)
		if current_result.is_terminal: break

		current_result = _resolve_set(current_result)
		if current_result.is_terminal: break

		current_result = _resolve_attack(current_result)
		if current_result.is_terminal: break

		current_result = _resolve_block(current_result)
		if current_result.is_terminal: break

		current_result = _resolve_defence_phase(current_result)
		if current_result.is_terminal: break

	_log_rally_end(current_result)
	return current_result

func _resolve_serve(ctx: RallyState) -> RallyState:
	var server: AthleteStats = ctx.server
	if server == null and ctx.serving_team_match_data != null:
		server = ctx.serving_team_match_data.choose_server()
	if server == null:
		server = ctx.serving_team.choose_server()
	var attempt := ServeAttempt.new(server, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_log_action(ctx, "SERVE", outcome, ctx.serving_team)

	return ctx

func _resolve_pass(ctx: RallyState) -> RallyState:
	var passer = ctx.defender.teamStrategy.choose_passer(ctx.defender_match_data, rng)
	var attempt := PassAttempt.new(passer, ctx, rng)

	var outcome := attempt.resolve()

	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_log_action(ctx, "RECEIVE", outcome, ctx.defender)

	return ctx

func _resolve_set(ctx:RallyState) -> RallyState:
	var setter = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	var attempt := SetAttempt.new(setter, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_log_action(ctx, "SET", outcome, ctx.defender)

	return ctx

func _resolve_attack(ctx:RallyState) -> RallyState:
	var attacker = ctx.defender.teamStrategy.choose_attacker(ctx.defender_match_data, rng)
	var attempt := AttackAttempt.new(attacker, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
	_log_action(ctx, "SPIKE", outcome, ctx.defender)

	return ctx

func _resolve_block(ctx:RallyState) -> RallyState:
	var blocker = ctx.attacker.teamStrategy.choose_blocker(ctx.attacker_match_data, rng)
	var attempt := BlockAttempt.new(blocker, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)
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
	print(
		"[Rally %d] %s | %s: %s (%s)"
		% [ctx.rally_number, team.teamName, athlete_name, action, result]
	)

func _log_rally_end(ctx: RallyState) -> void:
	print("[Rally %d] RALLY END: %s wins point" % [ctx.rally_number, ctx.point_winner.teamName])

func _athlete_name(athlete: AthleteStats) -> String:
	if athlete == null:
		return "Unknown Athlete"

	return "%s %s" % [athlete.firstName, athlete.lastName]
