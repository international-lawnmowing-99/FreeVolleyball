extends Attempt
class_name BlockAttempt

func resolve() -> BlockOutcome:
	var outcome := BlockOutcome.new()
	var block_chance = clamp(actor.block / 100.0, 0.15, 0.90)
	var roll := rng.randf()

	outcome.actor = actor
	outcome.metadata["roll"] = roll
	outcome.metadata["action"] = "block"

	if roll < block_chance * 0.35:
		outcome.success = true
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "stuff_block"
	elif roll < block_chance:
		outcome.success = true
		outcome.terminal = false
		outcome.metadata["result"] = "soft_touch_continues"
	else:
		outcome.success = false
		outcome.terminal = true
		outcome.point_winner = ctx.attacker
		outcome.metadata["result"] = "attack_scores"

	return outcome
