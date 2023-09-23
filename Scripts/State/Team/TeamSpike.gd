extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamSpike

var rng = RandomNumberGenerator.new()
var hit = false
var timeStart = 0
var timeEnd = 0

func Enter(_team:Team):
	nameOfState = "Spike"
	rng.randomize()
	hit = false
	pass
func Update(team:Team):
	team.UpdateTimeTillDigTarget()
#	Console.AddNewLine(str((team.ball.position - team.chosenSpiker.setRequest.target).length()))
	if !hit && team.ball.linear_velocity.y <= 0 && team.ball.position.y <= team.chosenSpiker.stats.spikeHeight:
		SpikeBall(team)
#		timeEnd = Time.get_unix_time_from_system()
#		var timeElapsed = timeEnd - timeStart
#		Console.AddNewLine("Actual time when ball ready to be spiked: " + str(timeElapsed))
#		if team.ball.linear_velocity.z > 0:
#			if team.ball.position.z > team.chosenSpiker.setRequest.target.z: #&& \
#				if(team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5:# &&\
#		if abs(team.ball.position.y - (team.chosenSpiker.position.y + team.chosenSpiker.stats.height * 1.33)) < 0.5:
#			if Maths.XZVector(team.ball.position - team.chosenSpiker.position).length() < 2:
#			if Vector3(team.chosenSpiker.position.x, team.chosenSpiker.position.y + team.chosenSpiker.stats.height * 1.33, team.chosenSpiker.position.z).distance_to(team.ball.position) <= 1:
#				team.chosenSpiker.spikeState.AdjustSpike(team.defendState.otherTeam)

#		elif team.ball.linear_velocity.z < 0:
#			if team.ball.position.z < team.chosenSpiker.setRequest.target.z:# &&\
				
##				if (team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5:# &&\
#				if Maths.XZVector(team.ball.position - team.chosenSpiker.position).length() < 0.5:
#					SpikeBall(team)
#		else:
#			Console.AddNewLine("No ball z vel...")
#			if team.ball.position.x <= team.setTarget.target.x &&\
#			(team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5:
#				SpikeBall(team)

func Exit(_team:Team):
	pass

func SpikeBall(team:Team):
	var netHeightPlusBallClearance:float = 2.43 + .13
	var ball:Ball = team.ball

	if team.setTarget.height > netHeightPlusBallClearance:
		#Draw a line from the ball to the target. If the point where it crosses the 
		#net is higher than said net, it can be hit, otherwise roll
		var netPass:Vector3

		var distanceFactor:float = ball.position.x / (abs(ball.position.x) + abs(ball.attackTarget.x))
		if ball.position.x < 0:
			distanceFactor *= -1;

		netPass = ball.position + (ball.attackTarget - ball.position) * distanceFactor
		
		if netPass.y > 0:# netHeightPlusBallClearance:
			#var xzDistToTarget:float = (Vector3(ball.position.x, 0, ball.position.z) - Vector3(ball.attackTarget.x, 0, ball.attackTarget.z)).length()
			#var y = ball.position.y
			#var g = team.chosenSpiker.g
			
			#initial velocity of spike in mps
			var u = 27.78
			#print("Spike Speed(m/s): " + str(u))
			
			ball.difficultyOfReception = u/37.0*team.chosenSpiker.stats.spike*2
			ball.gravity_scale = 7.0
			ball.linear_velocity = Maths.FindParabolaForGivenSpeed(ball.position, ball.attackTarget, u, false, 7.0)
			await team.get_tree().process_frame
			ball.linear_velocity = Maths.FindParabolaForGivenSpeed(ball.position, ball.attackTarget, u, false, 7.0)
			
		else:
			Console.AddNewLine("Ball will clip net if hit at that speed, finding easy parabola")
			#yet again, somehow necessary
			ball.linear_velocity = Maths.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
			await team.get_tree().process_frame
			ball.linear_velocity = Maths.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
			ball.difficultyOfReception = rng.randf_range(0, team.chosenSpiker.stats.spike/4)
			#team.setTarget = null
			#print(ball.attackTarget)
		
		if abs(netPass.z) >= 4.49:
			Console.AddNewLine("Ball will pass outside antennae lad", Color.CRIMSON)
			ball.inPlay = false
			if team.isHuman:
				team.mManager.PointToTeamB()
			else:
				team.mManager.PointToTeamA()
	else:
		Console.AddNewLine("set target below net height (taking into account ball clearance): " + str("%.1f"%team.setTarget.height))
		ball.linear_velocity = Maths.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
		ball.difficultyOfReception = rng.randf_range(0, team.chosenSpiker.stats.spike/4)
		team.setTarget = null
		
	team.mManager.BallSpiked(team.isHuman)
	hit = true
	
	Console.AddNewLine(team.chosenSpiker.stats.lastName + " cranks the ball at " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
