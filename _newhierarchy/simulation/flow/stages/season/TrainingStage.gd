class_name TrainingStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func run_training_block(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("training", "Starting scheduled training block.", team)
	schedule_weekly_training(team, plan)
	train_skills(team)
	train_physical_attributes(team)
	mitigate_age_related_decline(team)
	develop_team_plays(team)
	build_connection_bonus(team)
	log.log("training", "Training block completed.", team)

func schedule_weekly_training(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("training", "Scheduling training around fixtures.", team)
	# TODO: Build weekly training schedule around matches, travel, and recovery.

func train_skills(team: TeamData) -> void:
	log.log("training", "Improving player skill attributes toward potential.", team)
	# TODO: Raise technical stats toward long-term potential ceilings.

func train_physical_attributes(team: TeamData) -> void:
	log.log("training", "Improving physical attributes toward potential.", team)
	# TODO: Train jump, speed, acceleration, and arm-swing power.

func mitigate_age_related_decline(team: TeamData) -> void:
	log.log("training", "Applying older-player physical maintenance plan.", team)
	# TODO: Slow age-related decline from roughly age 28 onward with targeted physical work.

func develop_team_plays(team: TeamData) -> void:
	log.log("training", "Developing new team plays and dummy-run patterns.", team)
	# TODO: Add play concepts that overload blockers and create attacking options.

func build_connection_bonus(team: TeamData) -> void:
	log.log("training", "Building connection bonuses between players who train together.", team)
	# TODO: Increase pair/group familiarity for players training repeatedly together.
