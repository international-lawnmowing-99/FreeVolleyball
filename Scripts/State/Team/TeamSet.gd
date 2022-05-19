extends "res://Scripts/State/Team/TeamState.gd"
const enums = preload("res://Scripts/World/Enums.gd")

func Enter(team:Team):
	#ChooseSetter
	
	#can the setter/lib get there???
	
	if team.chosenReceiver.role == enums.Role.Setter:
		if team.isLiberoOnCourt:
			team.libero.stateMachine.SetCurrentState(team.libero.setState)
			team.chosenSetter = team.libero
		else:
			team.middleBack.stateMachine.SetCurrentState(team.middleBack.setState)
			team.chosenSetter = team.middleBack
	else:
		team.setter.stateMachine.SetCurrentState(team.setter.setState)
		team.chosenSetter = team.setter
	
	
	
	# Choose to attack on 2nd??
	if team.chosenSetter.FrontCourt():
		var dump = bool(randi()%2)
		if dump:
			Console.AddNewLine("Dumping", Color.white)

	#Can the spiker get back to their runup and if not, how will that affect their spike?
	var possibleSpikers = []
	
	for athlete in team.courtPlayers:
		if athlete!= team.chosenSetter && athlete != team.chosenReceiver && athlete.rb.mode != RigidBody.MODE_RIGID:
			athlete.stateMachine.SetCurrentState(athlete.transitionState)
			possibleSpikers.append(athlete)
			
	Console.AddNewLine("Choosing set option...")

	var setChoice = randi()%possibleSpikers.size()
	
	team.chosenSpiker = possibleSpikers[setChoice]
	
	match team.chosenSpiker.role:
		Enums.Role.Middle:
			team.setTarget = team.chosenSpiker.middleSpikes[0]
		Enums.Role.Outside:
			if team.chosenSpiker.FrontCourt():
				team.setTarget = team.chosenSpiker.outsideFrontSpikes[0]
			else:
				team.setTarget = team.chosenSpiker.outsideBackSpikes[0]
		Enums.Role.Opposite:
			if team.chosenSpiker.FrontCourt():
				team.setTarget = team.chosenSpiker.oppositeFrontSpikes[0]
			else:
				team.setTarget = team.chosenSpiker.oppositeBackSpikes[0]
	team.chosenSpiker.setRequest = team.setTarget
func Update(team:Team):
	team.UpdateTimeTillDigTarget()
	
	#Is the ball close enough
	if team.ball.translation.y <= team.receptionTarget.y && team.ball.linear_velocity.y < 0 && \
		Vector3(team.chosenSetter.translation.x, team.chosenSetter.stats.setHeight, team.chosenSetter.translation.z).distance_squared_to(team.ball.translation) < 1:
			SetBall(team)
	#CheckForSpikeDistance(team)
	pass
func Exit(team:Team):
	pass


func SetBall(team:Team):
	
	# mint set, poor set (short, long, mis-timed, tight, over, or some combo thereof - so many ways to set poorly!), 2 hits/carry ("setting error")
	randomize()
	var setExecution = randi()%3
	
	if setExecution == 0:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " lip-smacking set", Color.darkorchid)
	elif setExecution == 1:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " shitty set", Color.red)
	elif setExecution == 2:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " setting error", Color.blue)
		
	if !team.setTarget:
		#setTarget = Set(-4.5, 0, 0, randf() * 6 + 2.5)
		#ball.attackTarget = setTarget.target
		#team.ball.linear_velocity = team.ball.CalculateWellBehavedParabola(team.ball.translation, setTarget.target, setTarget.height)
		#BallOverNet()

		team.chosenSetter.setState.WaitThenDefend(team.chosenSetter, 0.5)
		team.chosenSetter = null
		if (team.markUndoChangesToRoles):
			team.setTarget = team.oppositeHitter.outsideFrontSpikes[0]

			team.chosenSpiker = team.oppositeHitter
		else:
			team.setTarget = team.outsideFront.outsideFrontSpikes[0]
			team.chosenSpiker = team.outsideFront
		
		team.chosenSpiker = team.middleFront
		team.setTarget = team.middleFront.middleSpikes[0]
		

		#CalculateSetDifficulty()

	team.ball.linear_velocity = team.ball.FindWellBehavedParabola(team.ball.translation, team.setTarget.target, team.setTarget.height)
	yield(team.get_tree(), "idle_frame")
	team.ball.linear_velocity = team.ball.FindWellBehavedParabola(team.ball.translation, team.setTarget.target, team.setTarget.height)
	
	
	
	#team.setTarget = null
	

	
	team.get_tree().get_root().get_node("MatchScene").BallSet(team.isHuman)


func CheckForSpikeDistance(team:Team):
	if !team.chosenSpiker:
		print("Error inbound")
		#Log(setTarget.target)
	if team.ball.translation.y <= team.setTarget.y \
	&& abs(team.ball.translation.z) >= abs(team.setTarget.z) && team.ball.linear_velocity.y <= 0:
		team.stateMachine.SetCurrentState(team.spikeState)
