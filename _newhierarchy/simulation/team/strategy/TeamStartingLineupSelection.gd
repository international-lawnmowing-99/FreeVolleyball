extends RefCounted

var system

func  _init(_system) -> void:
	system = _system



func calculate_offence(lineup:Array[AthleteStats]) -> float:
	var score := 0.0

	var context = {
		"rotation_index": 0,
		"touch_number": 2
	}

	# Ask system who the setter is in this lineup
	var setter = system.get_designated_setter(lineup, context)

	for player in lineup:
		score += player.athleteStats.spike

	# Add setter dump contribution
	if setter != null:
		score += setter.athleteStats.dump

	return score
