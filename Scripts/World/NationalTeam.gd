extends "res://Scripts/Team.gd"

class_name NationalTeam
var players = []
func _init():
	pass
func SelectNationalTeam():
	var orderedPlayers = players.duplicate(false)
	orderedPlayers.sort_custom(Athlete, "SortSkill")
	for i in range(12):
		allPlayers.append(orderedPlayers[i])
