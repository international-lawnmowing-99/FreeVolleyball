extends Control
class_name BlockOptionsUI

var teamA:Team
var teamB:Team

var servingSelected:bool = true


func UpdateBlockers(team:Team, otherTeam:Team):
	team.defendState.CacheBlockers(team)
	$Blockers/LeftBlockerUI.Populate("Left Blocker", false, team.defendState.leftSideBlocker, otherTeam)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", false, team.middleFront, otherTeam)
	$Blockers/RightBlockerUI.Populate("Right Blocker", false, team.defendState.rightSideBlocker, otherTeam)
	pass


func _on_rot_1_button_pressed():
	DisplayRotaion(1)


func _on_rot_2_button_pressed():
	DisplayRotaion(2)

func _on_rot_3_button_pressed():
	DisplayRotaion(3)


func _on_rot_4_button_pressed():
	DisplayRotaion(4)


func _on_rot_5_button_pressed():
	DisplayRotaion(5)

func _on_rot_6_button_pressed():
	DisplayRotaion(6)
	
func DisplayRotaion(positionOfOriginalRot1Player:int):
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
