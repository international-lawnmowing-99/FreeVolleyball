extends ColorRect

class_name LiberoOptionsNameCard

var athlete:Athlete
@onready var playerLabel:Label = $PlayerLabel
@onready var serveStatusLabel:Label = $ServeStatusLabel
@onready var receiveStatusLabel:Label = $ReceiveStatusLabel
@onready var positionLabel:Label = $PositionLabel

func DisplayAthlete(_athlete:Athlete):
	athlete = _athlete
	playerLabel.text = athlete.stats.lastName + " (" + Enums.Role.keys()[athlete.role] + ")"
	receiveStatusLabel.text = "On court for receive"
	serveStatusLabel.text = "On court for serve"
	
func CardAthleteWillBeLiberoedOnReceive(libero:Athlete):
	receiveStatusLabel.text = libero.stats.lastName + " will substitute on receive"
func CardAthleteWillBeLiberoedOnServe(libero:Athlete):
	serveStatusLabel.text = libero.stats.lastName + " will substitute on serve"
