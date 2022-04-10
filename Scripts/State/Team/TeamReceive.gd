extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	#ChooseReceiver
		
	for lad in team.courtPlayers:
		lad.distanceHack = team.ball.attackTarget.distance_squared_to(lad.translation)
		if lad.rb.mode == RigidBody.MODE_RIGID:
			lad.distanceHack = 9999
			
	team.courtPlayers.sort_custom(Athlete, "SortDistance")
	var orderedList = team.courtPlayers.duplicate(false)
	
	team.chosenReceiver = orderedList[0]

	team.middleFront.setRequest = CheckForFlip(team.middleFront.middleSpikes[0], team)
	team.outsideBack.setRequest =  CheckForFlip(team.outsideBack.outsideBackSpikes[0], team)
	if team.oppositeHitter.FrontCourt():
		if team.markUndoChangesToRoles:
			team.oppositeHitter.setRequest = CheckForFlip(team.oppositeHitter.outsideFrontSpikes[0], team)
			team.outsideFront.setRequest = CheckForFlip(team.outsideFront.oppositeFrontSpikes[0], team)
	
		else:
			team.oppositeHitter.setRequest =  CheckForFlip(team.oppositeHitter.oppositeFrontSpikes[0], team)
			team.outsideFront.setRequest = CheckForFlip(team.outsideFront.outsideFrontSpikes[0], team)
	else:
		team.oppositeHitter.setRequest =  CheckForFlip(team.oppositeHitter.oppositeBackSpikes[0], team)
		team.outsideFront.setRequest = CheckForFlip(team.outsideFront.outsideFrontSpikes[0], team)

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
