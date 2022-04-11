extends "res://Scripts/State/Team/TeamState.gd"


var otherTeam:Team
var leftSideBlocker
var rightSideBlocker

func Enter(team:Team):
	for player in team.courtPlayers:
#		print(player.stats.lastName)
		if player.rb.mode != RigidBody.MODE_RIGID:
#			print(player.stats.lastName + "Changing")
			if player.FrontCourt():
				player.stateMachine.SetCurrentState(player.blockState)
			else:
				player.stateMachine.SetCurrentState(player.defendState)
	
	CacheBlockers(team)
	
	if team.setter.FrontCourt():
		team.setter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
#		team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(5.5, 0, -2.2))
		team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
	else:
		if team.markUndoChangesToRoles:
			team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, 3))
			team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
		else:
			team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, 3))
			team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))

#		team.setter.moveTarget = team.CheckIfFlipped(Vector3(5.5, 0, 2.2))



	if otherTeam.markUndoChangesToRoles:
		leftSideBlocker.blockState.blockingTarget = otherTeam.outsideFront
		rightSideBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
	else:
		leftSideBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
		rightSideBlocker.blockState.blockingTarget = otherTeam.outsideFront


	team.middleFront.blockState.blockingTarget = otherTeam.middleFront

#	foreach athlete in team.courtPlayers:
#		if (athlete != GetServer())
#			athlete.PrepareToDefend()
	
func Update(team:Team):
	pass
func Exit(team:Team):
	pass

func CacheBlockers(team:Team):
	if team.setter.FrontCourt():
		rightSideBlocker = team.setter
		leftSideBlocker = team.outsideFront
	else:
		if team.markUndoChangesToRoles:
			rightSideBlocker = team.outsideFront
			leftSideBlocker = team.oppositeHitter
		else:
			rightSideBlocker = team.oppositeHitter
			leftSideBlocker = team.outsideFront
