class_name TeamMatchData
extends RefCounted

var team: TeamData
var rotation_index: int = 0
var court_players: Array[AthleteStats]
var bench_players: Array[AthleteStats]
var is_receiving: bool

func _init(_team: TeamData):
	team = _team


	court_players = team.matchPlayers.slice(0, 6)
	bench_players = team.matchPlayers.slice(6)


func rotate_on_sideout():
	if not is_receiving:
		return
