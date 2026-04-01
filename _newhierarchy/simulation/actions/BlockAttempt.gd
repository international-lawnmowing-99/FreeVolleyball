extends Attempt
class_name BlockAttempt

func resolve() -> BlockOutcome:
	var outcome := BlockOutcome.new()
	var actual_option: Dictionary = ctx.chosen_set_option
	var positioning_plan: Dictionary = ctx.defensive_positioning_plan
	var block_alignment: float = 1.0
	var primary_blocker: Dictionary = positioning_plan.get("primary_blocker", {})
	if not actual_option.is_empty() and not primary_blocker.is_empty():
		var target_position: Vector3 = actual_option.get("contact_position", Vector3.ZERO)
		var planned_position: Vector3 = primary_blocker.get("start_position", Vector3.ZERO)
		block_alignment = clamp(1.2 - abs(planned_position.z - target_position.z) * 0.18, 0.72, 1.2)

	var block_chance = clamp(actor.block / 100.0 * block_alignment, 0.15, 0.92)
	var roll := rng.randf()

	outcome.actor = actor
	outcome.metadata["roll"] = roll
	outcome.metadata["action"] = "block"
	outcome.metadata["block_alignment"] = block_alignment
	outcome.metadata["attack_lane"] = str(actual_option.get("attack_lane", ""))

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
