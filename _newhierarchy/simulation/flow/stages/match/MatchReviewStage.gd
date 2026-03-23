class_name MatchReviewStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func evaluate_post_match(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("post_match", "Evaluating match result in season context.", team)
	assess_result_vs_goal(team, plan)
	review_training_direction(team, plan)

func assess_result_vs_goal(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("post_match", "Assessing match result against season goals.", team)
	# TODO: Compare result to season_goal and update morale, expectations, and planning state.

func review_training_direction(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("post_match", "Re-evaluating training after the match.", team)
	# TODO: Update upcoming training focus from match takeaways.
