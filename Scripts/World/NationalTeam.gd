extends "res://Scripts/Team.gd"

class_name NationalTeam
var nationalPlayers = []
func _init():
	pass
func SelectNationalTeam():
	if matchPlayers.size() >= 12:
		Console.AddNewLine("Already have a selected national team, skipping autoselect")
		return
	
	var orderedPlayers = nationalPlayers.duplicate(false)
	orderedPlayers.sort_custom(Callable(Athlete,"SortSkill"))
	for i in range(12):
		matchPlayers.append(orderedPlayers[i])
