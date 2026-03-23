class_name SeasonPlanningStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func build_season_plan(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Building season plan.", team)
	set_season_goal(team, plan)
	apply_external_expectations(team, plan)
	evaluate_roster_strength(team, plan)
	plan_availability_and_contingencies(team, plan)
	plan_youth_development(team, plan)
	plan_rest_strategy(team, plan)
	log.log("season", "Season plan completed.", team)

func set_season_goal(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Setting season goal.", team)
	# TODO: Choose goals such as top-half finish, tournament win, or semi-final appearance.
	# TODO: Store the outcome in plan.season_goal.

func apply_external_expectations(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Applying sponsor and fan expectations.", team)
	# TODO: Adjust goals and pressure based on sponsor and fan demands.

func evaluate_roster_strength(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Evaluating roster strength and previous performance.", team)
	# TODO: Use roster quality, depth, and prior results to calibrate ambition.

func plan_availability_and_contingencies(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Planning around injuries, form swings, and absences.", team)
	# TODO: Build contingency lineups for injury, poor form, and schedule congestion.

func plan_youth_development(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Planning youth-player development.", team)
	# TODO: Allocate match opportunities and training goals for younger players.

func plan_rest_strategy(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("season", "Planning star-player usage and rest strategy.", team)
	# TODO: Rest stronger players strategically if the goal is to peak for decisive matches.
