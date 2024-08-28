extends Control
class_name PlayerStatsTable

var playerStatsRow = preload("res://Scenes/MatchScene/MatchUI/PlayerStatsRow.tscn")
@onready var rows = $ScrollContainer/Rows
var matchPlayerstatsRows = []
var matchPlayers:Array[AthleteStats] = []
var selectedPlayers:Array[AthleteStats] = []

var firstNamesAscending:bool = false
var lastNamesAscending:bool = false
var spikeHeightAscending:bool = false
var blockHeightAscending:bool = false
var serveAscending:bool = false
var spikeAscending:bool = false
var receiveAscending:bool = false
var setAscending:bool = false
var staminaAscending:bool = false

func clear():
	matchPlayerstatsRows.clear()
	matchPlayers.clear()
	for lad in selectedPlayers:
		lad.uiSelected = false
	selectedPlayers.clear()
	for entry in rows.get_children():
		entry.queue_free()

func PopulateTable(team:TeamData):
	if team is NationalTeam:
		for player in team.nationalPlayers:
			matchPlayers.append(player)
			var newRow:PlayerStatsRow = playerStatsRow.instantiate()
			newRow.playerStatsTable = self
			rows.add_child(newRow)
			newRow.DisplayPlayer(player)
			newRow.clubOrInternational = Enums.ClubOrInternational.International
			matchPlayerstatsRows.append(newRow)

	else:
		for player in team.matchPlayers:
			matchPlayers.append(player)
			var newRow:PlayerStatsRow = playerStatsRow.instantiate()
			newRow.playerStatsTable = self

			rows.add_child(newRow)
			player.uiSelected = true
			newRow.DisplayPlayer(player)

			newRow.clubOrInternational = Enums.ClubOrInternational.Club
			matchPlayerstatsRows.append(newRow)
			newRow._on_selected_pressed()

func _on_selected_pressed():
	matchPlayers.sort_custom(func(a,b): return a.uiSelected > b.uiSelected)

	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func _on_first_name_pressed():
	if firstNamesAscending:
		matchPlayers.sort_custom(func(a,b): return a.firstName > b.firstName)
	else:
		matchPlayers.sort_custom(func(a,b): return a.firstName < b.firstName)

	firstNamesAscending = !firstNamesAscending

	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])


func _on_last_name_pressed():
	if lastNamesAscending:
		matchPlayers.sort_custom(func(a,b): return a.lastName > b.lastName)
	else:
		matchPlayers.sort_custom(func(a,b): return a.lastName < b.lastName)

	lastNamesAscending = !lastNamesAscending

	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])


func _on_spike_height_pressed():
	if spikeHeightAscending:
		matchPlayers.sort_custom(func(a,b): return a.spikeHeight > b.spikeHeight)
	else:
		matchPlayers.sort_custom(func(a,b): return a.spikeHeight < b.spikeHeight)

	spikeHeightAscending = !spikeHeightAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func _on_block_height_pressed():
	if blockHeightAscending:
		matchPlayers.sort_custom(func(a,b): return a.blockHeight > b.blockHeight)
	else:
		matchPlayers.sort_custom(func(a,b): return a.blockHeight < b.blockHeight)

	blockHeightAscending = !blockHeightAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func _on_serve_pressed():
	if serveAscending:
		matchPlayers.sort_custom(func(a,b): return a.serve > b.serve)
	else:
		matchPlayers.sort_custom(func(a,b): return a.serve < b.serve)

	serveAscending = !serveAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func _on_spike_pressed():
	if spikeAscending:
		matchPlayers.sort_custom(func(a,b): return a.spike > b.spike)
	else:
		matchPlayers.sort_custom(func(a,b): return a.spike < b.spike)

	spikeAscending = !spikeAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func _on_receive_pressed():
	if receiveAscending:
		matchPlayers.sort_custom(func(a,b): return a.reception > b.reception)
	else:
		matchPlayers.sort_custom(func(a,b): return a.reception < b.reception)

	receiveAscending = !receiveAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])


func _on_set_pressed():
	if setAscending:
		matchPlayers.sort_custom(func(a,b): return a.set > b.set)
	else:
		matchPlayers.sort_custom(func(a,b): return a.set < b.set)

	setAscending = !setAscending
	for i in matchPlayerstatsRows.size():
		matchPlayerstatsRows[i].DisplayPlayer(matchPlayers[i])

func SelectUnselectAthlete(athlete:AthleteStats):
	if athlete in selectedPlayers:
		selectedPlayers.erase(athlete)
	else:
		selectedPlayers.append(athlete)
