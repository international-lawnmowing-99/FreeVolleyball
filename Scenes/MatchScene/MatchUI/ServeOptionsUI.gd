class_name ServeOptionsUI
extends Control

@onready var infoLabel = $Athlete1ServeOptionsUI/Panel/InfoLabel
var teamA:TeamNode
var teamB


func Init(_teamA, _teamB) -> void:
	teamA = _teamA
	teamB = _teamB

	for athlete:Athlete in teamA.matchPlayerNodes:
		var button = Button.new()
		var athleteName = athlete.stats.firstName + " " + athlete.stats.lastName
		button.name = "button " + athleteName
		$ScrollContainer/VBoxContainer.add_child(button)
		button.pressed.connect(_on_player_button_pressed.bind(athlete))

		button.text = athleteName

func _on_player_button_pressed(player:Athlete):
	# Tell us what sort of serve they're going to do
	var serveType:String = "Error"
	var serveAggression:String = "Error"

	#match teamA.data.teamStrategy.servingStrategies

	infoLabel.text = player.stats.firstName + " " + player.stats.lastName + "\n" \
	+ "Is doing a " + serveType + ", " + serveAggression + "\n"\
	+ "Some sort of strategy to be employed"

	pass
