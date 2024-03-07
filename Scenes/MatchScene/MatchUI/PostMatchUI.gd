extends Control
class_name PostMatchUI

@onready var winnerLabel:Label = $ColourRect/VBoxContainer/WinnerLabel
@onready var setScoreLabel:Label = $ColourRect/VBoxContainer/SetScoreLabel
@onready var pointScoresLabel:Label = $ColourRect/VBoxContainer/PointScoresLabel

#func _ready():

	
func Show(score:Score):
	visible = true
	winnerLabel.text = score.teamANameText.text + " Won!"
	if score.teamASetScore > score.teamBSetScore:
		setScoreLabel.text = str(score.teamASetScore) + ":" + str(score.teamBSetScore)
		pointScoresLabel.text = ""
		for i in range(score.teamAPreviousScores.size()):
			pointScoresLabel.text += str(score.teamAPreviousScores[i]) + ":" + str(score.teamBPreviousScores[i])
			if i != score.teamAPreviousScores.size() - 1:
				pointScoresLabel.text += ", "

	elif score.teamBScore > score.teamAScore:
		setScoreLabel.text = str(score.teamBScore) + ":" + str(score.teamAScore)
