extends Attempt
class_name ServeAttempt

func resolve() -> ServeOutcome:
	var outcome: ServeOutcome = ServeOutcome.new()

	outcome.actor = actor

	var error_threshold: float = float(clamp(1.0 - actor.serve / 100.0, 0.02, 0.45))
	var execution: float = float(clamp(actor.serve / 100.0 + rng.randf_range(-0.25, 0.25), 0.0, 1.0))
	var receive_difficulty: float = float(clamp(0.2 + execution * 0.75 + rng.randf_range(-0.08, 0.08), 0.05, 1.0))

	ctx.serve_execution = execution
	ctx.serve_receive_difficulty = receive_difficulty

	outcome.metadata["execution"] = execution
	outcome.metadata["receive_difficulty"] = receive_difficulty
	outcome.metadata["action"] = "serve"

	if execution < error_threshold:
		# Service error
		outcome.success = false
		outcome.service_error = true
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "service_error"

	else:
		# Ball in play
		outcome.success = true
		outcome.terminal = false
		outcome.metadata["result"] = "in_play"

	return outcome
