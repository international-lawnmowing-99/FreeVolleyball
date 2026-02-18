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
	var outcome := PassOutcome.new()

	var quality = actor.pass_rating
	var roll = rng.randf()

	outcome.actor = actor
	outcome.success = roll < quality
	outcome.metadata["roll"] = roll

	if not outcome.success:
		outcome.terminal = true
		outcome.point_winner = ctx.attacker
	else:
		outcome.terminal = false

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
