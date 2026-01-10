extends Control

class_name  StatsViewerUI

@export var mm:MatchManager
@onready var teamAButton:Button = $ColourRect/ColourRect2/TeamButtons/TeamAButton
@onready var teamBButton:Button = $ColourRect/ColourRect2/TeamButtons/TeamBButton

@onready var rowHolder = $ColourRect/ColourRect2/VBoxContainer/PassingStats/RowHolder

var teamAPlayersCount:int = 0
var teamBPlayersCount:int = 0

var statsRow:PackedScene = preload("res://Scenes/MatchScene/MatchUI/PassingStatsRow.tscn")

var isTeamASelected = true
var isTeamBSelected = false

func Init():
	teamAButton.text = mm.teamA.data.teamName
	teamBButton.text = mm.teamB.data.teamName

	teamAPlayersCount = mm.teamA.data.matchPlayers.size()
	teamBPlayersCount = mm.teamB.data.matchPlayers.size()

	for lad in mm.teamA.data.matchPlayers:
		var newRow = statsRow.instantiate()
		rowHolder.add_child(newRow)

	for lad in mm.teamB.data.matchPlayers:
		var newRow = statsRow.instantiate()
		rowHolder.add_child(newRow)

func UpdateDisplay():
	var rows = rowHolder.get_children()
	for row in rows:
		row.visible = false
	if isTeamASelected:
		for i in teamAPlayersCount:
			rows[i].visible = true
			(rows[i] as PassingStatsRow).UpdateRowDisplay(i+1, mm.teamA.matchPlayerNodes[i])

func _on_team_a_button_pressed() -> void:
	pass # Replace with function body.


func _on_team_b_button_pressed() -> void:
	pass # Replace with function body.


func _on_serve_button_pressed() -> void:
	pass # Replace with function body.


func _on_passing_button_pressed() -> void:
	pass # Replace with function body.


func _on_set_button_pressed() -> void:
	pass # Replace with function body.


func _on_block_button_pressed() -> void:
	pass # Replace with function body.


func _on_attack_button_pressed() -> void:
	pass # Replace with function body.
