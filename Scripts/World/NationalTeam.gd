extends "res://Scripts/Team.gd"

class_name NationalTeam
var players = []
func _init():
	pass
func SelectNationalTeam():
	if allPlayers.size() >= 12:
		Console.AddNewLine("Already have a selected national team, skipping autoselect")
		return
	
	var orderedPlayers = players.duplicate(false)
	orderedPlayers.sort_custom(Callable(Athlete,"SortSkill"))
	for i in range(12):
		allPlayers.append(orderedPlayers[i])
