extends Node2D

class_name LiberoOptionsPanel

var teamA:Team
@onready var position1Info = $ColourRect/CourtPlayers/Position1Info
@onready var position2Info = $ColourRect/CourtPlayers/Position2Info
@onready var position3Info = $ColourRect/CourtPlayers/Position3Info
@onready var position4Info = $ColourRect/CourtPlayers/Position4Info
@onready var position5Info = $ColourRect/CourtPlayers/Position5Info
@onready var position6Info = $ColourRect/CourtPlayers/Position6Info

var liberoOptionsNameCards:Array

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
		if lad.pseudoRotationPosition == 1:
			position1Info.DisplayAthlete(lad)
		if lad.pseudoRotationPosition == 2:
			position2Info.DisplayAthlete(lad)
		if lad.pseudoRotationPosition == 3:
			position3Info.DisplayAthlete(lad)
		if lad.pseudoRotationPosition == 4:
			position4Info.DisplayAthlete(lad)
		if lad.pseudoRotationPosition == 5:
			position5Info.DisplayAthlete(lad)
		if lad.pseudoRotationPosition == 6:
			position6Info.DisplayAthlete(lad)
			
	if teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player][0]:
		var playerToLibero = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player][1]
		var liberoUsed = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player][2]
		for card:LiberoOptionsNameCard in liberoOptionsNameCards:
			if card.athlete == playerToLibero:
				card.CardAthleteWillBeLiberoedOnServe(liberoUsed)

	if teamA.playerToBeLiberoedOnReceive[positionOfOriginalRot1Player][0]:
		var playerToLibero = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player][1]
		var liberoUsed = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player][2]
		for card:LiberoOptionsNameCard in liberoOptionsNameCards:
			if card.athlete == playerToLibero:
				card.CardAthleteWillBeLiberoedOnReceive(liberoUsed)
			
			
	pseudoTeam.free()
