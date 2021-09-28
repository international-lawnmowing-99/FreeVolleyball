extends "res://Scripts/Team.gd"

class_name NationalTeam
var players = []
func _init():
	pass
func SelectNationalTeam():
	for i in range(12):
		allPlayers.append(players[i])
