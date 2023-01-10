extends Node


var spikedByA:bool = false
var blockers:Array
var ball:Ball
var spiker:Athlete

func KillBlock():
	ball.linear_velocity.x *= -1
	randomize()
	ball.linear_velocity *= rand_range(.5,.9)
	ball.attackTarget = ball.BallPositionAtGivenHeight(0)
#	print(ball.attackTarget)
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
	
func _init(_ball:Ball) -> void:


	ball = _ball
	pass

func _process(delta: float) -> void:
	if ball.blockWillBeAttempted:
		if spikedByA:
			if ball.translation.x >= 0:
				ResolveBlock()
		else:
			if ball.translation.x <= 0:
				ResolveBlock()
	pass

func ResolveBlock():
	Console.AddNewLine("Resolving block, " + str(len(blockers)) + " blockers", Color.yellowgreen)

	
	
	var blockStatsString = ""
	var totalBlockStrength = 0
	
	var blockerCount = 0
	for blocker in blockers:
		blockStatsString += str(round(blocker.stats.block)) + " "
		
		# What if they're not in position? 
#		if blockers.length() > 1:
#			if blocker = middle
		
		blockerCount += 1
		totalBlockStrength += blocker.stats.block/blockerCount
	Console.AddNewLine("Spiker stat: " + str(round(spiker.stats.spike)) + " || Blocker stat(s): " + blockStatsString + " ::" + str(totalBlockStrength), Color.yellowgreen)


	var attackRoll = rand_range(1, spiker.stats.spike)
	var blockRoll = rand_range(1, totalBlockStrength)
	
	Console.AddNewLine("Spike Roll: : " + str(int(attackRoll)) + " || Block Roll: " + str(int(blockRoll)), Color.yellowgreen)
	
	if attackRoll>blockRoll:
		ball.blockWillBeAttempted = false
		spiker.get_tree().get_root().get_node("MatchScene").BallOverNet(spiker.team.isHuman)
		return
	elif blockRoll > attackRoll:
		KillBlock()
	else:
		KillBlock()
	
	
	
	
func AddUpcomingBlock(_spikedByA, _blockers, _spiker):
	ball.blockWillBeAttempted = true
	spikedByA = _spikedByA
	blockers = _blockers
	spiker = _spiker

