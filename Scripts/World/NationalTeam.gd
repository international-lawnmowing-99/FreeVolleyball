extends "res://Scripts/Team.gd"

class_name NationalTeam
var players = []
func _init():
	pass
func SelectNationalTeam():
	for i in range(12):
		var orderedPlayers = players.duplicate(false)
		orderedPlayers.sort_custom(Athlete, "SortSkill")
		allPlayers.append(orderedPlayers[i])
