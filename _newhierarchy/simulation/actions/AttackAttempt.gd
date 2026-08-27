extends Attempt
class_name AttackAttempt

func resolve() -> AttackOutcome:
	var outcome := AttackOutcome.new()
	var chosen_option: Dictionary = ctx.chosen_set_option
	var set_difficulty: float = float(chosen_option.get("set_difficulty", 0.45))
	var in_bounds_chance = clamp(actor.spike / 100.0 - set_difficulty * 0.18, 0.18, 0.98)
	var roll := rng.randf()

	outcome.actor = actor
	outcome.success = roll < in_bounds_chance
	outcome.metadata["roll"] = roll
	outcome.metadata["action"] = "spike"
	outcome.metadata["set_difficulty"] = set_difficulty
	outcome.metadata["attack_lane"] = str(chosen_option.get("attack_lane", ""))

	if outcome.success:
		outcome.terminal = false
		#outcome.metadata["result"] = "attack_in_play"
	else:
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		#outcome.metadata["result"] = "attack_error"

	return outcome
