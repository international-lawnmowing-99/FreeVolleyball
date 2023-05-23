extends Control
class_name ReceiveOptionsUI

@onready var courtRepresentationReceive = $CourtRepresentationUI
var teamA:Team
var teamB:Team

func _on_rot_1_button_pressed():
	DisplayRotation(1)


func _on_rot_2_button_pressed():
	DisplayRotation(2)


func _on_rot_3_button_pressed():
	DisplayRotation(3)


func _on_rot_4_button_pressed():
	DisplayRotation(4)


func _on_rot_5_button_pressed():
	DisplayRotation(5)


func _on_rot_6_button_pressed():
	DisplayRotation(6)

func DisplayRotation(positionOfOriginalRot1Player:int):
	var rotationDifference = teamA.originalRotation1Player.rotationPosition - positionOfOriginalRot1Player
	if rotationDifference < 0:
		rotationDifference = 6 + rotationDifference
	
	var pseudoTeam = PseudoTeam.new()
	pseudoTeam.CopyTeam(teamA)
	
	for i in range(rotationDifference):
		pseudoTeam.PseudoRotate()
		
	
	var i = 0
	for athlete in pseudoTeam.courtPlayers:
		var rect = $CourtRepresentationUI/OurTeam/UnscaledOurTeam.get_child(i)
		var pos = teamA.defaultReceiveRotations[pseudoTeam.server][athlete.pseudoRotationPosition - 1]
		rect.get_node("Name").text = athlete.stats.lastName + ": " + str(athlete.pseudoRotationPosition)
		rect.position.x = 428/-9 * pos.z
		rect.position.y = 428/9 * pos.x
		i += 1

