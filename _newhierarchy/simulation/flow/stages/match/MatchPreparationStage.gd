class_name MatchPreparationStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func prepare_for_match(team: TeamData, plan: TeamSeasonPlan, opponent: TeamData) -> void:
	log.log("match_setup", "Preparing for match.", team)
	select_match_squad(team, plan)
	select_starting_lineup(team)
	configure_libero_usage(team)
	choose_starting_rotation(team)
	choose_serving_strategy(team, opponent)
	choose_receive_side_strategy(team, opponent)
	log.log("match_setup", "Match preparation completed.", team)

func select_match_squad(team: TeamData, plan: TeamSeasonPlan) -> void:
	log.log("match_setup", "Selecting match squad from roster.", team)
	# TODO: Choose available players based on season plan, fatigue, injuries, and tactical fit.

func select_starting_lineup(team: TeamData) -> void:
	log.log("match_setup", "Selecting starting lineup.", team)
	# TODO: Choose the starting six and bench order.

func configure_libero_usage(team: TeamData) -> void:
	log.log("match_setup", "Configuring libero usage.", team)
	# TODO: Define libero patterns for serve/receive and defensive substitutions.

func choose_starting_rotation(team: TeamData) -> void:
	log.log("match_setup", "Choosing starting rotation.", team)
	# TODO: Choose the opening rotation based on strengths and matchup plan.

func choose_serving_strategy(team: TeamData, opponent: TeamData) -> void:
	log.log("match_setup", "Choosing serving strategy.", team)
	# TODO: Target weak passers, zones, strong attackers, or the libero depending on plan.

func choose_receive_side_strategy(team: TeamData, opponent: TeamData) -> void:
	log.log("match_setup", "Choosing initial attack structure when receiving serve.", team)
	# TODO: Decide designated setter, attack options, emergency second-ball attacks, and play calls.
