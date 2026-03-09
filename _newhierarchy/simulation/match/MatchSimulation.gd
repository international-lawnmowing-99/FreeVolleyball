class_name MatchSimulation

extends RefCounted

signal match_completed(winner: String, final_score: Dictionary)

var team_a:TeamData
var team_b:TeamData

var score: Score

var serving_team: TeamData
var team_a_match_data: TeamMatchData
var team_b_match_data: TeamMatchData
var rally_number: int = 0
var match_over: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var rally_engine:RallyEngine = RallyEngine.new(rng)

func _init(_team_a:TeamData, _team_b:TeamData, _seed: int = -1) -> void:
	team_a = _team_a
	team_b = _team_b

	score = Score.new(team_a, team_b)

	if _seed != -1:
		rng.seed = _seed
	else:
		rng.randomize()

	team_a_match_data = TeamMatchData.new(team_a)
	team_b_match_data = TeamMatchData.new(team_b)

	serving_team = team_a if rng.randf() < 0.5 else team_b


	#team_a.set_starting_rotation(team_a.teamStrategy.choose_starting_rotation())
	#team_b.set_starting_rotation(team_b.teamStrategy.choose_starting_rotation())


func play_match() -> Dictionary:
	while not match_over:
		play_point()

	return {
		"winner": score.get_match_winner().teamName,
		"sets_won": score.sets_won,
		"set_history": score.previous_set_scores,
		"total_rallies": rally_number
	}

func play_point() -> Dictionary:
	if match_over:
		var winner := score.get_match_winner()
		return {
			"type": "match_over",
			"winner": winner,
			"winner_name": winner.teamName
		}

	return _play_rally()

func play_set() -> Dictionary:
	if match_over:
		var winner := score.get_match_winner()
		return {
			"type": "match_over",
			"winner": winner,
			"winner_name": winner.teamName
		}

	var set_index_before: int = score.previous_set_scores.size()
	var rallies_in_set: int = 0
	var last_event: Dictionary = {"type": "point"}

	while not match_over and score.previous_set_scores.size() == set_index_before:
		var point_result = play_point()
		last_event = point_result["score_event"]
		rallies_in_set += 1

	return {
		"type": "set_complete",
		"set_number": set_index_before + 1,
		"rallies_played": rallies_in_set,
		"ending_event": last_event
	}

func step() -> void:
	if not match_over:
		play_point()

func _play_rally() -> Dictionary:
	rally_number += 1

	var previous_serving_team: TeamData = serving_team
	var rally_ctx = _create_rally_context()

	var rally_result = rally_engine.Resolve(rally_ctx)
	if rally_result.point_winner != previous_serving_team:
		_team_match_data_for(rally_result.point_winner).rotate_on_sideout()
	serving_team = rally_result.point_winner

	var score_event: Dictionary = score.award_point(rally_result.point_winner)
	print("[Match] Rally %d winner: %s" % [rally_number, rally_result.point_winner.teamName])
	print("[Match] Current score: %s %d - %s %d" % [team_a.teamName, score.points[team_a], team_b.teamName, score.points[team_b]])

	_handle_score_event(score_event)

	return {
		"type": "point_complete",
		"rally_number": rally_number,
		"point_winner": rally_result.point_winner,
		"point_winner_name": rally_result.point_winner.teamName,
		"score_event": score_event
	}


func _create_rally_context() -> RallyState:
	var state := RallyState.new()
	var serving_match_data: TeamMatchData = _team_match_data_for(serving_team)
	var receiving_team: TeamData = team_b if serving_team == team_a else team_a
	var receiving_match_data: TeamMatchData = _team_match_data_for(receiving_team)

	state.serving_team = serving_team
	state.receiving_team = receiving_team
	state.serving_team_match_data = serving_match_data
	state.receiving_team_match_data = receiving_match_data
	state.current_team = serving_team

	state.rally_number = rally_number

	state.attacker = serving_team
	state.defender = receiving_team
	state.attacker_match_data = serving_match_data
	state.defender_match_data = receiving_match_data

	state.server = serving_match_data.choose_server()
	return state

func get_current_server() -> AthleteStats:
	var serving_match_data: TeamMatchData = _team_match_data_for(serving_team)
	return serving_match_data.choose_server()

func _team_match_data_for(team: TeamData) -> TeamMatchData:
	if team == team_a:
		return team_a_match_data
	return team_b_match_data

func _handle_score_event(score_attempt):
	if score_attempt["type"] == "set_over":
		print("[Match] Set won by %s. Sets: %d-%d" % [score_attempt["winner"].teamName, score.sets_won[team_a], score.sets_won[team_b]])
	if score_attempt["type"] == "match_over":
		match_over = true
		print("[Match] Match won by %s" % score_attempt["winner"].teamName)
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
