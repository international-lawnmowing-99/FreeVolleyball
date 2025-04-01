extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamDefend

var otherTeam:TeamNode
var leftSideBlocker:Athlete
var rightSideBlocker:Athlete
var middleBlocker:Athlete

func Enter(team:TeamNode):
	nameOfState = "Defend"
	for athlete:Athlete in team.courtPlayerNodes:
#		print(player.stats.lastName)
#		if player.rb.freeze:
#			print(player.stats.lastName + "Changing")
		if athlete.FrontCourt():
			if athlete.stateMachine.currentState != athlete.blockState:
				athlete.stateMachine.SetCurrentState(athlete.blockState)
		else:
			athlete.stateMachine.SetCurrentState(athlete.defendState)

	CacheBlockers(team)

	# What is the blocking strategy?
	# Can go standard spread, tight for pipe, don't rate the opposite so 2 checked setter/middle...
	# Can go even more extravagant - triple stack checked outside
	# In general we can have - triple checked each opposing player ~ 5 or 6 depending checked whether
	# Triple block checked libero!
	# Then we can have all the different configurations of double blocking
	# Blocking behaviour involves: where to stand initially
	# - whether to commit to any spiker (mostly middles, but theoretically could anyone could
	# commit to anyone)
	# - Where to set the block ie taking out line or cross court primarily
	# - Also whether to remove hands to avoid being tooled


	if team.setter.FrontCourt():
		team.setter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
#		team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(5.5, 0, -2.2))
		team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, 3))
	else:
		if team.data.markUndoChangesToRoles:
			team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, 3))
			team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
		else:
			team.oppositeHitter.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, -3))
			team.outsideFront.moveTarget = team.CheckIfFlipped(Vector3(0.5, 0, 3))

#		team.setter.moveTarget = team.CheckIfFlipped(Vector3(5.5, 0, 2.2))



	if otherTeam.data.markUndoChangesToRoles:
		leftSideBlocker.blockState.blockingTarget = otherTeam.outsideFront
		rightSideBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
	else:
		leftSideBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
		rightSideBlocker.blockState.blockingTarget = otherTeam.outsideFront


	team.middleFront.blockState.blockingTarget = otherTeam.middleFront

func Update(team:TeamNode):
	if team.data.isHuman:

		#print("defend" + str(randf()))
		if Input.is_key_pressed(KEY_LEFT):
			#print("BlockingLeft")
			if Input.is_key_pressed(KEY_SHIFT):
				TripleBlockLeft(team)
			else:
				DoubleBlockLeft(team)
		elif Input.is_key_pressed(KEY_RIGHT):
			if Input.is_key_pressed(KEY_SHIFT):
				TripleBlockRight(team)
			else:
				DoubleBlockRight(team)
		elif Input.is_key_pressed(KEY_DOWN):
			TripleBlockPipe(team)
	pass
func Exit(_team:TeamNode):
	pass

func CacheBlockers(team:TeamNode):
	middleBlocker = team.middleFront

	if team.setter.FrontCourt():
		rightSideBlocker = team.setter
		leftSideBlocker = team.outsideFront
	else:
		if team.data.markUndoChangesToRoles:
			rightSideBlocker = team.outsideFront
			leftSideBlocker = team.oppositeHitter
		else:
			rightSideBlocker = team.oppositeHitter
			leftSideBlocker = team.outsideFront

func TripleBlockLeft(team:TeamNode):
	rightSideBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
	middleBlocker.blockState.blockingTarget = otherTeam.oppositeHitter

	leftSideBlocker.moveTarget = team.flip * Vector3(0.5, 0, 4)
	middleBlocker.moveTarget = leftSideBlocker.moveTarget + team.flip * Vector3(0,0,-0.8)
	rightSideBlocker.moveTarget = team.middleFront.moveTarget + team.flip * Vector3(0,0,-0.8)

func TripleBlockRight(team:TeamNode):
	leftSideBlocker.blockState.blockingTarget = otherTeam.outsideFront
	middleBlocker.blockState.blockingTarget = otherTeam.outsideFront

	rightSideBlocker.moveTarget = team.flip * Vector3(0.5, 0, -4)
	middleBlocker.moveTarget = rightSideBlocker.moveTarget + team.flip * Vector3(0,0,0.8)
	leftSideBlocker.moveTarget = team.middleFront.moveTarget + team.flip * Vector3(0,0,0.8)

func DoubleBlockLeft(team:TeamNode):
	middleBlocker.blockState.blockingTarget = otherTeam.outsideFront
	middleBlocker.moveTarget = leftSideBlocker.moveTarget + team.flip * Vector3(0,0,-0.8)

func DoubleBlockRight(team:TeamNode):
	middleBlocker.blockState.blockingTarget = otherTeam.oppositeHitter
	middleBlocker.moveTarget = rightSideBlocker.moveTarget + team.flip * Vector3(0,0,0.8)

func TripleBlockPipe(team:TeamNode):
	rightSideBlocker.blockState.blockingTarget = otherTeam.outsideBack
	leftSideBlocker.blockState.blockingTarget = otherTeam.outsideBack
	middleBlocker.blockState.blockingTarget = otherTeam.outsideBack

	leftSideBlocker.moveTarget = team.middleFront.moveTarget + team.flip * Vector3(0,0,0.8)
	rightSideBlocker.moveTarget = team.middleFront.moveTarget + team.flip * Vector3(0,0,-0.8)

func EvaluateOppositionPass(_team:TeamNode):
	# make a list of available options for the other team's attack
	# ie, bad pass means no middle, so stack checked actually possible hitters
#	print("other team reception target: " + str(otherTeam.receptionTarget))
	var dumpProbability = 0

	if rightSideBlocker.blockState.isCommitBlocking:
		rightSideBlocker.blockState.ConfirmCommitBlock(rightSideBlocker, otherTeam)
	if leftSideBlocker.blockState.isCommitBlocking:
		leftSideBlocker.blockState.ConfirmCommitBlock(leftSideBlocker, otherTeam)
	if middleBlocker.blockState.isCommitBlocking:
		middleBlocker.blockState.ConfirmCommitBlock(middleBlocker, otherTeam)

func ReactToSet(team:TeamNode):
	if !otherTeam.chosenSpiker:
		return
	# React blockers move to new blocking position, perhaps after a delay given by a "reaction time" stat
	if !leftSideBlocker.blockState.isCommitBlocking:

		leftSideBlocker.blockState.internalBlockState = leftSideBlocker.blockState.InternalBlockState.Preparing
		leftSideBlocker.blockState.blockingTarget = otherTeam.chosenSpiker

		if team.data.isHuman:
			if otherTeam.setTarget.target.z >= 0:
				leftSideBlocker.moveTarget = Vector3(0.5, 0, min(4.25, otherTeam.chosenSpiker.setRequest.target.z))
			else:
				if middleBlocker.rb.freeze:
					leftSideBlocker.moveTarget = Vector3(0.5, 0, max(-4.25, otherTeam.chosenSpiker.setRequest.target.z) + 1.5)
				else:
					leftSideBlocker.stateMachine.SetCurrentState(leftSideBlocker.chillState)
		else:
			if otherTeam.setTarget.target.z <= 0:
				leftSideBlocker.moveTarget = Vector3(-0.5, 0, max(-4.25, otherTeam.chosenSpiker.setRequest.target.z))
			else:
				if middleBlocker.rb.freeze:
					leftSideBlocker.moveTarget = Vector3(-0.5, 0, min(4.25, otherTeam.chosenSpiker.setRequest.target.z) - 1.5)
				else:
					leftSideBlocker.stateMachine.SetCurrentState(leftSideBlocker.chillState)


	if !rightSideBlocker.blockState.isCommitBlocking:

		rightSideBlocker.blockState.blockingTarget = otherTeam.chosenSpiker
		rightSideBlocker.blockState.internalBlockState = rightSideBlocker.blockState.InternalBlockState.Preparing

		if team.data.isHuman:
			if otherTeam.setTarget.target.z <= 0:
				rightSideBlocker.moveTarget = Vector3(0.5, 0, max(-4.25, otherTeam.chosenSpiker.setRequest.target.z))
			else:
				if middleBlocker.rb.freeze:
					rightSideBlocker.moveTarget = Vector3(0.5, 0, min(4.25, otherTeam.chosenSpiker.setRequest.target.z) - 1.5)
				else:
					rightSideBlocker.stateMachine.SetCurrentState(rightSideBlocker.chillState)

		else:
			if otherTeam.setTarget.target.z >= 0:
				rightSideBlocker.moveTarget = Vector3(-0.5, 0, min(4.25, otherTeam.chosenSpiker.setRequest.target.z))

			else:
				if middleBlocker.rb.freeze:
					rightSideBlocker.moveTarget = Vector3(-0.5, 0, max(-4.25, otherTeam.chosenSpiker.setRequest.target.z) + 1.5)
				else:
					rightSideBlocker.stateMachine.SetCurrentState(rightSideBlocker.chillState)

	if !team.middleFront.blockState.isCommitBlocking:

		team.middleFront.blockState.blockingTarget = otherTeam.chosenSpiker
		team.middleFront.blockState.internalBlockState = team.middleFront.blockState.InternalBlockState.Preparing

		if team.data.isHuman:
			team.middleFront.moveTarget = Vector3(0.5, 0, clamp(otherTeam.setTarget.target.z, rightSideBlocker.moveTarget.z + 0.75, leftSideBlocker.moveTarget.z - 0.75))
		else:
			team.middleFront.moveTarget = Vector3(-0.5, 0, clamp(otherTeam.setTarget.target.z, leftSideBlocker.moveTarget.z + 0.75, rightSideBlocker.moveTarget.z - 0.75))

	else:
		if team.middleFront.blockState.blockingTarget != otherTeam.chosenSpiker:
			team.middleFront.blockState.blockingTarget = otherTeam.chosenSpiker
			team.middleFront.blockState.internalBlockState = team.middleFront.blockState.InternalBlockState.Preparing
			team.middleFront.blockState.isCommitBlocking = false

			if team.flip * otherTeam.chosenSpiker.setRequest.target.z >= 0:
				team.middleFront.moveTarget = leftSideBlocker.moveTarget - team.flip * Vector3(0, 0, .75)
			else:
				team.middleFront.moveTarget = rightSideBlocker.moveTarget + team.flip * Vector3(0, 0, .75)
