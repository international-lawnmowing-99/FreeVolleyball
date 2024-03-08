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
		winnerLabel.text = score.teamANameText.text + " Won!"
		setScoreLabel.text = str(score.teamASetScore) + ":" + str(score.teamBSetScore)
		pointScoresLabel.text = ""
		for i in range(score.teamAPreviousScores.size()):
			pointScoresLabel.text += str(score.teamAPreviousScores[i]) + ":" + str(score.teamBPreviousScores[i])
			if i != score.teamAPreviousScores.size() - 1:
				pointScoresLabel.text += ", "

	elif score.teamBSetScore > score.teamASetScore:
		winnerLabel.text = score.teamBNameText.text + " Won!"
		setScoreLabel.text = str(score.teamBSetScore) + ":" + str(score.teamASetScore)
		pointScoresLabel.text = ""
		for i in range(score.teamAPreviousScores.size()):
			pointScoresLabel.text += str(score.teamBPreviousScores[i]) + ":" + str(score.teamAPreviousScores[i])
			if i != score.teamAPreviousScores.size() - 1:
				pointScoresLabel.text += ", "
	else:
		winnerLabel.text = "Set score equal, this shouldn't happen!"
		setScoreLabel.text = "ERROR"
		pointScoresLabel.text = "ERROR"
