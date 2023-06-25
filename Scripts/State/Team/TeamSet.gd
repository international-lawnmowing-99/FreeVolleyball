extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamSet

#can also potentially spike, dogshot
var ballWillBeDumped:bool = false
var possibleSpikers = []

func Enter(team:Team):
	nameOfState = "Set"
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
	if team.ball.position.y <= setHeight && team.ball.position.y <= team.receptionTarget.y && team.ball.linear_velocity.y < 0 && \
		Vector3(team.chosenSetter.position.x, setHeight, team.chosenSetter.position.z).distance_squared_to(team.ball.position) < 1:
			if ballWillBeDumped:
				DumpBall(team)
			else:
				SetBall(team)
	#CheckForSpikeDistance(team)
	pass
func Exit(_team:Team):
	pass

func DumpBall(team:Team):
	team.ball.attackTarget = team.CheckIfFlipped(Vector3(randf_range(-1, -4.5), 0, -4.5 + randf_range(0, 9)))
	team.ball.difficultyOfReception = randf_range(0, team.chosenSetter.stats.dump)
	
	# Here's a note about a weird error. If the ball is dumped with a well behaved parabola with 
	# a max height of 0.1 above the current height, hundreds of errors appear somewhere during 
	# physics process, using both physics engines. Not for +0.2 height though
	
	team.ball.linear_velocity = team.ball.CalculateBallOverNetVelocity(team.ball.position, team.ball.attackTarget, max(team.ball.position.y + 2, 2.9))
#	FindWellBehavedParabola(team.ball.position, team.ball.attackTarget, max(team.ball.position.y + 2, 2.9))
	print("ball.linear_vel: " + str(team.ball.linear_velocity))
#	team.ball.linear_velocity = team.ball.FindParabolaForGivenSpeed(team.ball.position, team.ball.attackTarget, randf_range(5,10), false)
#	if team.ball.FindNetPass().y <= 2.5:
#		team.ball.linear_velocity = team.ball.CalculateBallOverNetVelocity(team.ball.position, team.ball.attackTarget, 2.5)
	team.mManager.BallOverNet(team.isHuman)
	
func SetBall(team:Team):
	
	# mint set, poor set (short, long, mis-timed, tight, over, or some combo thereof - so many ways to set poorly!), 2 hits/carry ("setting error")
	randomize()
	var setExecution = randi()% 100
	
	# A 100 setter would always set good?
	# A 0 setter always makes errors
	# An 80 setter sets a higher proportion of good sets than a 40
	
	var errorThreshold = pow((team.chosenSetter.stats.set/100 - 1.0), 8.0)
	var perfectThreshold = 1.0 / (1.0 + pow(2.71828, -((team.chosenSetter.stats.set/100.0) - 0.5)/0.1))
	
	
	
	if setExecution == 0:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " lip-smacking set", Color.DARK_ORCHID)
	elif setExecution == 1:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " shitty set", Color.RED)
	elif setExecution == 2:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " setting error", Color.BLUE)
		
	if !team.setTarget:
		#setTarget = Set(-4.5, 0, 0, randf() * 6 + 2.5)
		#ball.attackTarget = setTarget.target
		#team.ball.linear_velocity = team.ball.CalculateWellBehavedParabola(team.ball.position, setTarget.target, setTarget.height)
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
		
	for athlete in possibleSpikers:
		if athlete != team.chosenSpiker:
			athlete.stateMachine.SetCurrentState(athlete.coverState)
		#CalculateSetDifficulty()

	team.ball.linear_velocity = team.ball.FindWellBehavedParabola(team.ball.position, team.setTarget.target, team.setTarget.height)
	if team.ball.linear_velocity == Vector3.ZERO:
		team.ball.linear_velocity = team.ball.FindDownwardsParabola(team.ball.position, team.setTarget.target)
#	
	team.ballPositionWhenSet = team.ball.position
	Console.AddNewLine("Ball vel ----------------------------------- " + str(3.6 * team.ball.linear_velocity.length()))
	
	#team.setTarget = null
	

	
	team.get_tree().get_root().get_node("MatchScene").BallSet(team.isHuman)


func CheckForSpikeDistance(team:Team):
	if !team.chosenSpiker:
		print("Error inbound")
		#Log(setTarget.target)
	if team.ball.position.y <= team.setTarget.y \
	&& abs(team.ball.position.z) >= abs(team.setTarget.z) && team.ball.linear_velocity.y <= 0:
		team.stateMachine.SetCurrentState(team.spikeState)

func ChooseSetter(team:Team):
#	var timeTillBallAtReceptionTarget = TimeTillBallAtReceptionTarget(team.ball, team.receptionTarget)
	# Who will set?
	# Who will hit?
	# Who is out of the picture and will sit around looking pretty?
	
	if team.chosenReceiver == team.setter:
		if team.isLiberoOnCourt:
			if AthleteCanStandingSet(team.libero, team):
				AssignSetter(team.libero, team, false)
				#libero sets (if that's the plan)
				pass
			elif AttemptToFindSetterOutOfSystem(team):
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team):
			#Someone digs or dives for the ball
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayers[1]
				team.Chill()
		else:
			if AttemptToFindSetterOutOfSystem(team):
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team):
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayers[1]
				team.Chill()

			#can someone else do it?
	else: # setter preferred - and the team is using a dedicated setter!
		if AthleteCanJumpSet(team.setter, team):
			AssignSetter(team.setter, team, true)

		elif AthleteCanStandingSet(team.setter, team):
			AssignSetter(team.setter, team, false)#Setter sets

		elif AttemptToFindSetterOutOfSystem(team):
			#another setter is used
			pass
		elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team):
			#Someone digs or dives for the ball
			pass
			#team.SendMultipleChasersAfterBall()

		else:
			team.chosenSetter = team.courtPlayers[1]
			team.Chill()
			
func AssignSetter(athlete:Athlete, team:Team, isJumpSetting:bool):
	if isJumpSetting:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.JumpSet
		athlete.setState.jumpSetState = athlete.setState.JumpSetState.PreSet
		team.receptionTarget = team.ball.BallPositionAtGivenHeight(athlete.stats.jumpSetHeight)
	else:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.StandingSet
		team.receptionTarget = team.ball.BallPositionAtGivenHeight(athlete.stats.standingSetHeight)

	athlete.stateMachine.SetCurrentState(athlete.setState)
	team.chosenSetter = athlete

	athlete.moveTarget = team.receptionTarget
	athlete.moveTarget.y = 0


func AthleteCanJumpSet(athlete:Athlete, team:Team)->bool:
	var athleteSetPosition:Vector3 = athlete.ball.BallPositionAtGivenHeight(athlete.stats.jumpSetHeight)

	if team.isHuman:
		if athleteSetPosition.x < 0.1:
			return false
	else:
		if athleteSetPosition.x > 0.1:
			return false
	
	var timeTillBallAtSetPosition = athlete.ball.TimeTillBallAtPosition(athlete.ball, athleteSetPosition)
		
	return timeTillBallAtSetPosition >= athlete.setState.TimeToJumpSet(athlete, athleteSetPosition)


func AthleteCanStandingSet(athlete:Athlete, team:Team)->bool:
	var athleteSetPosition:Vector3 = team.ball.BallPositionAtGivenHeight(athlete.stats.standingSetHeight)
	
	if team.isHuman:
		if athleteSetPosition.x < 0.1:
			return false
		if athlete.role == Enums.Role.Libero:
			if athleteSetPosition.x < 3.1:
				return false
	else:
		if athleteSetPosition.x > 0.1:
			return false
		if athlete.role == Enums.Role.Libero:
			if athleteSetPosition.x > -3.1:
				return false
			
	var timeTillBallAtSetPosition = athlete.ball.TimeTillBallAtPosition(athlete.ball, athleteSetPosition)
	
	return timeTillBallAtSetPosition >= athlete.setState.TimeToStandingSet(athlete, athleteSetPosition)

func AttemptToFindSetterOutOfSystem(team:Team)->bool:
	# Has the person chosen a dedicated reserve setter? 
	# Defaulting to standard 2022 play style
	for lad in team.courtPlayers:
		if !AthleteCanStandingSet(lad, lad.team):
			lad.distanceHack = 9999
			continue
		var athleteSetPosition:Vector3 = team.ball.BallPositionAtGivenHeight(lad.stats.standingSetHeight)
		var timeToReachGround = 0
		if !lad.rb.freeze:
			if lad.rb.linear_velocity.y > 0:
				#they're going up
				timeToReachGround = lad.linear_velocity.y/-lad.g + sqrt(2 + lad.g * lad.stats.verticalJump)/lad.g
			else:
				#they're falling
				timeToReachGround = sqrt(2 * lad.g * lad.position.y)
		lad.distanceHack = timeToReachGround + lad.position.distance_to(athleteSetPosition)/lad.stats.speed
		if lad == team.chosenReceiver:
			lad.distanceHack = 99999
		
	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))
	
	print(str(orderedList[0].distanceHack) + " time for quickest option to set ball")
	if AthleteCanStandingSet(orderedList[0], orderedList[0].team):
		AssignSetter(orderedList[0], team, false)
		return true
	
	return false

func DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team:Team)->bool:	
	for lad in team.courtPlayers:
		if !AthleteCanStandingSet(lad, lad.team):
			lad.distanceHack = 9999
			continue
		var athleteSetPosition:Vector3 = team.ball.BallPositionAtGivenHeight(lad.stats.standingSetHeight)
		var timeToReachGround = 0
		
		if !lad.rb.freeze:
			if lad.rb.linear_velocity.y > 0:
				#they're going up
				timeToReachGround = lad.linear_velocity.y/-lad.g + sqrt(2 + lad.g * lad.stats.verticalJump)/lad.g
			else:
				#they're falling
				timeToReachGround = sqrt(2 * lad.g * lad.position.y)
		lad.distanceHack = timeToReachGround + lad.position.distance_to(athleteSetPosition)/lad.stats.speed
		
		if lad == team.chosenReceiver:
			lad.distanceHack = 9999

	var orderedList = team.courtPlayers.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))
	AssignSetter(orderedList[0], team, false)
	
	if AthleteCanStandingSet(orderedList[0], orderedList[0].team):
		return true

	return false

func ThinkAboutDumping(team:Team):
	if team.chosenSetter && team.chosenSetter.FrontCourt():
		var dump = !bool(randi()%30)
		if dump && abs(team.receptionTarget.x) < 2:
			Console.AddNewLine("!!!!Dumping!!!!!", Color.DARK_RED)
			ballWillBeDumped = true
			return
			
func ChooseSpiker(team:Team):
	# can the potential spiker get back to their runup location?
	# if not, can they still get to planned spike contact location by running checked an angle?
	# does the setter know that they aren't in the play? 
	# is the set feasible given a max velocity out of the hand of somewhere around 10 to 11 mps?
	
	possibleSpikers = []
	
	for athlete in team.courtPlayers:
		if athlete!= team.chosenSetter && athlete.role != Enums.Role.Libero && athlete != team.middleBack:
			if team.receptionTarget.x == NAN:
				var dfsdfds = 1
			var setSpeed = team.ball.FindWellBehavedParabola(team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height).length()
			# Very hacky, but if no parabola is found then vector3.zero will be returned
			if setSpeed > 10 || setSpeed < 0.01:
				# Attempt downwards parabola
				setSpeed = team.ball.FindDownwardsParabola(team.receptionTarget, athlete.setRequest.target).length()
				if setSpeed > 10 || setSpeed < 0.01:
					athlete.stateMachine.SetCurrentState(athlete.coverState)
					continue
				
					
			
			if AthleteCanFullyTransition(athlete):
				athlete.spikeState.spikeValue = 1
				
				# to solve this we need the time for the set to occur
				# and the time for the athlete to get to the transition position, 
				# then run up, then reach max jump height
				if athlete.rb.freeze:
					athlete.stateMachine.SetCurrentState(athlete.transitionState)
				possibleSpikers.append(athlete)
				
			# elif they can run diagonally to the take unchecked point - 
			# this needs set time, diagonal motion, and jump time
			elif AthleteCanDiagonallyTransition(athlete):
				athlete.spikeState.spikeValue = 0.5
				if athlete.rb.freeze:
					athlete.stateMachine.SetCurrentState(athlete.transitionState)
				possibleSpikers.append(athlete)
			else:
				athlete.stateMachine.SetCurrentState(athlete.coverState)

			
	Console.AddNewLine("Choosing set option...")
	if possibleSpikers.size() <= 0:
		# Is there the opportunity to dump? Or should we do a release ball?
#		if abs(team.receptionTarget.x) > 
		ballWillBeDumped = true
		
		Console.AddNewLine("^^^___^^^  No possible spikers, release ball", Color.CRIMSON)

		return

	var setChoice = randi()%possibleSpikers.size()
	
	team.chosenSpiker = possibleSpikers[setChoice]
	team.setTarget = team.chosenSpiker.setRequest


func AthleteCanFullyTransition(athlete) -> bool:
	var timeToReachGround = 0
	if !athlete.rb.freeze:
		if athlete.rb.linear_velocity.y > 0:
			#they're going up
			timeToReachGround = athlete.linear_velocity.y/-athlete.g + sqrt(2 + athlete.g * athlete.stats.verticalJump)/athlete.g
		else:
			#they're falling
			timeToReachGround = sqrt(2 * athlete.g * athlete.position.y)
	
	var timeToTransition = athlete.position.distance_to(athlete.spikeState.runupStartPosition)/athlete.stats.speed
	var timeToRunup = athlete.spikeState.runupStartPosition.distance_to(athlete.spikeState.takeOffXZ)/athlete.stats.speed
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / athlete.g
	var timeToJumpPeak = timeToReachGround + timeToTransition + timeToRunup + jumpTime
	
	var timeTillBallReachesSetTarget 
	
	if athlete.setRequest.target.y > athlete.team.receptionTarget.y:
	#normal set
		timeTillBallReachesSetTarget = athlete.ball.TimeTillBallAtPosition(athlete.ball, athlete.team.receptionTarget) \
		+ athlete.team.ball.SetTimeWellBehavedParabola(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)

	else:
		# setting downwards
		timeTillBallReachesSetTarget = athlete.ball.TimeTillBallAtPosition(athlete.ball, athlete.team.receptionTarget) \
		+ athlete.team.ball.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
	return timeToJumpPeak < timeTillBallReachesSetTarget
	
func AthleteCanDiagonallyTransition(athlete)-> bool:
	if !athlete.rb.freeze:
		# It would be ridiculous (and more effort to make work!) if they ran backwards to the takeoffpoint then jumped forwards!
		return false
	var timeToTakeOffXZ = athlete.position.distance_to(athlete.spikeState.takeOffXZ)/athlete.stats.speed
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / -athlete.g
	var timeToJumpPeak = timeToTakeOffXZ + jumpTime
	
	# Assumes the team's reception target has been updated 
	# to reflect the choice of setter already
	var timeTillBallReachesSetTarget

	if athlete.setRequest.target.y > athlete.team.receptionTarget.y:
		#normal set
		timeTillBallReachesSetTarget = athlete.ball.TimeTillBallAtPosition(athlete.ball, athlete.team.receptionTarget) \
		+ athlete.team.ball.SetTimeWellBehavedParabola(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)
	else:
		# setting downwards
		timeTillBallReachesSetTarget = athlete.ball.TimeTillBallAtPosition(athlete.ball, athlete.team.receptionTarget) \
		+ athlete.team.ball.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
	return timeToJumpPeak < timeTillBallReachesSetTarget
