class_name MatchSimulation

extends RefCounted

signal match_completed(winner: String, final_score: Dictionary)

var team_a:TeamData
var team_b:TeamData

var score: Score

var serving_team: TeamData
var rally_number: int = 0
var match_over: bool = false

var rng := RandomNumberGenerator.new()

var rally_engine:RallyEngine = RallyEngine.new(rng)

func _init(_team_a:TeamData, _team_b:TeamData, _seed: int = -1) -> void:
	team_a = _team_a
	team_b = _team_b

	score = Score.new(team_a, team_b)

	if _seed != -1:
		rng.seed = _seed
	else:
		rng.randomize()

	serving_team = team_a if rng.randf() < 0.5 else team_b


	#team_a.set_starting_rotation(team_a.teamStrategy.choose_starting_rotation())
	#team_b.set_starting_rotation(team_b.teamStrategy.choose_starting_rotation())


func play_match() -> Dictionary:
	while not match_over:
		_play_rally()

	return {
		"winner": score.get_match_winner().teamName,
		"sets_won": score.sets_won,
		"set_history": score.previous_set_scores,
		"total_rallies": rally_number
	}

func step() -> void:
	if not match_over:
		_play_rally()

func _play_rally() -> void:
	rally_number += 1

	var rally_ctx = _create_rally_context()

	var rally_result = rally_engine.Resolve(rally_ctx)

	var score_event = score.award_point(rally_result.point_winner)

	_handle_score_event(score_event)


func _create_rally_context() -> RallyState:
	var state := RallyState.new()

	state.serving_team = serving_team
	state.receiving_team = team_b if serving_team == team_a else team_a
	state.current_team = serving_team

	state.rally_number = rally_number

	state.attacker = serving_team
	state.defender = state.receiving_team

	state.server = serving_team.choose_server()
	return state

func _handle_score_event(score_attempt):
	if score_attempt["type"] == "match_over":
		match_over = true
	return {}

func create_save_data() -> MatchSaveData:
	var save := MatchSaveData.new()

	save.team_a = team_a
	save.team_b = team_b
	save.score_data = score.serialize()
	save.rally_number = rally_number
	save.serving_team_name = serving_team.teamName
	#save.team_a_rotation_index = team_a_state.rotation_index
	#save.team_b_rotation_index = team_b_state.rotation_index

	return save
