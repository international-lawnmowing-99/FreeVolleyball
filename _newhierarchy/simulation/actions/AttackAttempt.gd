extends Attempt
class_name AttackAttempt

func resolve() -> AttackOutcome:
	var outcome := AttackOutcome.new()
	var in_bounds_chance = clamp(actor.spike / 100.0, 0.25, 0.98)
	var roll := rng.randf()

	outcome.actor = actor
	outcome.success = roll < in_bounds_chance
	outcome.metadata["roll"] = roll
	outcome.metadata["action"] = "spike"

	if outcome.success:
		outcome.terminal = false
		outcome.metadata["result"] = "attack_in_play"
	else:
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "attack_error"

	return outcome
