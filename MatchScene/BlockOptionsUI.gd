extends Control
class_name BlockOptionsUI

func UpdateBlockers(team:Team, otherTeam:Team):
	team.defendState.CacheBlockers(team)
	$Blockers/LeftBlockerUI.Populate("Left Blocker", team.defendState.leftSideBlocker, otherTeam)
	$Blockers/MiddleBlockerUI.Populate("Middle Blocker", team.middleFront, otherTeam)
	$Blockers/RightBlockerUI.Populate("Right Blocker", team.defendState.rightSideBlocker, otherTeam)
	pass
