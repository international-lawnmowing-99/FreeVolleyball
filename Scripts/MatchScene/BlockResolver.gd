extends Node


var spikedByA:bool = false
var blockers:Array
var ball:Ball
var spiker:Athlete
var netPass:Vector3

func KillBlock():
	ball.linear_velocity.x *= -1
	randomize()
	ball.linear_velocity *= randf_range(.5,.9)
	ball.gravity_scale = 1.0
	ball.topspin = 1.0
	ball.attackTarget = Maths.BallPositionAtGivenHeight(ball.position, ball.linear_velocity, 0, 1.0)
	
	ball.blockWillBeAttempted = false
	if spikedByA:
		ball.TouchedByB()
	else:
		ball.TouchedByA()
	pass
	
func ReflectBlock():
	pass
	
func TouchBlock():
	pass
	
func SnickBlock():
	pass
	
func BlockFault():
	pass
	
func _init(_ball:Ball):


	ball = _ball
	pass

func _physics_process(_delta: float) -> void:
	if ball.blockWillBeAttempted:
		if spikedByA:
			if ball.position.x >= 0:
				ResolveBlock()
		else:
			if ball.position.x <= 0:
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
	
	var defendingTeam:Team = blockers[0].team
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
			spiker.team.mManager.BallOverNet(spiker.team.isHuman)
		return


	var attackRoll = randf_range(1, spiker.stats.spike)
	var blockRoll = randf_range(1, chosenBlocker.stats.block)
	
	Console.AddNewLine("Spike Roll: : " + str(int(attackRoll)) + " || Block Roll: " + str(int(blockRoll)), Color.YELLOW_GREEN)
	
	# Imagine a graph of spike roll vs block roll, both 0-100
	# If spike is much better than the corresponding equal block value, then it's a kill, 
	# the other way, a kill block, and in the middle a deflection
	var deflectGradient = .25
	
	# Ineffective block
	if attackRoll>blockRoll + (1 + deflectGradient):
		KillBlock()
			
	elif blockRoll * (1 - deflectGradient) > attackRoll:
		KillBlock()
	else:
		KillBlock()
	
	
	
	
func AddUpcomingBlock(_spikedByA, _blockers, _spiker):
	ball.blockWillBeAttempted = true
	spikedByA = _spikedByA
	blockers = _blockers
	spiker = _spiker

