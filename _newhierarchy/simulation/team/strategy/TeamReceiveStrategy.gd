extends Resource
class_name TeamReceiveStrategy

var team_strategy: TeamStrategy

func _init(_team_strategy: TeamStrategy = null) -> void:
	team_strategy = _team_strategy

func phase_local_target(athlete: AthleteStats, team_match_data: TeamMatchData, phase: String, highlighted_player: AthleteStats = null, has_ball_control: bool = false) -> Vector3:
	return team_strategy._phase_local_target_impl(athlete, team_match_data, phase, highlighted_player, has_ball_control)

func reception_target_for_side(team_side: float) -> Vector3:
	return team_strategy._reception_target_for_side_impl(team_side)

func receive_transition_local(team_match_data: TeamMatchData, athlete: AthleteStats, pass_target_world: Vector3 = Vector3.ZERO, chosen_option: Dictionary = {}) -> Vector3:
	return team_strategy._receive_transition_local_impl(team_match_data, athlete, pass_target_world, chosen_option)

func choose_passer_for_ball(team_match_data: TeamMatchData, ball_position: Vector3, team_side: float) -> AthleteStats:
	return team_strategy._choose_passer_for_ball_impl(team_match_data, ball_position, team_side)
