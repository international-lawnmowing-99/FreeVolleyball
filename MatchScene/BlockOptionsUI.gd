extends Control
class_name BlockOptionsUI

var teamA:Team
var teamB:Team

func UpdateBlockers(team:Team, otherTeam:Team):
	team.defendState.CacheBlockers(team)
	$Blockers/LeftBlockerUI.Populate("Left Blocker", team.defendState.leftSideBlocker, otherTeam)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", team.middleFront, otherTeam)
	$Blockers/RightBlockerUI.Populate("Right Blocker", team.defendState.rightSideBlocker, otherTeam)
	pass


func _on_rot_1_button_pressed():
	# need to get the current court playerz
	# deep copy them so they don't actually rotate on court
	# then rotate the copy till it aligns to rot 1
	var duplicateTeam:Team = teamA.duplicate(true)
	var setterRotationPosition = duplicateTeam.setter.rotationPosition
	var rotationDifference = setterRotationPosition - 1
	
	for i in range(6 - rotationDifference):
		duplicateTeam.Rotate()
		pass # Replace with function body.
	
	# now, find the original players
	duplicateTeam.defendState.CacheBlockers(duplicateTeam)
	var realCopyOfLeftBlocker:Athlete
	var realCopyOfMiddleBlocker:Athlete
	var realCopyOfRightBlocker:Athlete
	
	for player in teamA.allPlayers:
		# it's very unlikely that you'd have a collision, but with the ability for players to rename players
		# so that they have the same names it makes sense to put in a 
		# UNIQUE ID at some point
		if duplicateTeam.defendState.leftBlocker.stats.firstName == player.stats.firstName && \
		duplicateTeam.defendState.leftBlocker.stats.lastName == player.stats.lastName:
			realCopyOfLeftBlocker = player
			
		elif duplicateTeam.middleBlocker.stats.firstName == player.stats.firstName && \
		duplicateTeam.middleBlocker.stats.lastName == player.stats.lastName:
			realCopyOfMiddleBlocker = player
			
		elif duplicateTeam.defendState.rightBlocker.stats.firstName == player.stats.firstName && \
		duplicateTeam.defendState.rightBlocker.stats.lastName == player.stats.lastName:
			realCopyOfRightBlocker = player
	
	$Blockers/LeftBlockerUI.Populate("Left Blocker", realCopyOfLeftBlocker, teamB)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", realCopyOfMiddleBlocker, teamB)
	$Blockers/RightBlockerUI.Populate("Right Blocker", realCopyOfRightBlocker, teamB)

func _on_rot_2_button_pressed():
	pass # Replace with function body.


func _on_rot_3_button_pressed():
	pass # Replace with function body.


func _on_rot_4_button_pressed():
	pass # Replace with function body.


func _on_rot_5_button_pressed():
	pass # Replace with function body.


func _on_rot_6_button_pressed():
	pass # Replace with function body.
