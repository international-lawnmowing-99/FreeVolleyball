extends RefCounted
class_name Score

var previous_set_scores := []

var team_a: TeamData
var team_b: TeamData

var points := {}
var sets_won := {}

func _init(a: TeamData, b: TeamData) -> void:
	team_a = a
	team_b = b

	points[team_a] = 0
	points[team_b] = 0

	sets_won[team_a] = 0
	sets_won[team_b] = 0


func award_point(team: TeamData):
	if not points.has(team):
		push_error("Score received unknown team")
		return

	var other = team_b if team == team_a else team_a

	points[team] += 1

	# Fifth set
	if sets_won[team_a] == 2 and sets_won[team_b] == 2:
		if points[team] >= 15 and points[team] >= points[other] + 2:
			return _win_set(team)

	# Sets 1–4
	elif points[team] >= 25 and points[team] >= points[other] + 2:
		return _win_set(team)

	return {"type": "point"}

func _win_set(team: TeamData) -> Dictionary:
	var other := team_b if team == team_a else team_a

	previous_set_scores.append({
		team_a: points[team_a],
		team_b: points[team_b]
	})

	sets_won[team] += 1
	points[team_a] = 0
	points[team_b] = 0

	if sets_won[team] >= 3:
		return {
			"type": "match_over",
			"winner": team
		}

	return {
		"type": "set_over",
		"winner": team
	}

func get_match_winner() -> TeamData:
	if sets_won[team_a] >= 3:
		return team_a
	elif sets_won[team_b] >= 3:
		return team_b
	else:
		push_error("no winner, but queried")
		return null
