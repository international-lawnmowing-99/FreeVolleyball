extends Control
class_name PlayerStatsTable

var playerStatsRow = preload("res://Scenes/MatchScene/MatchUI/PlayerStatsRow.tscn")
@onready var rows = $ScrollContainer/Rows
var allPlayerStatsRows = []
var allPlayers = []
var firstNamesAscending:bool = false
var lastNamesAscending:bool = false
var spikeHeightAscending:bool = false
var blockHeightAscending:bool = false
var serveAscending:bool = false
var spikeAscending:bool = false
var receiveAscending:bool = false
var setAscending:bool = false
var staminaAscending:bool = false

func _ready():
	await get_tree().create_timer(.1).timeout
	var mManager:MatchManager = get_tree().root.get_node("MatchScene")
	PopulateTable(mManager.teamA)

func PopulateTable(team:Team):
	if team.nation.nationalTeam.players:
		for player in team.nation.nationalTeam.players:
			allPlayers.append(player)
			var newRow:PlayerStatsRow = playerStatsRow.instantiate()
			rows.add_child(newRow)
			newRow.DisplayPlayer(player)
			allPlayerStatsRows.append(newRow)
			
	else:
		for player in team.allPlayers:
			allPlayers.append(player)
			var newRow:PlayerStatsRow = playerStatsRow.instantiate()

			rows.add_child(newRow)
			newRow.DisplayPlayer(player)

			allPlayerStatsRows.append(newRow)


func _on_selected_pressed():
#	for row in allPlayerStatsRows:
#		if row.selected.button_pressed:
#			rows.move_child(row, 0)
	pass

func _on_first_name_pressed():
	if firstNamesAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.firstName > b.stats.firstName)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.firstName < b.stats.firstName)
		
	firstNamesAscending = !firstNamesAscending
	
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])


func _on_last_name_pressed():
	if lastNamesAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.lastName > b.stats.lastName)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.lastName < b.stats.lastName)
		
	lastNamesAscending = !lastNamesAscending
	
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])


func _on_spike_height_pressed():
	if spikeHeightAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.spikeHeight > b.stats.spikeHeight)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.spikeHeight < b.stats.spikeHeight)
		
	spikeHeightAscending = !spikeHeightAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])

func _on_block_height_pressed():
	if blockHeightAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.blockHeight > b.stats.blockHeight)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.blockHeight < b.stats.blockHeight)
		
	blockHeightAscending = !blockHeightAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])

func _on_serve_pressed():
	if serveAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.serve > b.stats.serve)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.serve < b.stats.serve)
		
	serveAscending = !serveAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])

func _on_spike_pressed():
	if spikeAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.spike > b.stats.spike)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.spike < b.stats.spike)
	
	spikeAscending = !spikeAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])

func _on_receive_pressed():
	if receiveAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.reception > b.stats.reception)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.reception < b.stats.reception)
		
	receiveAscending = !receiveAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])


func _on_set_pressed():
	if setAscending:
		allPlayers.sort_custom(func(a,b): return a.stats.set > b.stats.set)
	else:
		allPlayers.sort_custom(func(a,b): return a.stats.set < b.stats.set)

	setAscending = !setAscending
	for i in allPlayerStatsRows.size():
		allPlayerStatsRows[i].DisplayPlayer(allPlayers[i])