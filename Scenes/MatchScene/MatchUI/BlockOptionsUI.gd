extends Control
class_name BlockOptionsUI

var teamA:Team
var teamB:Team

var servingSelected:bool = true
@onready var displayedRotationLabel = $DisplayedRotationLabel

func UpdateBlockers(team:Team, otherTeam:Team):
	team.defendState.CacheBlockers(team)
	$Blockers/LeftBlockerUI.Populate("Left Blocker", false, team.defendState.leftSideBlocker, otherTeam)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", false, team.middleFront, otherTeam)
	$Blockers/RightBlockerUI.Populate("Right Blocker", false, team.defendState.rightSideBlocker, otherTeam)
	pass


func _on_rot_1_button_pressed():
	DisplayRotation(1)
	displayedRotationLabel.text = "Rotation 1"

func _on_rot_2_button_pressed():
	DisplayRotation(2)
	displayedRotationLabel.text = "Rotation 2"

func _on_rot_3_button_pressed():
	DisplayRotation(3)
	displayedRotationLabel.text = "Rotation 3"

func _on_rot_4_button_pressed():
	DisplayRotation(4)
	displayedRotationLabel.text = "Rotation 4"

func _on_rot_5_button_pressed():
	DisplayRotation(5)
	displayedRotationLabel.text = "Rotation 5"

func _on_rot_6_button_pressed():
	DisplayRotation(6)
	displayedRotationLabel.text = "Rotation 6"

func DisplayRotation(positionOfOriginalRot1Player:int):
	var rotationDifference = teamA.originalRotation1Player.rotationPosition - positionOfOriginalRot1Player
	if rotationDifference < 0:
		rotationDifference = 6 + rotationDifference

	var pseudoTeam = PseudoTeam.new()
	pseudoTeam.CopyTeam(teamA)

	for i in range(rotationDifference):
		pseudoTeam.PseudoRotate()

	pseudoTeam.CachePlayers()
	pseudoTeam.PseudoCacheBlockers(servingSelected)
	$Blockers/LeftBlockerUI.Populate("Left Blocker", true, pseudoTeam.pseudoLeftBlocker, teamB)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", true, pseudoTeam.pseudoMiddleBlocker, teamB)
	$Blockers/RightBlockerUI.Populate("Right Blocker", true, pseudoTeam.pseudoRightBlocker, teamB)


func _on_current_rotation_button_pressed():
	DisplayRotation(teamA.originalRotation1Player.rotationPosition)
	displayedRotationLabel.text = "Rotation " + str(teamA.originalRotation1Player.rotationPosition)


func _on_serve_receive_option_button_item_selected(index):
	if index == 0:
		#Receiving
		pass
	elif index == 1:
		#Serving

		pass
