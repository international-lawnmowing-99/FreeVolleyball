class_name TeamMatchData
extends RefCounted

var team: TeamData
var court_players: Array[AthleteStats]
var bench_players: Array[AthleteStats]
var sideout_rotations: int = 0

func _init(_team: TeamData):
	team = _team

	if team.courtPlayers.is_empty():
		team.select_starting_lineup()

	court_players = team.courtPlayers.duplicate()
	bench_players = team.benchPlayers.duplicate()
	_sync_rotation_positions()

func rotate_on_sideout() -> void:
	if court_players.size() < 2:
		return

	# Keep court_players in position order [1..6]. On side-out, team rotates:
	# P2 -> P1 (new server), P3 -> P2 ... P1 -> P6.
	var former_p1: AthleteStats = court_players[0]
	for i in range(court_players.size() - 1):
		court_players[i] = court_players[i + 1]
	court_players[court_players.size() - 1] = former_p1
	sideout_rotations += 1
	_sync_rotation_positions()

func choose_server() -> AthleteStats:
	if court_players.is_empty():
		push_error("No court players available for serving.")
		return null
	return court_players[0]

func _sync_rotation_positions() -> void:
	for i in range(court_players.size()):
		court_players[i].rotationPosition = i + 1
