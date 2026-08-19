class_name WorldBootstrapStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func create_initial_world(world: SimulationWorldState) -> void:
	log.log("world", "Initial world creation started.")
	generate_professional_athletes(world)
	generate_professional_teams(world)
	for team in world.professional_teams:
		assign_team_strategic_preferences(team)
		negotiate_contracts(team, world.free_agents)
		#apply_international_player_limits(team)
		#finalize_roster(team)
		allocate_team_budget(team)
	log.log("world", "Initial world creation completed.")

func generate_professional_athletes(world: SimulationWorldState) -> void:
	log.log("world", "Generating professional athletes distributed around the world.")
	# TODO: Create athletes with nationality, age, current ability, potential, and location.
	# TODO: Add athletes to world.athletes and world.free_agents.

func generate_professional_teams(world: SimulationWorldState) -> void:
	log.log("world", "Generating professional teams.")
	# TODO: Create professional teams, leagues, budgets, and operating context.
	# TODO: Add teams to world.professional_teams.

func assign_team_strategic_preferences(team: TeamData) -> void:
	log.log("world", "Assigning team and coach strategic preferences.", team)
	# TODO: Set strategy weights for youth, key stats, international status, role priorities, and contract length.
	# TODO: Decide later whether coaches remain abstract or become separate hireable entities.

func negotiate_contracts(team: TeamData, free_agents: Array[AthleteData]) -> void:
	log.log("world", "Negotiating contracts to build roster.", team)
	# TODO: Model team spending priorities against athlete goals, promises, salary demands, and court-time expectations.
	# TODO: Track athlete happiness and future re-sign desire based on offer quality and promises kept.
	# TODO: Move signed players from free_agents into the team roster.

#func apply_international_player_limits(team: TeamData) -> void:
	#log.log("world", "Applying international-player restrictions for league context.", team)
	## TODO: Enforce league-specific foreign-player caps where applicable.

#func finalize_roster(team: TeamData) -> void:
	#log.log("world", "Finalizing roster after negotiations.", team)
	## TODO: Confirm final roster size, role balance, and depth chart.

func allocate_team_budget(team: TeamData) -> void:
	log.log("world", "Allocating budget to training, facilities, and operations.", team)
	# TODO: Decide budget split for training, facilities, staff, scouting, and other operating expenses.
