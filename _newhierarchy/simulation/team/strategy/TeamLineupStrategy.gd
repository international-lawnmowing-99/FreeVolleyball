extends Resource
class_name TeamLineupStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func choose_starting_rotation() -> int:
	return team_strategy._choose_starting_rotation_impl()

func select_starting_lineup(players: Array[AthleteStats]) -> Array[AthleteStats]:
	return team_strategy._select_starting_lineup_impl(players)
