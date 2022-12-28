extends "res://Scripts/State/Team/TeamState.gd"
const enums = preload("res://Scripts/World/Enums.gd")

#can also potentially spike, dogshot
var ballWillBeDumped:bool = false

func Enter(team:Team):
	ballWillBeDumped = false
	
	ChooseSetter(team)

	

	
	
	# Choose to attack on 2nd??
	if team.chosenSetter && team.chosenSetter.FrontCourt():
		var dump = bool(randi()%2)
		if dump && abs(team.receptionTarget.x) < 2:
			Console.AddNewLine("!!!!Dumping!!!!!", Color.darkred)
			ballWillBeDumped = true
			return


	#Can the spiker get back to their runup and if not, how will that affect their spike?
	var possibleSpikers = []
	
	for athlete in team.courtPlayers:
		if athlete!= team.chosenSetter && athlete != team.chosenReceiver && athlete.rb.mode != RigidBody.MODE_RIGID && athlete.role != enums.Role.Libero:
			athlete.stateMachine.SetCurrentState(athlete.transitionState)
			possibleSpikers.append(athlete)
			
	Console.AddNewLine("Choosing set option...")
	if possibleSpikers.size() <= 0:
		#Got to dump
		#This happens when everyone's in the air and the back outside receives presumably so intensively that it takes them out of the attack - will eventually test 
		#if there's enough time for the spiker to do a full runup, and penalise their desirability as an option for the ai if they can't make it all the way back and 
		#have to hop on the spot. 
		#The choice of who to set could be moved to the actual point at which the set occurs??
		pass

	var setChoice = randi()%possibleSpikers.size()
	
	team.chosenSpiker = possibleSpikers[setChoice]
	
	match team.chosenSpiker.role:
		Enums.Role.Middle:
			var randint:int = randi()%3
			match randint:
				0:
					team.setTarget = team.chosenSpiker.middleSpikes[0]
				1:
					team.setTarget = team.chosenSpiker.middleSpikes[1]
				2:
					team.setTarget = team.chosenSpiker.middleSpikes[2]
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
		Vector3(team.chosenSetter.translation.x, team.chosenSetter.stats.standingSetHeight, team.chosenSetter.translation.z).distance_squared_to(team.ball.translation) < 1:
			if ballWillBeDumped:
				DumpBall(team)
			else:
				SetBall(team)
	#CheckForSpikeDistance(team)
	pass
func Exit(team:Team):
	pass

func DumpBall(team:Team):
	team.ball.attackTarget = team.CheckIfFlipped(Vector3(rand_range(-1, -4.5), 0, -4.5 + rand_range(0, 9)))
	team.ball.difficultyOfReception = rand_range(0, team.chosenSetter.stats.dump)
	team.ball.linear_velocity = team.ball.FindParabolaForGivenSpeed(team.ball.translation, team.ball.attackTarget, rand_range(5,10), false)
	if team.ball.FindNetPass().y <= 2.5:
		team.ball.linear_velocity = team.ball.CalculateBallOverNetVelocity(team.ball.translation, team.ball.attackTarget, 2.5)
	team.mManager.BallOverNet(team.isHuman)
	
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

func ChooseSetter(team:Team):
	var timeTillBallAtReceptionTarget = TimeToBallAtReceptionTarget(team.ball, team.receptionTarget)
	# Who will set?
	# Who will hit?
	# Who is out of the picture and will sit around looking pretty?
	
	
	
	
#	if team.chosenReceiver.role == enums.Role.Setter:
#		if team.isLiberoOnCourt:
#			team.libero.stateMachine.SetCurrentState(team.libero.setState)
#			team.chosenSetter = team.libero
#		else:
#			team.middleBack.stateMachine.SetCurrentState(team.middleBack.setState)
#			team.chosenSetter = team.middleBack
#	else:
#		if team.setter.rb.mode == RigidBody.MODE_KINEMATIC:
#			team.setter.stateMachine.SetCurrentState(team.setter.setState)
#		team.chosenSetter = team.setter
	
	if team.chosenReceiver == team.setter:
		if team.isLiberoOnCourt:
			if AthleteCanStandingSet(team.libero, team, timeTillBallAtReceptionTarget):
				AssignSetter(team.libero, team, false)
				#libero sets (if that's the plan)
				pass
			elif AttemptToFindSetterOutOfSystem(team, timeTillBallAtReceptionTarget):
				
				
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team, timeTillBallAtReceptionTarget):
			#Someone digs or dives for the ball
				team.SendMultipleChasersAfterBall()
			else:
				team.GiveUpThePoint()
		else:
			pass
			#can someone else do it?
	else: # setter preferred - and the team is using a dedicated setter!
		if AthleteCanJumpSet(team.setter, team, timeTillBallAtReceptionTarget):
			AssignSetter(team.setter, team, true)

		elif AthleteCanStandingSet(team.setter, team, timeTillBallAtReceptionTarget):
			AssignSetter(team.setter, team, false)#Setter sets

		elif AttemptToFindSetterOutOfSystem(team, timeTillBallAtReceptionTarget):
			#another setter is used
			pass
		elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team, timeTillBallAtReceptionTarget):
			#Someone digs or dives for the ball
			team.SendMultipleChasersAfterBall()
		
		else:
			team.Chill()
			
func AssignSetter(athlete:Athlete, team:Team, isJumpSetting:bool):
	athlete.stateMachine.SetCurrentState(athlete.setState)
	team.chosenSetter = athlete
	team.receptionTarget = team.ball.BallPositionAtGivenHeight(athlete.stats.jumpSetHeight)
	athlete.moveTarget = team.receptionTarget
	athlete.moveTarget.y = 0
	
	if isJumpSetting:
		athlete.setState.setState = athlete.setState.SetState.JumpSet
		athlete.setState.jumpSetState = athlete.setState.JumpSetState.PreSet
	else:
		athlete.setState.setState = athlete.setState.SetState.StandingSet
	

func AthleteCanJumpSet(athlete:Athlete, team:Team, timeTillBallAtReceptionTarget:float)->bool:
	return timeTillBallAtReceptionTarget >= athlete.setState.TimeToJumpSet(athlete, team.receptionTarget)


func AthleteCanStandingSet(athlete:Athlete, team:Team, timeTillBallAtReceptionTarget:float)->bool:
	return timeTillBallAtReceptionTarget >= team.setter.setState.TimeToStandingSet(team.setter, team.receptionTarget)

func AttemptToFindSetterOutOfSystem(team:Team, timeTillBallAtReceptionTarget:float)->bool:
	# Has the person chosen a dedicated reserve setter? 
	# Defaulting to standard 2022 play style
	
	var xzReceptionTarget = team.xzVector(team.receptionTarget)
	for lad in team.courtPlayers:
		lad.distanceHack = lad.translation.distance_to(xzReceptionTarget)/lad.stats.speed
		if lad == team.chosenReceiver:
			lad.distanceHack = 99999
		
	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Athlete, "SortDistance")
	
	print(str(orderedList[0].distanceHack) + " time for quickest option to set ball")
	if orderedList[0].distanceHack < timeTillBallAtReceptionTarget:
		AssignSetter(orderedList[0], team, false)
		return true
	
	return false

func DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team:Team, timeTillBallAtReceptionTarget:float)->bool:
	
	var xzReceptionTarget = team.xzVector(team.receptionTarget)
	
	for lad in team.courtPlayers:
		lad.distanceHack = lad.translation.distance_to(xzReceptionTarget) - lad.stats.height
		if lad == team.chosenReceiver:
			lad.distanceHack = 99999

	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Athlete, "SortDistance")
	AssignSetter(orderedList[0], team, false)
	
	if orderedList[0].distanceHack / orderedList[0].stats.speed < timeTillBallAtReceptionTarget:
		return true

	return false

func TimeToBallAtReceptionTarget(ball:Ball, receptionTarget:Vector3):
	var ballXZVel = Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length()
	var ballXZDist = Vector3(ball.translation.x - receptionTarget.x, 0, ball.translation.z - receptionTarget.z).length()
	
	var time = ballXZDist/ ballXZVel
	#print("Time till ball at reception target: " + str(time))
	return time
