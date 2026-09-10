class_name SetReviewStage
extends RefCounted

var event_log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	event_log = _log

func evaluate_post_set(team: TeamData) -> void:
	event_log.log("post_set", "Evaluating end-of-set decisions.", team)
	choose_new_rotations(team)

func choose_new_rotations(team: TeamData) -> void:
	event_log.log("post_set", "Choosing rotations for the next set.", team)
	# TODO: Review player effectiveness in the completed set and choose updated rotations.
