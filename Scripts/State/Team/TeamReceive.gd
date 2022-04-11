extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	#ChooseReceiver
		
	for lad in team.courtPlayers:
		lad.distanceHack = team.ball.attackTarget.distance_squared_to(lad.translation)
		if lad.rb.mode == RigidBody.MODE_RIGID:
			lad.distanceHack = 9999
		if lad == team.setter:
			lad.distanceHack*=3
	team.courtPlayers.sort_custom(Athlete, "SortDistance")
	var orderedList = team.courtPlayers.duplicate(false)
	
	team.chosenReceiver = orderedList[0]

	team.middleFront.setRequest = team.middleFront.middleSpikes[0]
	team.outsideBack.setRequest =  team.outsideBack.outsideBackSpikes[0]
	if team.oppositeHitter.FrontCourt():
		if team.markUndoChangesToRoles:
			team.oppositeHitter.setRequest = team.oppositeHitter.outsideFrontSpikes[0]
			team.outsideFront.setRequest = team.outsideFront.oppositeFrontSpikes[0]
	
		else:
			team.oppositeHitter.setRequest =  team.oppositeHitter.oppositeFrontSpikes[0]
			team.outsideFront.setRequest = team.outsideFront.outsideFrontSpikes[0]
	else:
		team.oppositeHitter.setRequest =  team.oppositeHitter.oppositeBackSpikes[0]
		team.outsideFront.setRequest = team.outsideFront.outsideFrontSpikes[0]

	for i in range(1, team.courtPlayers.size()):
		#print(team.courtPlayers[i].stats.lastName)
		if team.courtPlayers[i].rb.mode != RigidBody.MODE_RIGID:
			#print(team.courtPlayers[i].stats.lastName + " transitnio")
			team.courtPlayers[i].stateMachine.SetCurrentState(team.courtPlayers[i].transitionState)
		
	team.chosenReceiver.stateMachine.SetCurrentState(team.chosenReceiver.passState)

	
func Update(team:Team):
	#Is the ball close enough
	pass
func Exit(team:Team):
	#Discard receiver info?
	team.UpdateTimeTillDigTarget()
	pass

func CheckForFlip(set:Set, team:Team):
		var s = Set.new(team.flip* set.target.x, set.target.y, team.flip * set.target.z, set.height)
		return s
