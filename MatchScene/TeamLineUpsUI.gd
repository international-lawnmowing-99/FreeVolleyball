extends ColorRect

var nameCards:Array

func _ready() -> void:
	for card in $OppositionTeam.get_children():
		nameCards.append(card)
	for card in $HumanTeam.get_children():
		nameCards.append(card)
	
	for card in nameCards:
		card.DisplayEssentials()
