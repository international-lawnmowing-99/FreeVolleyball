class_name NationalProgramStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func build_national_teams(world: SimulationWorldState) -> void:
	log.log("national", "Building national teams from the best eligible players.")
	select_players_by_nationality(world)
	schedule_national_team_competitions(world)

func select_players_by_nationality(world: SimulationWorldState) -> void:
	log.log("national", "Selecting top players from each nationality.")
	# TODO: Group players by nationality and choose national-team rosters.
	# TODO: National teams should not own training programs the way clubs do.

func schedule_national_team_competitions(world: SimulationWorldState) -> void:
	log.log("national", "Scheduling VNL, Olympics, and continental championships.")
	# TODO: Create national-team tournament calendar and entry rules.
