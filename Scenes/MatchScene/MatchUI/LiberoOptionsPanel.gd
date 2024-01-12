extends Node2D

class_name LiberoOptionsPanel

var teamA:Team
@onready var position1Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position1Info
@onready var position2Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position2Info
@onready var position3Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position3Info
@onready var position4Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position4Info
@onready var position5Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position5Info
@onready var position6Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position6Info
@onready var libero2Info:ColorRect = $ColourRect/Libero2Info
@onready var currentRotationLabel:Label = $ColourRect/CurrentRotationLabel

var liberoOptionsNameCards:Array

func _ready():
	position1Info.positionLabel.text = "Position 1"
	position2Info.positionLabel.text = "Position 2"
	position3Info.positionLabel.text = "Position 3"
	position4Info.positionLabel.text = "Position 4"
	position5Info.positionLabel.text = "Position 5"
	position6Info.positionLabel.text = "Position 6"
	
	liberoOptionsNameCards.append(position1Info)
	liberoOptionsNameCards.append(position2Info)
	liberoOptionsNameCards.append(position3Info)
	liberoOptionsNameCards.append(position4Info)
	liberoOptionsNameCards.append(position5Info)
	liberoOptionsNameCards.append(position6Info)
	
func Init(_teamA:Team):
	teamA = _teamA
	
	$ColourRect/Libero1Info/Label.text = "Libero 1: " + teamA.libero.stats.lastName
	if teamA.libero2:
		libero2Info.visible = true
		libero2Info.get_node("Label").text = "Libero 2: " + teamA.libero2.stats.lastName
	
	var currentRotation = teamA.originalRotation1Player.rotationPosition



func _on_rotation_1_pressed():
	DisplayRotation(1)


func _on_rotation_2_pressed():
	DisplayRotation(2)


func _on_rotation_3_pressed():
	DisplayRotation(3)


func _on_rotation_4_pressed():
	DisplayRotation(4)


func _on_rotation_5_pressed():
	DisplayRotation(5)


func _on_rotation_6_pressed():
	DisplayRotation(6)


func DisplayRotation(positionOfOriginalRot1Player:int):
	currentRotationLabel.text = "Rotation " + str(positionOfOriginalRot1Player)
	
	if !teamA:
		teamA = get_tree().root.get_node("MatchScene").teamA
	
	var rotationDifference = teamA.originalRotation1Player.rotationPosition - positionOfOriginalRot1Player
	if rotationDifference < 0:
		rotationDifference = 6 + rotationDifference
	
	var pseudoTeam = PseudoTeam.new()
	pseudoTeam.CopyTeam(teamA)
	
	for i in range(rotationDifference):
		pseudoTeam.PseudoRotate()
	
	
	for lad:Athlete in pseudoTeam.courtPlayers:
		var athleteToDisplay = lad
		if lad == teamA.libero:
			athleteToDisplay = teamA.benchPlayers[0]
			
		if lad.pseudoRotationPosition == 1:
			position1Info.DisplayAthlete(athleteToDisplay)
		if lad.pseudoRotationPosition == 2:
			position2Info.DisplayAthlete(athleteToDisplay)
		if lad.pseudoRotationPosition == 3:
			position3Info.DisplayAthlete(athleteToDisplay)
		if lad.pseudoRotationPosition == 4:
			position4Info.DisplayAthlete(athleteToDisplay)
		if lad.pseudoRotationPosition == 5:
			position5Info.DisplayAthlete(athleteToDisplay)
		if lad.pseudoRotationPosition == 6:
			position6Info.DisplayAthlete(athleteToDisplay)
			
	if teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player-1][0]:
		var playerToLibero = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player - 1][1]
		var liberoUsed = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player - 1][2]
		for card:LiberoOptionsNameCard in liberoOptionsNameCards:
			if card.athlete == playerToLibero:
				card.CardAthleteWillBeLiberoedOnServe(liberoUsed)

	if teamA.playerToBeLiberoedOnReceive[positionOfOriginalRot1Player-1][0]:
		var playerToLibero = teamA.playerToBeLiberoedOnReceive[positionOfOriginalRot1Player - 1][1]
		var liberoUsed = teamA.playerToBeLiberoedOnReceive[positionOfOriginalRot1Player - 1][2]
		for card:LiberoOptionsNameCard in liberoOptionsNameCards:
			if card.athlete == playerToLibero:
				card.CardAthleteWillBeLiberoedOnReceive(liberoUsed)
			
			
	pseudoTeam.free()
