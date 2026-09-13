extends Resource
class_name TeamAttackStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func choose_attacker(team_match_data: TeamMatchData = null, rng: RandomNumberGenerator = null) -> AthleteStats:
	return team_strategy._choose_attacker_impl(team_match_data, rng)

func attack_runup_start_local(contact_local: Vector3, athlete: AthleteStats) -> Vector3:
	return team_strategy._attack_runup_start_local_impl(contact_local, athlete)

func attack_approach_time(from_local: Vector3, runup_start_local: Vector3, athlete: AthleteStats) -> float:
	return team_strategy._attack_approach_time_impl(from_local, runup_start_local, athlete)

func attack_cover_local(athlete: AthleteStats, chosen_option: Dictionary) -> Vector3:
	return team_strategy._attack_cover_local_impl(athlete, chosen_option)
