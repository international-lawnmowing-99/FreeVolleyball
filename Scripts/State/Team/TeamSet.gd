extends "res://Scripts/State/Team/TeamState.gd"
const enums = preload("res://Scripts/World/Enums.gd")

#can also potentially spike, dogshot
var ballWillBeDumped:bool = false

func Enter(team:Team):
	ballWillBeDumped = false
	
	ChooseSetter(team)
	ThinkAboutDumping(team)
	
	if !ballWillBeDumped:
		ChooseSpiker(team)
	#Can the spiker get back to their runup and if not, how will that affect their spike?

func Update(team:Team):
	team.UpdateTimeTillDigTarget()
	
	var setHeight
	#will need to add more heights in for diving, bump sets
	if team.chosenSetter.setState.internalSetState == team.chosenSetter.setState.InternalSetState.JumpSet:
		setHeight = team.chosenSetter.stats.jumpSetHeight
	else:
		setHeight = team.chosenSetter.stats.standingSetHeight
	#Is the ball close enough
	if team.ball.translation.y <= team.receptionTarget.y && team.ball.linear_velocity.y < 0 && \
		Vector3(team.chosenSetter.translation.x, setHeight, team.chosenSetter.translation.z).distance_squared_to(team.ball.translation) < 1:
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
	
	# Here's a note about a weird error. If the ball is dumped with a well behaved parabola with 
	# a max height of 0.1 above the current height, hundreds of errors appear somewhere during 
	# physics process, using both physics engines. Not for +0.2 height though
	
	team.ball.linear_velocity = team.ball.FindWellBehavedParabola(team.ball.translation, team.ball.attackTarget, max(team.ball.translation.y + .2, 2.9))
#	team.ball.linear_velocity = team.ball.FindParabolaForGivenSpeed(team.ball.translation, team.ball.attackTarget, rand_range(5,10), false)
#	if team.ball.FindNetPass().y <= 2.5:
#		team.ball.linear_velocity = team.ball.CalculateBallOverNetVelocity(team.ball.translation, team.ball.attackTarget, 2.5)
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
	
	Console.AddNewLine("Ball vel ----------------------------------- " + str(3.6 * team.ball.linear_velocity.length()))
	
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
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayers[1]
				team.Chill()
		else:
			if AttemptToFindSetterOutOfSystem(team, timeTillBallAtReceptionTarget):
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team, timeTillBallAtReceptionTarget):
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayers[1]
				team.Chill()
			
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
			pass
			#team.SendMultipleChasersAfterBall()
		
		else:
			team.chosenSetter = team.courtPlayers[1]
			team.Chill()
			
func AssignSetter(athlete:Athlete, team:Team, isJumpSetting:bool):
	athlete.stateMachine.SetCurrentState(athlete.setState)
	team.chosenSetter = athlete

	athlete.moveTarget = team.receptionTarget
	athlete.moveTarget.y = 0
	
	if isJumpSetting:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.JumpSet
		athlete.setState.jumpSetState = athlete.setState.JumpSetState.PreSet
		team.receptionTarget = team.ball.BallPositionAtGivenHeight(athlete.stats.jumpSetHeight)
	else:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.StandingSet
		team.receptionTarget = team.ball.BallPositionAtGivenHeight(athlete.stats.standingSetHeight)

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
			lad.distanceHack = 9999

	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Athlete, "SortDistance")
	AssignSetter(orderedList[0], team, false)
	
	if orderedList[0].distanceHack / orderedList[0].stats.speed < timeTillBallAtReceptionTarget:
		return true

	return false

func TimeToBallAtReceptionTarget(ball:Ball, receptionTarget:Vector3) -> float:
	var ballXZVel = Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length()
	var ballXZDist = Vector3(ball.translation.x - receptionTarget.x, 0, ball.translation.z - receptionTarget.z).length()
	
	var time = ballXZDist/ ballXZVel
	#print("Time till ball at reception target: " + str(time))
	return time

func ThinkAboutDumping(team:Team):
	if team.chosenSetter && team.chosenSetter.FrontCourt():
		var dump = !bool(randi()%10)
		if dump && abs(team.receptionTarget.x) < 2:
			Console.AddNewLine("!!!!Dumping!!!!!", Color.darkred)
			ballWillBeDumped = true
			return
			
func ChooseSpiker(team:Team):
	# can the potential spiker get back to their runup location?
	# if not, can they still get to planned spike contact location by running on an angle?
	# does the setter know that they aren't in the play? 
	# is the set feasible given a max velocity out of the hand of somewhere around 10 to 11 mps?
	
	var possibleSpikers = []
	
	for athlete in team.courtPlayers:
		if athlete!= team.chosenSetter && athlete.role != enums.Role.Libero && athlete != team.middleBack:
			var setSpeed = team.ball.FindWellBehavedParabola(team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height).length()
			if setSpeed > 10:
				athlete.stateMachine.SetCurrentState(athlete.coverState)
				continue
			
			if AthleteCanFullyTransition(athlete):
				athlete.spikeState.spikeValue = 1
				
				# to solve this we need the time for the set to occur
				# and the time for the athlete to get to the transition position, 
				# then run up, then reach max jump height
				if athlete.rb.mode == RigidBody.MODE_KINEMATIC:
					athlete.stateMachine.SetCurrentState(athlete.transitionState)
				possibleSpikers.append(athlete)
				
			# elif they can run diagonally to the take off point - 
			# this needs set time, diagonal motion, and jump time
			elif AthleteCanDiagonallyTransition(athlete):
				athlete.spikeState.spikeValue = 0.5
				if athlete.rb.mode == RigidBody.MODE_KINEMATIC:
					athlete.stateMachine.SetCurrentState(athlete.transitionState)
				possibleSpikers.append(athlete)
			else:
				athlete.stateMachine.SetCurrentState(athlete.coverState)

			
	Console.AddNewLine("Choosing set option...")
	if possibleSpikers.size() <= 0:
		ballWillBeDumped = true
		
		Console.AddNewLine("^^^___^^^  No possible spikers, dumping", Color.crimson)
		#Got to dump
		#This happens when everyone's in the air and the back outside receives presumably so intensively that it takes them out of the attack - will eventually test 
		#if there's enough time for the spiker to do a full runup, and penalise their desirability as an option for the ai if they can't make it all the way back and 
		#have to hop on the spot. 
		#The choice of who to set could be moved to the actual point at which the set occurs??
		return

	var setChoice = randi()%possibleSpikers.size()
	
	team.chosenSpiker = possibleSpikers[setChoice]
	team.setTarget = team.chosenSpiker.setRequest
#	match team.chosenSpiker.role:
#		Enums.Role.Middle:
#
#		Enums.Role.Outside:
#			if team.chosenSpiker.FrontCourt():
#				team.setTarget = team.chosenSpiker.outsideFrontSpikes[0]
#			else:
#				team.setTarget = team.chosenSpiker.outsideBackSpikes[0]
#		Enums.Role.Opposite:
#			if team.chosenSpiker.FrontCourt():
#				team.setTarget = team.chosenSpiker.oppositeFrontSpikes[0]
#			else:
#				team.setTarget = team.chosenSpiker.oppositeBackSpikes[0]
	team.chosenSpiker.setRequest = team.setTarget

func AthleteCanFullyTransition(athlete) -> bool:
	var timeToReachGround = 0
	if athlete.rb.mode == RigidBody.MODE_RIGID:
		if athlete.rb.linear_velocity.y < 0:
			#they're going up
			timeToReachGround = athlete.linear_velocity.y/-athlete.g + sqrt(2 + athlete.g * athlete.stats.verticalJump)/athlete.g
		else:
			#they're falling
			timeToReachGround = sqrt(2 * athlete.g * athlete.translation.y)
	
	var timeToTransition = athlete.translation.distance_to(athlete.spikeState.runupStartPosition)/athlete.stats.speed
	var timeToRunup = athlete.spikeState.runupStartPosition.distance_to(athlete.spikeState.takeOffXZ)/athlete.stats.speed
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / athlete.g
	var timeToJumpPeak = timeToReachGround + timeToTransition + timeToRunup + jumpTime
	
	var timeTillBallReachesSetTarget = TimeToBallAtReceptionTarget(athlete.team.ball, athlete.team.receptionTarget) \
	+ athlete.team.ball.SetTime(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)
	
	return timeToJumpPeak < timeTillBallReachesSetTarget
	
func AthleteCanDiagonallyTransition(athlete)-> bool:
	if athlete.rb.mode != RigidBody.MODE_KINEMATIC:
		# It would be ridiculous (and a more effort to make work!) if they ran backwards to the takeoffpoint then jumped forwards!
		return false
	var timeToTakeOffXZ = athlete.translation.distance_to(athlete.spikeState.takeOffXZ)/athlete.stats.speed
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / -athlete.g
	var timeToJumpPeak = timeToTakeOffXZ + jumpTime
	
	var timeTillBallReachesSetTarget = TimeToBallAtReceptionTarget(athlete.team.ball, athlete.team.receptionTarget) \
	+ athlete.team.ball.SetTime(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)
	
	return timeToJumpPeak < timeTillBallReachesSetTarget
