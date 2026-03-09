#extends RefCounted
#
#class_name PassAttempt
#
#var passer
#var ball
#var team_context

class_name PassAttempt
extends Attempt

func resolve() -> AttemptOutcome:
	var outcome: PassOutcome = PassOutcome.new()

	var receiver_skill: float = float(clamp(actor.reception / 100.0, 0.15, 0.95))
	var receive_difficulty: float = float(clamp(ctx.serve_receive_difficulty, 0.05, 1.0))
	var instability: float = float(clamp(0.5 + receive_difficulty - receiver_skill, 0.05, 0.95))
	var roll: float = rng.randf()

	outcome.actor = actor
	outcome.success = roll > instability
	outcome.pass_quality = float(clamp(receiver_skill - receive_difficulty * 0.45 + rng.randf_range(-0.15, 0.15), 0.0, 1.0))
	outcome.metadata["roll"] = roll
	outcome.metadata["receiver_skill"] = receiver_skill
	outcome.metadata["receive_difficulty"] = receive_difficulty
	outcome.metadata["instability"] = instability
	outcome.metadata["action"] = "receive"

	if not outcome.success:
		var ace_cutoff: float = float(clamp(instability * (0.45 + receive_difficulty * 0.55), 0.05, 0.8))
		var is_ace: bool = receive_difficulty > 0.55 and roll < ace_cutoff
		outcome.terminal = true
		outcome.point_winner = ctx.attacker
		outcome.metadata["result"] = "ace" if is_ace else "overpass_or_shank"
	else:
		outcome.terminal = false
		outcome.metadata["result"] = "controlled_pass"

	return outcome

#
#func _init(_passer, _ball, _team_context):
	#passer = _passer
	#ball = _ball
	#team_context = _team_context
#
#func _evaluate_reach() -> ReachResult:
	#if ReachModel.can_get_set_behind_ball(passer, ball):
		#return ReachResult.SET
#
	#if ReachModel.can_reach_upright(passer, ball):
		#return ReachResult.UPRIGHT
#
	#if ReachModel.can_reach_diving(passer, ball):
		#return ReachResult.DIVE
#
	#return ReachResult.NONE
#
#func _effective_passing_skill(reach: int) -> float:
	#var skill = passer.passing_stat_for(ball.pass_type)
#
	#match reach:
		#ReachResult.SET:
			#pass # no penalty
		#ReachResult.UPRIGHT:
			#skill *= 0.8
		#ReachResult.DIVE:
			#skill *= 0.6
#
	#return skill
#
#func _resolve_quality(skill: float, difficulty: float) -> float:
	#return skill - difficulty
#
#func _translate_outcome(score: float) -> PassOutcome:
	#var quality := PassQualityModel.from_score(score)
#
	#var deviation := DeviationModel.compute(
		#score,
		#team_context.preferred_trajectory,
		#rng
		#)
#
	#return PassOutcome.new(
		#passer,
		#quality,
		#deviation
	#)
#
#func resolve() -> PassOutcome:
	#var reach = _evaluate_reach()
#
	#if reach == ReachResult.NONE:
		#return PassOutcome.ace_against(passer)
#
	#var skill = _effective_passing_skill(reach)
	#var difficulty = _serve_difficulty()
#
	#var score = _resolve_quality(skill, difficulty)
	#return _translate_outcome(score)
