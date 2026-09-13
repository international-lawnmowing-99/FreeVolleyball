extends Resource
class_name TeamBlockStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func choose_blocker(team_match_data: TeamMatchData = null, rng: RandomNumberGenerator = null) -> AthleteStats:
	return team_strategy._choose_blocker_impl(team_match_data, rng)

func defensive_plan_local_target(athlete: AthleteStats, positioning_plan: Dictionary) -> Vector3:
	return team_strategy._defensive_plan_local_target_impl(athlete, positioning_plan)
