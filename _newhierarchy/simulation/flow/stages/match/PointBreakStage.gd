class_name PointBreakStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func evaluate_post_point(team: TeamData) -> void:
	log.log("post_point", "Evaluating end-of-point decisions.", team)
	evaluate_timeout(team)
	evaluate_substitutions(team)
	evaluate_libero_changes(team)
	evaluate_tactical_adjustments(team)

func evaluate_timeout(team: TeamData) -> void:
	log.log("post_point", "Evaluating timeout call.", team)
	# TODO: Consider runs conceded, score pressure, fatigue, and remaining timeouts.
	# TODO: Handle priority where the team that lost the point gets first timeout opportunity.

func evaluate_substitutions(team: TeamData) -> void:
	log.log("post_point", "Evaluating substitutions.", team)
	# TODO: Use fatigue, underperformance, remaining substitutions, and planned double-subs.

func evaluate_libero_changes(team: TeamData) -> void:
	log.log("post_point", "Evaluating libero changes.", team)
	# TODO: Decide whether to make libero swaps for the next rally.

func evaluate_tactical_adjustments(team: TeamData) -> void:
	log.log("post_point", "Evaluating tactical changes.", team)
	# TODO: Adjust blocking and attacking plans from recent rally evidence.
