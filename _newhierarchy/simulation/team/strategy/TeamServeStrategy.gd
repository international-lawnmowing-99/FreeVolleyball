extends Resource
class_name TeamServeStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func choose_serve_plan(server: AthleteStats, team_match_data: TeamMatchData = null, opponent_match_data: TeamMatchData = null, rng: RandomNumberGenerator = null) -> Dictionary:
	return team_strategy._choose_serve_plan_impl(server, team_match_data, opponent_match_data, rng)
