extends Resource
class_name TeamSettingStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func choose_setter(team_match_data: TeamMatchData = null, rng: RandomNumberGenerator = null) -> AthleteStats:
	return team_strategy._choose_setter_impl(team_match_data, rng)

func setting_preference_weight_for_attacker(attacker: AthleteStats) -> float:
	return team_strategy._setting_preference_weight_for_attacker_impl(attacker)
