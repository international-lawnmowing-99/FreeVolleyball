class_name ServeOptionsUI

extends Control
var teamA
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

func _on_player_button_pressed(player):
	# Tell us what sort of serve they're going to do
	pass
