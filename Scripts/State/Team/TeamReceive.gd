extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamReceive

func Enter(team:Team):
	nameOfState = "Receive"
	#ChooseReceiver
		
	for lad in team.courtPlayers:
		lad.distanceHack = team.ball.attackTarget.distance_squared_to(lad.position)
		if !lad.rb.freeze:
			lad.distanceHack = 9999
		if lad == team.setter:
			lad.distanceHack*=3

	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))
	
	team.chosenReceiver = orderedList[0]

	# Begin transitions
	var middleChoice:int = randi()%3
	match middleChoice:
		0:
			team.middleFront.setRequest = team.middleFront.middleSpikes[0].Duplicate()
		1:
			team.middleFront.setRequest = team.middleFront.middleSpikes[1].Duplicate()
		2:
			team.middleFront.setRequest = team.middleFront.middleSpikes[2].Duplicate()

	team.outsideBack.setRequest =  team.outsideBack.outsideBackSpikes[0].Duplicate()
	if team.oppositeHitter.FrontCourt():
		team.setter.setRequest = team.setter.oppositeBackSpikes[0].Duplicate()
		if team.markUndoChangesToRoles:
			team.oppositeHitter.setRequest = team.oppositeHitter.outsideFrontSpikes[0].Duplicate()
			team.outsideFront.setRequest = team.outsideFront.oppositeFrontSpikes[0].Duplicate()
	
		else:
			team.oppositeHitter.setRequest =  team.oppositeHitter.oppositeFrontSpikes[0].Duplicate()
			team.outsideFront.setRequest = team.outsideFront.outsideFrontSpikes[0].Duplicate()
	else:
		team.oppositeHitter.setRequest =  team.oppositeHitter.oppositeBackSpikes[0].Duplicate()
		team.outsideFront.setRequest = team.outsideFront.outsideFrontSpikes[0].Duplicate()

		team.setter.setRequest = team.setter.oppositeFrontSpikes[0].Duplicate()

	for i in range(1, team.courtPlayers.size()):
		#print(team.courtPlayers[i].stats.lastName)
		if team.courtPlayers[i].rb.freeze:
			#print(team.courtPlayers[i].stats.lastName + " transitnio")
			team.courtPlayers[i].stateMachine.SetCurrentState(team.courtPlayers[i].transitionState)
		
	team.chosenReceiver.stateMachine.SetCurrentState(team.chosenReceiver.passState)
#	Console.AddNewLine("Outside front spike[0] = " + str(team.outsideFront.outsideFrontSpikes[0].target))
	
func Update(_team:Team):
	#Is the ball close enough
	pass
func Exit(team:Team):
	#Discard receiver info?
	team.UpdateTimeTillDigTarget()
	pass

#func CheckForFlip(_set:Set, team:Team):
#		var s = Set.new(team.flip* _set.target.x, _set.target.y, team.flip * _set.target.z, _set.height)
#		return s
