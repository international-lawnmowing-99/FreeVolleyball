extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamSet

#can also potentially spike, dogshot
var ballWillBeDumped:bool = false
var possibleSpikers:Array[Athlete] = []
var otherTeam:TeamNode


func Enter(team:TeamNode):
	if !otherTeam:
		if team.data.isHuman:
			otherTeam = team.mManager.teamB
		else:
			otherTeam = team.mManager.teamA

	nameOfState = "Set"
	ballWillBeDumped = false

	ChooseSetter(team)
	ThinkAboutDumping(team)

	if !ballWillBeDumped:
		ChooseSpiker(team)
	#Can the spiker get back to their runup and if not, how will that affect their spike?
#	team.mManager.sphere.position = team.setTarget.target
func Update(team:TeamNode):
	team.UpdateTimeTillDigTarget()

	var setHeight
	#will need to add more heights in for diving, bump sets
	if team.chosenSetter.setState.internalSetState == team.chosenSetter.setState.InternalSetState.JumpSet:
		setHeight = team.chosenSetter.stats.jumpSetHeight
	else:
		setHeight = team.chosenSetter.stats.standingSetHeight
	#Is the ball close enough
	if team.ball.position.y <= setHeight && team.ball.linear_velocity.y < 0 && \
		Vector3(team.chosenSetter.position.x, setHeight, team.chosenSetter.position.z).distance_squared_to(team.ball.position) < 1:
			if ballWillBeDumped:
				DumpBall(team)
			else:
				SetBall(team)
	#CheckForSpikeDistance(team)

func Exit(_team:TeamNode):
	pass

func DumpBall(team:TeamNode):
	team.ball.attackTarget = team.CheckIfFlipped(Vector3(randf_range(-1, -4.5), 0, -4.5 + randf_range(0, 9)))
	team.ball.difficultyOfReception = randf_range(0, team.chosenSetter.stats.dump)

	# Here's a note about a weird error. If the ball is dumped with a well behaved parabola with
	# a max height of 0.1 above the current height, hundreds of errors appear somewhere during
	# physics process, using both physics engines. Not for +0.2 height though
	# Solved - it was the IK system deciding to "rip [the setter's] bloody arms off"!

	team.ball.linear_velocity = Maths.CalculateBallOverNetVelocity(team.ball.position, team.ball.attackTarget, max(team.ball.position.y + .1, 2.9), 1.0)
#	FindWellBehavedParabola(team.ball.position, team.ball.attackTarget, max(team.ball.position.y + 2, 2.9))
	print("ball.linear_vel: " + str(team.ball.linear_velocity))
#	team.ball.linear_velocity = team.ball.FindParabolaForGivenSpeed(team.ball.position, team.ball.attackTarget, randf_range(5,10), false)
#	if team.ball.FindNetPass().y <= 2.5:
#		team.ball.linear_velocity = team.ball.CalculateBallOverNetVelocity(team.ball.position, team.ball.attackTarget, 2.5)
	team.mManager.BallOverNet(team.data.isHuman)

func SetBall(team:TeamNode):
	# mint set, poor set (short, long, mis-timed, tight, over, or some combo thereof - so many ways to set poorly!), 2 hits/carry ("setting error")
	randomize()
	var setExecution = 100#randi()% 100

	# A 100 setter would always set good?
	# A 0 setter always makes errors
	# An 80 setter sets a higher proportion of good sets than a 40

	var errorThreshold = 100.0 * pow((team.chosenSetter.stats.set/100 - 1.0), 8.0)
	var perfectThreshold = 100.0 - 100.0 / (1.0 + pow(2.71828, -((team.chosenSetter.stats.set/100.0) - 0.5)/0.1))
	# most sets are perfect now...
#	setExecution = perfectThreshold - 1
#	Console.AddNewLine("[[[[[ set execution:" + str(setExecution) + " ]]]]]")
#	Console.AddNewLine("[[[[[ error threshold:" + str(errorThreshold) + " ]]]]]")
#	Console.AddNewLine("[[[[[ perfect threshold:" + str(perfectThreshold) + " ]]]]]")
#
	if setExecution < errorThreshold:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " setting error", Color.BLUE)
		team.ball.inPlay = false
		team.ball.linear_velocity = Vector3.ZERO
		team.Chill()
		if team.data.isHuman:
			team.mManager.PointToTeamB()
		else:
			team.mManager.PointToTeamA()
	elif setExecution > perfectThreshold:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " lip-smacking set", Color.LAWN_GREEN)
		team.ball.linear_velocity = Maths.FindWellBehavedParabola(team.ball.position, team.setTarget.target, team.setTarget.height)
		#await team.get_tree().process_frame
		#team.ball.linear_velocity = Maths.FindWellBehavedParabola(team.ball.position, team.setTarget.target, team.setTarget.height)

		if team.ball.linear_velocity == Vector3.ZERO || team.ball.linear_velocity.length() > 10:
			if team.ball.position.y < team .setTarget.target.y:
				Console.AddNewLine("What happened here? Nothing logically impossible, but a perfect set has been requested in a place it can't happen. What do we do now?")
				team.mManager.Pause()

			Console.AddNewLine("Perfect, downwards set", Color.DARK_ORANGE)
			var trialVel = Maths.FindDownwardsParabola(team.ball.position, team.setTarget.target)
			if trialVel == null:
				trialVel = Vector3.ZERO
				Console.AddNewLine("Error!: Perfect set couldn't be produced from position requested")
				#Throw to setting error, however pardoxically? Will this be common enough to throw out long run averages?
				# Or force perfect parabola, leading to improbable sets being made?

			team.ball.linear_velocity = trialVel
			var timeCheck = Maths.TimeTillBallReachesHeight(team.ball.position, trialVel, team.setTarget.target.y, 1)

			Console.AddNewLine("Set speed: " + str(trialVel.length()), Color.POWDER_BLUE)
			Console.AddNewLine("Predicted set time: " + str(timeCheck), Color.POWDER_BLUE)

	else:
		Console.AddNewLine(team.chosenSetter.stats.lastName + " shitty set", Color.RED)
		# sets can be off in direction or speed (i.e. max height)
		# my major issue is setting short! direction not so bad
		# angle, distance, time as the three possible imperfections

		var difference = 100.0 - perfectThreshold - setExecution
		# smaller difference = smaller error
		var error = randf_range(0, difference) /30
		if team.data.isHuman:
			team.setTarget.target.x += abs(error)
		else:
			team.setTarget.target.x -= abs(error)
		team.setTarget.target.z += pow(-1,randi()%2) * error
		team.setTarget.height += randf_range(0,4) * abs(error)
		Console.AddNewLine("Error: " + str(error))
		team.mManager.cylinder.position = team.setTarget.target

		team.ball.linear_velocity = Maths.FindWellBehavedParabola(team.ball.position, team.setTarget.target, team.setTarget.height)

		#await team.get_tree().process_frame
		#team.ball.linear_velocity = Maths.FindWellBehavedParabola(team.ball.position, team.setTarget.target, team.setTarget.height)

		if team.ball.linear_velocity == Vector3.ZERO:
			team.ball.linear_velocity = Maths.FindDownwardsParabola(team.ball.position, team.setTarget.target)
	#
		team.ballPositionWhenSet = team.ball.position
		# React to the unexpected trajectory of the ball...
		###
		###
		if team.setTarget.target.x * team.flip < -0.5:
			Console.AddNewLine("__________________________________________===============================================================================================================================")
			team.ball.attackTarget = Maths.BallPositionAtGivenHeight(team.ball.position, team.ball.linear_velocity, 0, 1.0)
			team.ball.difficultyOfReception = 1.3
			team.mManager.BallOverNet(team.data.isHuman)
			return
		elif team.setTarget.target.x * team.flip < 0:
			# Tight set on other side of court, might be able to block
			pass
		elif team.setTarget.target.x * team.flip < 0.5:
			# Tight set on our side
			pass
		else:
			# Standard bad set

			# Can the ball still be hit?


			var maxHeightBadSet = Maths.BallMaxHeight(team.ball.position, team.ball.linear_velocity, 1.0)
			if maxHeightBadSet <= team.chosenSpiker.stats.spikeHeight:
				Console.AddNewLine("can't attack that bad set: Spike height " + str(team.chosenSpiker.stats.spikeHeight) + "  vs set: " + str(maxHeightBadSet))
				ScrambleForBadSet(team)
			else:
				# how long will it take to get to the new contact position?
				# *Reaction Time* + runup time + jumpTime

				# Decide new spiker. In future, if team cohesion is low,
				# perhaps people will collide or stare at each other while
				# the ball bounces?

				if AthleteCanSpikeBadSet(team.chosenSpiker):
					Console.AddNewLine(team.chosenSpiker.stats.lastName + " (chosenSpiker) CAN spike bad set +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
					team.chosenSpiker.moveTarget = team.chosenSpiker.spikeState.runupStartPosition
					team.chosenSpiker.setRequest = team.setTarget
					team.chosenSpiker.spikeState.spikeState = team.chosenSetter.spikeState.SpikeState.ChoiceConfirmed
					pass

				elif AthleteCanStandingRollBadSet(team.chosenSpiker):
					Console.AddNewLine(team.chosenSpiker.stats.lastName + " (chosenSpiker) can't spike bad set, will be able to aggressively play it though --------------------------------------------------------------------------------------------------------------------")
					pass
				else:
					Console.AddNewLine("Scrambling for bad set ===============================================================")
					ScrambleForBadSet(team)

	Console.AddNewLine("SET SPEED: " + str(team.ball.linear_velocity.length()) + "mps")
#		team.chosenSpiker.spikeState.ReactToDodgySet()

	if !team.setTarget:
		#setTarget = Set(-4.5, 0, 0, randf() * 6 + 2.5)
		#ball.attackTarget = setTarget.target
		#team.ball.linear_velocity = team.ball.CalculateWellBehavedParabola(team.ball.position, setTarget.target, setTarget.height)
		#BallOverNet()

		team.chosenSetter.setState.WaitThenDefend(team.chosenSetter, 0.5)
		team.chosenSetter = null
		if (team.data.markUndoChangesToRoles):
			team.setTarget = team.oppositeHitter.outsideFrontSpikes[0]

			team.chosenSpiker = team.oppositeHitter
		else:
			team.setTarget = team.outsideFront.outsideFrontSpikes[0]
			team.chosenSpiker = team.outsideFront

		team.chosenSpiker = team.middleFront
		team.setTarget = team.middleFront.middleSpikes[0]

	for athlete in possibleSpikers:
		if athlete != team.chosenSpiker && athlete.stateMachine.currentState != athlete.freeBallState:
			athlete.stateMachine.SetCurrentState(athlete.coverState)
		#CalculateSetDifficulty()


#	Console.AddNewLine("Ball vel ----------------------------------- " + str(3.6 * team.ball.linear_velocity.length()))

	#team.setTarget = null



	team.mManager.BallSet(team.data.isHuman)

func AthleteCanStandingRollBadSet(_athlete:Athlete) -> bool:
	return false

func ScrambleForBadSet(team:TeamNode):
	# Find someone to roll/push the set over if possible, or else give a free ball
	var ballDigHeight = 0.5
	var ballPositionAtDig = Maths.BallPositionAtGivenHeight(team.ball.position, team.ball.linear_velocity, ballDigHeight, 1.0)
	for athlete in team.courtPlayerNodes:
		athlete.distanceHack = 9999

		if athlete == team.chosenSpiker || athlete == team.chosenSetter:
			continue

		athlete.distanceHack = Maths.XZVector(ballPositionAtDig - athlete.position).length()/athlete.stats.speed

		if !athlete.freeze:
			var timeToReachGround
			if athlete.rb.linear_velocity.y > 0:
				# They're going up
				timeToReachGround = athlete.linear_velocity.y/-athlete.g + sqrt(2 + athlete.g * athlete.stats.verticalJump)/athlete.g
			else:
				# They're falling
				timeToReachGround = sqrt(2 * athlete.g * athlete.position.y)
			athlete.distanceHack += timeToReachGround

	var orderedList = team.courtPlayerNodes.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))
	if orderedList[0].distanceHack >= 9999:
		Console.AddNewLine("No one could reach the ball")
	else:
		orderedList[0].stateMachine.SetCurrentState(orderedList[0].freeBallState)
		orderedList[0].moveTarget = Maths.XZVector(ballPositionAtDig)
		Console.AddNewLine(orderedList[0].stats.lastName + " cleans up bad set")
	team.chosenSpiker.stateMachine.SetCurrentState(team.chosenSpiker.chillState)
	team.stateMachine.SetCurrentState(team.chillState)
	team.chosenSpiker = null

func CheckForSpikeDistance(team:TeamNode):
	if !team.chosenSpiker:
		print("Error inbound")
		#Log(setTarget.target)
	if team.ball.position.y <= team.setTarget.y \
	&& abs(team.ball.position.z) >= abs(team.setTarget.z) && team.ball.linear_velocity.y <= 0:
		team.stateMachine.SetCurrentState(team.spikeState)

func ChooseSetter(team:TeamNode):
#	var timeTillBallAtReceptionTarget = TimeTillBallAtReceptionTarget(team.ball, team.receptionTarget)
	# Who will set?
	# Who will hit?
	# Who is out of the picture and will sit around looking pretty?

	if team.chosenReceiver == team.setter:
		# what will the setter do now?
		#team.setter.moveTarget = Maths.XZVector(team.setter.setRequest.target) + team.setter.team.flip * Vector3(3 + team.setter.stats.verticalJump/2, 0, 0)

		if team.data.isLiberoOnCourt:
			if AthleteCanStandingSet(team.activeLibero, team):
				AssignSetter(team.activeLibero, team, false)
				#libero sets (if that's the plan)
				pass
			elif AttemptToFindSetterOutOfSystem(team):
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team):
			#Someone digs or dives for the ball
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayerNodes[1]
				team.Chill()
		else:
			if AttemptToFindSetterOutOfSystem(team):
				pass
			elif DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team):
				#team.SendMultipleChasersAfterBall()
				pass
			else:
				team.chosenSetter = team.courtPlayerNodes[1]
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
			team.chosenSetter = team.courtPlayerNodes[1]
			team.Chill()

func AssignSetter(athlete:Athlete, team:TeamNode, isJumpSetting:bool):
	if isJumpSetting:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.JumpSet
		athlete.setState.jumpSetState = athlete.setState.JumpSetState.PreSet
		team.receptionTarget = Maths.BallPositionAtGivenHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.jumpSetHeight, 1.0)
	else:
		athlete.setState.internalSetState = athlete.setState.InternalSetState.StandingSet
		team.receptionTarget = Maths.BallPositionAtGivenHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.standingSetHeight, 1.0)

	athlete.stateMachine.SetCurrentState(athlete.setState)
	team.chosenSetter = athlete

	athlete.moveTarget = team.receptionTarget
	athlete.moveTarget.y = 0

#	team.mManager.sphere.position = athlete.moveTarget
#	team.mManager.cylinder.position = team.receptionTarget

func AthleteCanJumpSet(athlete:Athlete, team:TeamNode)->bool:
	var athleteSetPosition:Vector3 = Maths.BallPositionAtGivenHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.jumpSetHeight, 1.0)

	if team.data.isHuman:
		if athleteSetPosition.x < 0.1:
			return false
	else:
		if athleteSetPosition.x > 0.1:
			return false

	var timeTillBallAtSetPosition = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athleteSetPosition, 1.0)

	return timeTillBallAtSetPosition >= athlete.setState.TimeToJumpSet(athlete, athleteSetPosition)


func AthleteCanStandingSet(athlete:Athlete, team:TeamNode)->bool:
	var athleteSetPosition:Vector3 = Maths.BallPositionAtGivenHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.standingSetHeight, 1.0)

	if team.data.isHuman:
		if athleteSetPosition.x < 0.1:
			return false
		if athlete.stats.role == Enums.Role.Libero:
			if athleteSetPosition.x < 3.1:
				return false
	else:
		if athleteSetPosition.x > 0.1:
			return false
		if athlete.stats.role == Enums.Role.Libero:
			if athleteSetPosition.x > -3.1:
				return false

	var timeTillBallAtSetPosition = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athleteSetPosition, 1.0)

	return timeTillBallAtSetPosition >= athlete.setState.TimeToStandingSet(athlete, athleteSetPosition)

func AttemptToFindSetterOutOfSystem(team:TeamNode)->bool:
	# Has the person chosen a dedicated reserve setter?
	# Defaulting to standard 2022 play style
	for lad in team.courtPlayerNodes:
		if !AthleteCanStandingSet(lad, lad.team):
			lad.distanceHack = 9999
			continue
		var athleteSetPosition:Vector3 = Maths.BallPositionAtGivenHeight(lad.ball.position, lad.ball.linear_velocity, lad.stats.standingSetHeight, 1.0)
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

	var orderedList = team.courtPlayerNodes.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))

	print(str(orderedList[0].distanceHack) + " time for quickest option to set ball")
	if AthleteCanStandingSet(orderedList[0], orderedList[0].team):
		AssignSetter(orderedList[0], team, false)
		return true

	return false

func DesperatelyAttemptToFindSomeoneToPlayTheSecondBall(team:TeamNode)->bool:
	for lad in team.courtPlayerNodes:
		if !AthleteCanStandingSet(lad, lad.team):
			lad.distanceHack = 9999
			continue
		var athleteSetPosition:Vector3 = Maths.BallPositionAtGivenHeight(lad.ball.position, lad.ball.linear_velocity, lad.stats.standingSetHeight, 1.0)
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

	var orderedList = team.courtPlayerNodes.duplicate(false)
	orderedList.sort_custom(Callable(Athlete,"SortDistance"))
	AssignSetter(orderedList[0], team, false)

	if AthleteCanStandingSet(orderedList[0], orderedList[0].team):
		return true

	return false

func ThinkAboutDumping(team:TeamNode):
	if team.chosenSetter && team.chosenSetter.FrontCourt():
		var dump = !bool(randi()%30)
		if dump && abs(team.receptionTarget.x) < 2:
			Console.AddNewLine("!!!!Dumping!!!!!", Color.DARK_RED)
			ballWillBeDumped = true
			return

func ChooseSpiker(team:TeamNode):
	Console.AddNewLine("$    " + team.name + " choosing spiker", Color.TEAL)
	#Assess block/defence
		#Assess our quick attack threat to other team - will they commit?
		#Assess height/skill matchups
	# Weight for quality of attacker, predictability of set
	# I imagine there will be some Bayesian process of adjusting prior likelihoods based on only setting one person all around the court

	# How much do they fear a quick set on a scale of 0-1?
	var middleThreat:float = 0
	if otherTeam.middleFront.blockState.internalBlockState == AthleteBlockState.InternalBlockState.Jump:
		Console.AddNewLine("The opposition middle is already blocking", Color.LIGHT_BLUE)
	elif team.middleFront.stats.spikeHeight< 2.6 || \
		abs(team.receptionTarget.x) > 3:
		middleThreat = 0
		Console.AddNewLine("No middle threat", Color.TEAL)
	else:
		# how likely do we think they are they to commit to our middle?
		#
		# maybe they already have!
		#
		# what can they measure about our middle attack? Position of middle, position of setter, angle and distance to potential middle hits
		# Can the middle spike? How hard will it be to set them based on distance, angle?
		# If they do spike, how likely are they to win a point?
		pass

	# can the potential spiker get back to their runup location?
	# if not, can they still get to planned spike contact location by running checked an angle?
	# does the setter know that they aren't in the play?
	# is the set feasible given a max velocity out of the hand of somewhere around 10 to 11 mps?

	possibleSpikers = []

	for athlete:Athlete in team.courtPlayerNodes:
		if athlete!= team.chosenSetter && athlete.stats.role != Enums.Role.Libero && athlete != team.middleBack:
			if team.receptionTarget.x == NAN:
				var dfsdfds = 1
			var potentialSet = Maths.FindWellBehavedParabola(team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)
			if potentialSet == null:
				potentialSet = Vector3.ZERO
			var setSpeed = potentialSet.length()
			# Very hacky, but if no parabola is found then vector3.zero will be returned
			if setSpeed > 10 || setSpeed < 0.01:
				# Attempt downwards parabola
				potentialSet = Maths.FindDownwardsParabola(team.receptionTarget, athlete.setRequest.target)
				if potentialSet == null:
					athlete.stateMachine.SetCurrentState(athlete.coverState)
					Console.AddNewLine(athlete.stats.lastName + " requires a set with velocity: " + str(setSpeed) + "mps, and will cover - no theoretical downward set available")
					Console.AddNewLine("reception target: " + str(team.receptionTarget) + ", setTarget: " + str(athlete.setRequest.target))
					continue

				setSpeed = potentialSet.length()
				if setSpeed > 10 || setSpeed < 0.01:
					athlete.stateMachine.SetCurrentState(athlete.coverState)
					Console.AddNewLine(athlete.stats.lastName + " requires a set with velocity: " + str(setSpeed) + "mps, and will cover")
					Console.AddNewLine("reception target: " + str(team.receptionTarget) + ", setTarget: " + str(athlete.setRequest.target))
					continue

			if AthleteCanFullyTransition(athlete):
				athlete.spikeState.spikeValue = 1

				# to solve this we need the time for the set to occur
				# and the time for the athlete to get to the transition position,
				# then run up, then reach max jump height
				if athlete.rb.freeze:
					if athlete == team.chosenReceiver:
						athlete.WaitThenTransition(0.5)
						continue
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
				Console.AddNewLine(athlete.stats.lastName + " couldn't transition and will cover")

#	Console.AddNewLine("Choosing set option...")
	if possibleSpikers.size() <= 0:
		# Is there the opportunity to dump? Or should we do a release ball?
#		if abs(team.receptionTarget.x) >
		ballWillBeDumped = true

		Console.AddNewLine("^^^___^^^  No possible spikers, release ball", Color.CRIMSON)
		return

	else:
		Console.AddNewLine("There are " + str(possibleSpikers.size()) + " possible spikers")
		#
		# Now, will the middle be able to close to both pin blockers, and will they be able to seal against the pipe?
		# With this information, will the spiker have a single of double block?
		# What are the odds of a clean kill from the spiker vs such a block?
		# Weight and normalise these values so that they add to 1
		# If a random float is in the range of the choice, choose that spiker

		Console.AddNewLine("Assessing block...")
		# coverage and skill of double block * odds of double block + single block * (1 - odds of double block). And triple too
		var ourLeftBlockValue:float = otherTeam.defendState.rightSideBlocker.stats.block * middleThreat

		#This is very preliminary, a more rigorous method would account for the angles possible
		#IE if your spiike height is 6 metres, even if you're in the back court it doesn't matter
		for spiker:Athlete in possibleSpikers:
			if spiker.FrontCourt():
				if spiker == team.outsideFront && spiker.setRequest.target.z > 1*team.flip:
					#Set is on the left (i think), so the matchup is against the other team's right blocker
					if spiker.stats.spikeHeight> otherTeam.defendState.rightSideBlocker.stats.blockHeight:
						Console.AddNewLine("Might be able to OTT with left wing spiker")
				elif spiker == team.middleFront:
					if spiker.stats.spikeHeight> otherTeam.defendState.middleBlocker.stats.blockHeight:
						Console.AddNewLine("Might be able to OTT with middle")
				if spiker == team.oppositeHitter && spiker.setRequest.target.z > -1*team.flip:
					if spiker.stats.spikeHeight> otherTeam.defendState.leftSideBlocker.stats.blockHeight:
						Console.AddNewLine("Might be able to OTT with opposite")

		Console.AddNewLine("Considering spiker skill...")
		for spiker:Athlete in possibleSpikers:
			Console.AddNewLine(spiker.stats.lastName + " spike: " + str(spiker.stats.spike))

		Console.AddNewLine("How repetitive is our choice - are we predictable?")
		Console.AddNewLine("Do we have an explicit instruction from the coach?")
		Console.AddNewLine("Does the setter favour any set? Do they prefer to spread it around, or to set their best hitter all the time?")
		Console.AddNewLine("Does the hitter have any connection modifier from playing with the setter for a long time?") # Maybe in version 2...
		Console
#		if team.outsideBack in possibleSpikers:
#			team.chosenSpiker = team.outsideBack
#			team.setTarget = team.outsideBack.setRequest
#			return

		var setChoice = randi()%possibleSpikers.size()

		team.chosenSpiker = possibleSpikers[setChoice] #team.middleFront #

		if team.middleFront in possibleSpikers:
			team.chosenSpiker = team.middleFront

		team.setTarget = team.chosenSpiker.setRequest
		Console.AddNewLine("Chosen spiker is " + team.chosenSpiker.stats.lastName)

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
	#
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / athlete.g
	var timeToJumpPeak = timeToReachGround + timeToTransition + timeToRunup + jumpTime

	var timeTillBallReachesSetTarget

	if athlete.setRequest.target.y > athlete.team.receptionTarget.y:
	#normal set
		timeTillBallReachesSetTarget = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athlete.team.receptionTarget, 1.0) \
		+ Maths.SetTimeWellBehavedParabola(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)

	else:
		# setting downwards
		timeTillBallReachesSetTarget = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athlete.team.receptionTarget, 1.0) \
		+ Maths.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
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
		timeTillBallReachesSetTarget = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athlete.team.receptionTarget, 1.0) \
		+ Maths.SetTimeWellBehavedParabola(athlete.team.receptionTarget, athlete.setRequest.target, athlete.setRequest.height)
	else:
		# setting downwards
		timeTillBallReachesSetTarget = Maths.TimeTillBallAtPosition(athlete.ball.position, athlete.ball.linear_velocity, athlete.team.receptionTarget, 1.0) \
		+ Maths.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
	return timeToJumpPeak < timeTillBallReachesSetTarget

func AthleteCanSpikeBadSet(athlete:Athlete)-> bool:
	# The assumption is that there's a max angle you can still approach and spike
	# normally from. 45 degrees each side of perpendicular to the net let's say.
	# So can the athlete get to a position which is the distance of their runup plus
	# their jump length but all rotated a maximum of 45 degrees from behind the
	# point they would contact the new set??

	if !athlete.FrontCourt():
		if athlete.team.flip * athlete.team.setTarget.target.x <= athlete.team.flip * (3 - athlete.stats.verticalJump/2):
			return false

	var athleteSpikeTime:float = 0

	# 0 Are they airborne?
	var timeToReachGround:float = 0
	if !athlete.rb.freeze:
		if athlete.stateMachine.currentState == athlete.spikeState:
			Console.AddNewLine("Current spiker can't adjust to bad set after jumping")
			return false

		if athlete.rb.linear_velocity.y > 0:
			# They're going up
			timeToReachGround = athlete.linear_velocity.y/-athlete.g + sqrt(2 + athlete.g * athlete.stats.verticalJump)/athlete.g
		else:
			# They're falling
			timeToReachGround = sqrt(2 * athlete.g * athlete.position.y)

	athleteSpikeTime += timeToReachGround

	var ball:Ball = athlete.ball

	# 1 Find new spike contact location
	# (all normalised so that it takes place from the perspective of the human/teamA side)
	var spikeContactPos:Vector3 = Maths.BallPositionAtGivenHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.spikeHeight, 1.0)




	var XZSpikeContactFlipped = Maths.XZVector(spikeContactPos) * athlete.team.flip
	# 2 The critical points are the corners of fan shape
	var leftFanCorner:Vector3
	var rightFanCorner:Vector3
	# By our longstanding and extremely valid convention, jump length = jumpHeight/2
	# There is no comparable convention on runup length, curiously. So it's 3 metres now
	var runupLengthWithoutJump = 3
	var totalRunupLength:float = athlete.stats.verticalJump/2 + runupLengthWithoutJump
	var runupVector = Vector3(totalRunupLength, 0, 0)

	# If they can get back to the ordinary runup start position just go there
	if athleteSpikeTime + totalRunupLength/athlete.stats.speed <= Maths.SetTimeWellBehavedParabola(ball.position, spikeContactPos, Maths.BallMaxHeight(ball.position, ball.linear_velocity, 1.0)):
		athlete.spikeState.runupStartPosition = Maths.XZVector(spikeContactPos + athlete.team.flip * runupVector)
		return true



	leftFanCorner = XZSpikeContactFlipped + runupVector.rotated(Vector3.UP , -PI/4)
	rightFanCorner = XZSpikeContactFlipped + runupVector.rotated(Vector3.UP, PI/4)
#	athlete.team.mManager.sphere.position = leftFanCorner
	#athlete.team.mManager.cube.position = rightFanCorner

	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / -athlete.g

	athleteSpikeTime += runupLengthWithoutJump/athlete.stats.speed + jumpTime


	# 3 If the spiker is left or right of either of the corners, can they make it to one?
	if athlete.position.z * athlete.team.flip > leftFanCorner.z:
		athleteSpikeTime += Maths.XZVector(leftFanCorner - athlete.team.flip * athlete.position).length()/athlete.stats.speed
		athlete.spikeState.runupStartPosition = leftFanCorner * athlete.team.flip
		Console.AddNewLine(athlete.stats.lastName + " cornering left" + str(leftFanCorner))
	elif athlete.position.z * athlete.team.flip < rightFanCorner.z:
		athleteSpikeTime += Maths.XZVector(rightFanCorner - athlete.team.flip * athlete.position).length()/athlete.stats.speed
		athlete.spikeState.runupStartPosition = rightFanCorner * athlete.team.flip
		Console.AddNewLine(athlete .stats.lastName + " cornering right" + str(rightFanCorner))
	# 3.5 Otherwise it gets a little complicated. If they are within the fan, can they
	# get to the position that is on the circle 3m back from the contact point?
	# Or, if they are standing just to the side of the contact point for example,
	# can they get to the relevant corner?

	var angleToSpikeContactPos = Vector3(athlete.team.flip,0,0).signed_angle_to(Maths.XZVector(athlete.position - spikeContactPos), Vector3.UP)
	Console.AddNewLine(str(rad_to_deg(angleToSpikeContactPos)) + " degrees angle " + athlete.stats.lastName)
	if angleToSpikeContactPos > PI/4:
		athleteSpikeTime += Maths.XZVector(leftFanCorner - athlete.team.flip * athlete.position).length()/athlete.stats.speed
		athlete.spikeState.runupStartPosition = leftFanCorner * athlete.team.flip
		Console.AddNewLine(athlete.stats.lastName + " cornering left due to angle" + str(leftFanCorner))
		athlete.team.mManager.sphere.position = athlete.position# + Vector3(athlete.team.flip,0,0)
		athlete.team.mManager.cylinder.position = athlete.position + Maths.XZVector(athlete.position - spikeContactPos)

	elif angleToSpikeContactPos < -PI/4:
		athleteSpikeTime += Maths.XZVector(rightFanCorner - athlete.team.flip * athlete.position).length()/athlete.stats.speed
		athlete.spikeState.runupStartPosition = rightFanCorner * athlete.team.flip
		Console.AddNewLine(athlete .stats.lastName + " cornering right due to angle" + str(rightFanCorner))
		athlete.team.mManager.sphere.position = athlete.position# + Vector3(athlete.team.flip,0,0)
		athlete.team.mManager.cylinder.position = athlete.position + Maths.XZVector(athlete.position - spikeContactPos)
	# 4 Otherwise can they simply make the distance to the spike contact location?
	else:
		var distanceToSpikeContact = Maths.XZVector(athlete.position - spikeContactPos).length()
		Console.AddNewLine("distance to spkie contact: " + str(distanceToSpikeContact))
		Console.AddNewLine("total runup length: " + str(totalRunupLength))
		if distanceToSpikeContact > totalRunupLength:
			Console.AddNewLine("distance greater than runup")
			# They are outside the fan radius, just need to head to the location
			athleteSpikeTime += (distanceToSpikeContact - totalRunupLength)/athlete.stats.speed
			athlete.spikeState.runupStartPosition = Maths.XZVector(athlete.position + (spikeContactPos - athlete.position) * (distanceToSpikeContact - totalRunupLength) / distanceToSpikeContact)
#			athlete.team.mManager.sphere.position = athlete.spikeState.runupStartPosition
		else:
			# They are inside the fan, need to backtrack a little
			Console.AddNewLine("runup greater than distance, backtracking")
			athleteSpikeTime += (totalRunupLength - distanceToSpikeContact)/athlete.stats.speed
			athlete.spikeState.runupStartPosition = Maths.XZVector(athlete.position + (athlete.position - spikeContactPos) * totalRunupLength / distanceToSpikeContact)

#	athlete.team.mManager.cube.position = athlete.spikeState.runupStartPosition


	return athleteSpikeTime < Maths.SetTimeWellBehavedParabola(ball.position, spikeContactPos, Maths.BallMaxHeight(ball.position, ball.linear_velocity, 1.0))
