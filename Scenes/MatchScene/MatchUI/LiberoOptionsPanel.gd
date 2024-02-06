extends Node2D

class_name LiberoOptionsPanel

var teamA:Team
@onready var position1Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position1Info
@onready var position2Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position2Info
@onready var position3Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position3Info
@onready var position4Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position4Info
@onready var position5Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position5Info
@onready var position6Info:LiberoOptionsNameCard = $ColourRect/CourtPlayers/Position6Info
@onready var libero1Info:ColorRect = $ColourRect/Libero1Info
@onready var libero2Info:ColorRect = $ColourRect/Libero2Info
@onready var currentRotationLabel:Label = $ColourRect/CurrentRotationLabel

@onready var changePlayerLiberoedOnServePopup:PopupMenu = $ColourRect/PlayerLiberoedOnServeButton/ChangePlayerLiberoedOnServePopupMenu
@onready var changePlayerLiberoedOnReceivePopup:PopupMenu = $ColourRect/PlayerLiberoedOnReceiveButton/ChangePlayerLiberoedOnReceivePopupMenu
@onready var whichLiberoServePopup:PopupMenu = $ColourRect/WhichLiberoServePopupMenu
@onready var whichLiberoReceivePopup:PopupMenu = $ColourRect/WhichLiberoReceivePopupMenu

var athleteToBeLiberoed:Athlete

var liberoOptionsNameCards:Array
#var tempPlayerIndex:int = -
var rotationCurrentlyDisplayed:int = -1

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
	#rotationCurrentlyDisplayed = positionOfOriginalRot1Player
	currentRotationLabel.text = "Rotation " + str(positionOfOriginalRot1Player)
	
	if !teamA:
		Init(get_tree().root.get_node("MatchScene").teamA)
	
	var rotationDifference = teamA.originalRotation1Player.rotationPosition - positionOfOriginalRot1Player
	if rotationDifference < 0:
		rotationDifference = 6 + rotationDifference
	
	var pseudoTeam = PseudoTeam.new()
	pseudoTeam.CopyTeam(teamA)
	
	for i in range(rotationDifference):
		pseudoTeam.PseudoRotate()
	
	
	for lad:Athlete in pseudoTeam.courtPlayers:
		var athleteToDisplay = lad
		if lad == teamA.libero || lad == teamA.libero2:
			if teamA.mManager.isTeamAServing:
				athleteToDisplay = teamA.playerToBeLiberoedOnServe[positionOfOriginalRot1Player - 1][1]
			else:
				athleteToDisplay = teamA.playerToBeLiberoedOnReceive[positionOfOriginalRot1Player - 1][1]

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


func _on_player_liberoed_on_serve_button_pressed():
	changePlayerLiberoedOnServePopup.show()

	changePlayerLiberoedOnServePopup.clear()
	
	changePlayerLiberoedOnServePopup.add_item("None")
	changePlayerLiberoedOnServePopup.add_item(position5Info.athlete.stats.lastName, 5)
	changePlayerLiberoedOnServePopup.add_item(position6Info.athlete.stats.lastName, 6)


func _on_player_liberoed_on_receive_button_pressed():
	changePlayerLiberoedOnReceivePopup.show()
	
	changePlayerLiberoedOnReceivePopup.clear()

	changePlayerLiberoedOnReceivePopup.add_item("None")
	changePlayerLiberoedOnReceivePopup.add_item(position1Info.athlete.stats.lastName,1)
	changePlayerLiberoedOnReceivePopup.add_item(position5Info.athlete.stats.lastName, 5)
	changePlayerLiberoedOnReceivePopup.add_item(position6Info.athlete.stats.lastName, 6)


func _on_change_player_liberoed_on_serve_popup_menu_index_pressed(index):
	if index == 0:
		Console.AddNewLine("No Libero will be used when serving in rotation " + str(rotationCurrentlyDisplayed))
		teamA.playerToBeLiberoedOnServe[rotationCurrentlyDisplayed - 1] = [false, null, null]
		teamA.CheckForLiberoChange()
		DisplayRotation(rotationCurrentlyDisplayed)
		return
		

	var id = changePlayerLiberoedOnServePopup.get_item_id(index)
	Console.AddNewLine("ID: " + str(id))
	

	if id == 5:
		athleteToBeLiberoed = position5Info.athlete
	elif id == 6:
		athleteToBeLiberoed = position6Info.athlete
	if !athleteToBeLiberoed:
		Console.AddNewLine("ERROR! No athlete to be liberoed")
		return
		
	if teamA.libero2:
		whichLiberoServePopup.show()
	
	else:
		teamA.playerToBeLiberoedOnServe[rotationCurrentlyDisplayed - 1][0] = true
		teamA.playerToBeLiberoedOnServe[rotationCurrentlyDisplayed - 1][1] = athleteToBeLiberoed
		teamA.playerToBeLiberoedOnServe[rotationCurrentlyDisplayed - 1][2] = teamA.libero
		
		teamA.CheckForLiberoChange()
		DisplayRotation(rotationCurrentlyDisplayed)


func _on_change_player_liberoed_on_receive_popup_menu_index_pressed(index):
	if index == 0:
		Console.AddNewLine("No Libero will be used when receiving in rotation " + str(rotationCurrentlyDisplayed))
		teamA.playerToBeLiberoedOnReceive[rotationCurrentlyDisplayed - 1] = [false, null, null]
		teamA.CheckForLiberoChange()
		DisplayRotation(rotationCurrentlyDisplayed)
		return


	var id = changePlayerLiberoedOnReceivePopup.get_item_id(index)
	Console.AddNewLine("ID: " + str(id))
	

	if id == 5:
		athleteToBeLiberoed = position5Info.athlete
	elif id == 6:
		athleteToBeLiberoed = position6Info.athlete
	elif id == 1:
		athleteToBeLiberoed = position1Info.athlete
		
	if ! athleteToBeLiberoed:
		Console.AddNewLine("ERROR! No athlete to be liberoed")
		return
		
	if teamA.libero2:
		whichLiberoReceivePopup.show()

	else:
		teamA.playerToBeLiberoedOnReceive[rotationCurrentlyDisplayed - 1][0] = true
		teamA.playerToBeLiberoedOnReceive[rotationCurrentlyDisplayed - 1][1] = athleteToBeLiberoed
		teamA.playerToBeLiberoedOnReceive[rotationCurrentlyDisplayed - 1][2] = teamA.libero
		
		teamA.CheckForLiberoChange()
		DisplayRotation(rotationCurrentlyDisplayed)

#func _on_which_libero_popup_menu_index_pressed(index):


func _on_which_libero_serve_popup_menu_index_pressed(index):
	var newLibero
	if index == 0:
		newLibero = teamA.libero
	elif index == 1:
		newLibero = teamA.libero2
	else:
		Console.AddNewLine("ERROR! Index libero mismatch")
		return
	
	teamA.playerToBeLiberoedOnServe[rotationCurrentlyDisplayed - 1] = [true, athleteToBeLiberoed, newLibero]
	
	teamA.CheckForLiberoChange()
	DisplayRotation(rotationCurrentlyDisplayed)
	athleteToBeLiberoed = null


func _on_which_libero_receive_popup_menu_index_pressed(index):
	var newLibero
	if index == 0:
		newLibero = teamA.libero
	elif index == 1:
		newLibero = teamA.libero2
	else:
		Console.AddNewLine("ERROR! Index libero mismatch")
		return
	
	teamA.playerToBeLiberoedOnReceive[rotationCurrentlyDisplayed - 1] = [true, athleteToBeLiberoed, newLibero]
	
	teamA.CheckForLiberoChange()
	DisplayRotation(rotationCurrentlyDisplayed)
	athleteToBeLiberoed = null
