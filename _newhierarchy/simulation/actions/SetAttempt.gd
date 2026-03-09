extends Attempt
class_name SetAttempt

func resolve() -> SetOutcome:
	var outcome := SetOutcome.new()
	var success_chance = clamp(actor.set / 100.0, 0.20, 0.97)
	var roll := rng.randf()

	outcome.actor = actor
	outcome.success = roll < success_chance
	outcome.metadata["roll"] = roll
	outcome.metadata["action"] = "set"

	if outcome.success:
		outcome.terminal = false
		outcome.metadata["result"] = "attackable_ball"
	else:
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "setting_error"

	return outcome
