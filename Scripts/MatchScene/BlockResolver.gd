extends Node


var spikedByA:bool = false
var blockers:Array
var ball:Ball
var spiker:Athlete
var netPass:Vector3
var mManager:MatchManager

func KillBlock():
	var normal:Vector3 = Vector3(spiker.team.flip, 0, 0).rotated(Vector3.FORWARD*spiker.team.flip, (randf_range(PI/24,PI/8))).rotated(Vector3.UP, randf_range(-PI/13, PI/13))
	ball.linear_velocity = ball.linear_velocity.bounce(normal) * randf_range(0.5, 0.9)

	ball.gravity_scale = 1.0
	ball.topspin = 1.0
	ball.attackTarget = Maths.BallPositionAtGivenHeight(ball.position, ball.linear_velocity, 0, 1.0)

	ball.blockWillBeAttempted = false
	if spikedByA:
		ball.TouchedByB()
	else:
		ball.TouchedByA()

	Console.AddNewLine("Kill Block! Ball speed: " + str(ball.linear_velocity.length() * 3.6) + " kph", Color.BLUE)

	mManager.BallBlocked(spikedByA)

func ReflectBlock():
	# Ball loops up back on our side
	ball.blockWillBeAttempted = false
	ball.linear_velocity.x *= -1
	ball.linear_velocity *= randf_range(0.05, 0.3)
	ball.linear_velocity.y = randf_range(1.5, 5)

	if spikedByA:
		ball.TouchedByB()
	else:
		ball.TouchedByA()

	Console.AddNewLine("Reflect block", Color.THISTLE)
	ball.SetTopspin(1.0)
	ball.attackTarget = Maths.BallPositionAtGivenHeight(ball.position, ball.linear_velocity, 0, 1.0)
	spiker.team.stateMachine.SetCurrentState(spiker.team.receiveState)
	blockers[0].team.stateMachine.SetCurrentState(blockers[0].team.defendState)

func TouchBlock():
	pass

func SnickBlock():
	Console.AddNewLine("Snick block", Color.TURQUOISE)
	ball.blockWillBeAttempted = false
	ball.SetTopspin(1.0)
	ball.attackTarget.x = -spiker.team.flip * randf_range(4.5, 15.0)
	ball.attackTarget.z = randf_range(-6.0, 6.0)
	ball.attackTarget.y = 0

	var ballMaxHeight = randf_range(ball.position.y + 0.5, ball.position.y + 7.0)

	ball.linear_velocity = Maths.FindWellBehavedParabola(ball.position, ball.attackTarget, ballMaxHeight)
	ball.difficultyOfReception = randf_range(0, 20)
	mManager.BallOverNet(spiker.team.data.isHuman)
	ball.wasLastTouchedByA = !spikedByA

func BlockFault():
	if spikedByA:
		Console.AddNewLine("Net Touch by team B", Color.THISTLE)
		mManager.PointToTeamA()
	else:
		Console.AddNewLine("Net Touch by team A", Color.THISTLE)
		mManager.PointToTeamB()

func _init(_ball:Ball):
	ball = _ball

func _physics_process(_delta: float) -> void:
	if ball.blockWillBeAttempted:
		if !spikedByA:
			if ball.position.x >= -0.25:
				ResolveBlock()
		else:
			if ball.position.x <= 0.25:
				ResolveBlock()
	pass

func ResolveBlock():
	var ballRadius:float = 0.13

	Console.AddNewLine("Resolving block, " + str(len(blockers)) + " blockers", Color.YELLOW_GREEN)
	# Did the ball pass in a zone with a blocker?
	var leftBlocker:Athlete
	var middleBlocker:Athlete
	var rightBlocker:Athlete

	var canLeftBlock:bool = false
	var canMiddleBlock:bool = false
	var canRightBlock:bool = false

	var defendingTeam:TeamNode = blockers[0].team
	var flip = defendingTeam.flip

	if blockers.has(defendingTeam.defendState.leftSideBlocker):
		leftBlocker = defendingTeam.defendState.leftSideBlocker
		Console.AddNewLine("Defending team's left blocker present " + leftBlocker.stats.lastName)
#		var leftBlockerLeft:float = leftBlocker.position.z + flip * leftBlocker.stats.height/3
#		var leftBlockerRight:float = leftBlocker.position.z - flip * leftBlocker.stats.height/3


		if abs(netPass.z - leftBlocker.position.z) > leftBlocker.stats.height/3:
			Console.AddNewLine("Left blocker can't reach ball")
		else:
			var actualBlockHeight:float = leftBlocker.stats.blockHeight - leftBlocker.stats.verticalJump + leftBlocker.position.y
			Console.AddNewLine("Left blocker height at block: " + str("%0.2f" % actualBlockHeight) + " ... Possible block height: " + str("%0.2f" % leftBlocker.stats.blockHeight))
			if netPass.y - ballRadius > actualBlockHeight:
				Console.AddNewLine("Ball sails harmlessly over left blocker, ball height: " + str(netPass.y))
			else:
				Console.AddNewLine("Left blocker involved in block!", Color.MEDIUM_TURQUOISE)
				canLeftBlock = true


	if blockers.has(defendingTeam.defendState.middleBlocker):
		middleBlocker = defendingTeam.defendState.middleBlocker
		Console.AddNewLine("Defending team's middle blocker present " + middleBlocker.stats.lastName)
		if abs(netPass.z - middleBlocker.position.z) > middleBlocker.stats.height/3:
			Console.AddNewLine("Middle blocker can't reach ball")
		else:
			var actualBlockHeight:float = middleBlocker.stats.blockHeight - middleBlocker.stats.verticalJump + middleBlocker.position.y
			Console.AddNewLine("Middle blocker height at block: " + str("%0.2f" % actualBlockHeight) + " ... Possible block height: " + str("%0.2f" % middleBlocker.stats.blockHeight))
			if netPass.y - ballRadius > actualBlockHeight:
				Console.AddNewLine("Ball sails harmlessly over middle blocker, ball height: " + str(netPass.y))
			else:
				Console.AddNewLine("Middle blocker involved in block!", Color.MEDIUM_TURQUOISE)
				canMiddleBlock = true

	if blockers.has(defendingTeam.defendState.rightSideBlocker):
		rightBlocker = defendingTeam.defendState.rightSideBlocker
		Console.AddNewLine("Defending team's right blocker present " + rightBlocker.stats.lastName)
		if abs(netPass.z - rightBlocker.position.z) > rightBlocker.stats.height/3:
			Console.AddNewLine("Right blocker can't reach ball")
		else:
			var actualBlockHeight:float = rightBlocker.stats.blockHeight - rightBlocker.stats.verticalJump + rightBlocker.position.y
			Console.AddNewLine("Right blocker height at block: " + str("%0.2f" % actualBlockHeight) + " ... Possible block height: " + str("%0.2f" % rightBlocker.stats.blockHeight))
			if netPass.y - ballRadius > actualBlockHeight:
				Console.AddNewLine("Ball sails harmlessly over right blocker, ball height: " + str(netPass.y))
			else:
				Console.AddNewLine("Right blocker involved in block!", Color.MEDIUM_TURQUOISE)
				canRightBlock = true

	# Choose the best available blocker to do a roll-off with
	var chosenBlocker:Athlete
	if canMiddleBlock:
		if canLeftBlock && canRightBlock:
			var tripleBlockList = [leftBlocker, middleBlocker, rightBlocker]
			tripleBlockList.sort_custom(func(a,b): return a.stats.block > b.stats.block)
			chosenBlocker = tripleBlockList[0]
		elif canLeftBlock:
			Console.AddNewLine("Middle and Left combine", Color.BLANCHED_ALMOND)
			if leftBlocker.stats.block > middleBlocker.stats.block:
				chosenBlocker = leftBlocker
			else:
				chosenBlocker = middleBlocker
		elif canRightBlock:
			Console.AddNewLine("Middle and Right combine", Color.BLANCHED_ALMOND)
			if rightBlocker.stats.block > middleBlocker.stats.block:
				chosenBlocker = rightBlocker
			else:
				chosenBlocker = middleBlocker
		else:
			chosenBlocker = middleBlocker

	elif canLeftBlock:
		chosenBlocker = leftBlocker
	elif  canRightBlock:
		chosenBlocker = rightBlocker
	else:
		Console.AddNewLine("Queued block, but noone could reach ball!", Color.RED)
		ball.blockWillBeAttempted = false
		if ball.inPlay:
			spiker.team.mManager.BallOverNet(spiker.team.data.isHuman)
		return


	var attackRoll = randf_range(1, spiker.stats.spike)
	var blockRoll = randf_range(1, chosenBlocker.stats.block)

	Console.AddNewLine("Spike Roll: : " + str(int(attackRoll)) + " || Block Roll: " + str(int(blockRoll)), Color.YELLOW_GREEN)

	# Imagine a graph of spike roll vs block roll, both 0-100
	# If spike is much better than the corresponding equal block value, then it's a kill,
	# the other way, a kill block, and in the middle a deflection
	var deflectGradient = .25

	Console.AddNewLine("A block will happen")
	Console.AddNewLine("1 + deflectGradient: " + str(1 + deflectGradient))
	Console.AddNewLine("1 - deflectGradient: " + str(1 - deflectGradient))
	Console.AddNewLine("Attack roll: " + str(attackRoll))
	Console.AddNewLine("Block roll: " + str(blockRoll))

	# Ineffective block
	if attackRoll>blockRoll * (1 + deflectGradient):
		KillBlock()
		#SnickBlock()

	elif blockRoll * (1 - deflectGradient) > attackRoll:
		KillBlock()
		#SnickBlock()
	else:
		KillBlock()
		#SnickBlock()




func AddUpcomingBlock(_spikedByA, _blockers, _spiker):
	ball.blockWillBeAttempted = true
	spikedByA = _spikedByA
	blockers = _blockers
	spiker = _spiker

