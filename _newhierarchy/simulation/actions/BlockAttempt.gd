extends Attempt
class_name BlockAttempt

func resolve() -> BlockOutcome:
	var outcome := BlockOutcome.new()
	var actual_option: Dictionary = ctx.chosen_set_option
	var positioning_plan: Dictionary = ctx.defensive_positioning_plan
	var available_blocker_plans: Array[Dictionary] = SetPlayAnalysis.identify_reachable_blockers(positioning_plan, actual_option)
	var available_blockers: Array[AthleteStats] = []
	for blocker_plan in available_blocker_plans:
		var blocker: AthleteStats = blocker_plan.get("athlete")
		if blocker != null:
			available_blockers.append(blocker)
	ctx.available_blocker_plans = available_blocker_plans
	ctx.available_blockers = available_blockers

	var block_alignment: float = 1.0
	var primary_blocker: Dictionary = positioning_plan.get("primary_blocker", {})
	if not actual_option.is_empty() and not primary_blocker.is_empty():
		var target_position: Vector3 = actual_option.get("contact_position", Vector3.ZERO)
		var planned_position: Vector3 = primary_blocker.get("start_position", Vector3.ZERO)
		block_alignment = clamp(1.2 - abs(planned_position.z - target_position.z) * 0.18, 0.72, 1.2)

	outcome.actor = actor
	outcome.metadata["action"] = "block"
	outcome.metadata["block_alignment"] = block_alignment
	outcome.metadata["attack_lane"] = str(actual_option.get("attack_lane", ""))
	outcome.metadata["available_blockers"] = available_blockers.size()

	if actor == null or available_blockers.is_empty():
		outcome.success = false
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "attack_scores"
		outcome.metadata["reason"] = "no_reachable_blocker"
		return outcome

	var support_factor: float = 1.0 + max(0.0, float(available_blockers.size() - 1)) * 0.18
	var block_roll: float = rng.randf_range(1.0, max(actor.block * block_alignment * support_factor, 1.0))
	var attacking_athlete: AthleteStats = actual_option.get("attacker", null)
	var attack_skill: float = float(ctx.chosen_set_option.get("spike_skill", attacking_athlete.spike if attacking_athlete != null else 1.0))
	var attack_roll: float = rng.randf_range(1.0, max(attack_skill, 1.0))
	var deflect_gradient: float = 0.25
	var lane_delta: float = 0.0
	if not available_blocker_plans.is_empty():
		lane_delta = float(available_blocker_plans[0].get("lane_delta", 0.0))

	outcome.metadata["attack_roll"] = attack_roll
	outcome.metadata["block_roll"] = block_roll
	outcome.metadata["support_factor"] = support_factor
	outcome.metadata["lane_delta"] = lane_delta
	outcome.metadata["primary_blocker_name"] = "%s %s" % [actor.firstName, actor.lastName]

	if attack_roll > block_roll * (1.0 + deflect_gradient):
		outcome.success = false
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "attack_scores"
	elif block_roll > attack_roll * (1.0 + deflect_gradient):
		outcome.success = true
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "stuff_block"
	else:
		outcome.success = true
		outcome.terminal = false
		outcome.metadata["result"] = "soft_touch_continues"

	return outcome
