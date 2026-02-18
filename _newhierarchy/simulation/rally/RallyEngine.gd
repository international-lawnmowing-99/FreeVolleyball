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

		current_result = _resolve_defence_phase(current_result)
		if current_result.is_terminal: break

	return current_result

func _resolve_serve(ctx: RallyState) -> RallyState:
	var server = ctx.serving_team.choose_server()
	var attempt := ServeAttempt.new(server, ctx, rng)

	var outcome := attempt.resolve()
	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)

	return ctx

func _resolve_pass(ctx: RallyState) -> RallyState:
	var passer = ctx.defender.choose_passer()
	var attempt := PassAttempt.new(passer, ctx, rng)

	var outcome := attempt.resolve()

	_apply_outcome(ctx, outcome)
	ctx.event_log.add(outcome)

	return ctx

func _resolve_set(ctx:RallyState) -> RallyState:
	return ctx

func _resolve_attack(ctx:RallyState) -> RallyState:
	ctx.is_terminal = rng.randf() > 0.8
	if ctx.is_terminal:
		ctx.point_winner = ctx.attacker
	return ctx

func _resolve_defence_phase(ctx:RallyState) -> RallyState:
	var previous_attacker: TeamData = ctx.attacker
	ctx.attacker = ctx.defender
	ctx.defender = previous_attacker
	return ctx

func _apply_outcome(ctx: RallyState, outcome: AttemptOutcome) -> void:
	if outcome.terminal:
		ctx.is_terminal = true
		ctx.point_winner = outcome.point_winner
