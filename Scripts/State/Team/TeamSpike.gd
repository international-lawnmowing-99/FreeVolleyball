extends "res://Scripts/State/Team/TeamState.gd"
var rng = RandomNumberGenerator.new()


func Enter(team:Team):
	rng.randomize()
	pass
func Update(team:Team):
	team.UpdateTimeTillDigTarget()
	if team.ball.linear_velocity.z > 0:
		if (team.ball.translation.z > team.chosenSpiker.setRequest.target.z && \
		team.ball.linear_velocity.y <= 0 && \
		(team.ball.translation - team.chosenSpiker.setRequest.target).length() < 0.5):
			SpikeBall(team)
		elif (team.ball.translation.z < team.chosenSpiker.setRequest.target.z &&\
			 team.ball.linear_velocity.y <= 0 && \
			(team.ball.translation - team.chosenSpiker.setRequest.target).length() < 0.5):
				SpikeBall(team)

func Exit(team:Team):
	pass

func SpikeBall(team:Team):
	var ball:Ball = team.ball
	if (!team.isHuman):
		ball.attackTarget = team.CheckIfFlipped(Vector3(rng.randf_range(1, 9), 0, -4.5 + rng.randf_range(9)))

	if team.setTarget.height > 2.43:
		#Draw a line from the ball to the target. If the point where it crosses the 
		#net is higher than said net, it can be hit, otherwise roll
		var netPass:Vector3

		var distanceFactor:float = ball.translation.x / (abs(ball.translation.x) + abs(ball.attackTarget.x))
		if ball.translation.x < 0:
			distanceFactor *= -1;

		netPass = ball.translation + (ball.attackTarget - ball.translation) * distanceFactor
		
		if netPass.y > 2.43:
			var xzDistToTarget:float = (Vector3(ball.translation.x, 0, ball.translation.z) - Vector3(ball.attackTarget.x, 0, ball.attackTarget.z)).length()
			var y = ball.translation.y
			var g = team.chosenSpiker.g
			
			#initial velocity of spike in mps
			var u = rng.randf_range(20,37)
			print("Spike Speed(m/s): " + str(u))
			
			var determinate = sqrt(4*pow(u,4)*xzDistToTarget*xzDistToTarget - 4*g*xzDistToTarget * xzDistToTarget* (g*xzDistToTarget*xzDistToTarget - 2*u*u*y))
			var solution1 = atan(-2*u*u + determinate)/(2*g*xzDistToTarget*xzDistToTarget)
			var solution2 = atan(-2*u*u - determinate)/(2*g*xzDistToTarget*xzDistToTarget)
			
			var correctSolution = min(solution2,solution1)
			print(str(correctSolution))
			var finalYVel = u * sin(correctSolution)
			var finalXZVel = u * cos(correctSolution)
			
			var xzVector = Vector3(ball.attackTarget.x, 0, ball.attackTarget.z) - Vector3(ball.translation.x, 0, ball.translation.z)
			# now the angles
			var xzTheta = ball.SignedAngle(Vector3(1,0,0), xzVector, Vector3.UP)
			var finalXVel = finalXZVel * cos(xzTheta)
			var finalZVel = finalXZVel * sin(xzTheta)
			
			ball.linear_velocity = Vector3(u * cos(correctSolution) * cos(-xzTheta), finalYVel, u * cos(correctSolution) * sin(-xzTheta))
			yield(team.get_tree(),"idle_frame")
			ball.linear_velocity = Vector3(u * cos(correctSolution) * cos(-xzTheta), finalYVel, u * cos(correctSolution) * sin(-xzTheta))
			print(ball.attackTarget)
	else:
		#yet again, somehow necessary
		ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, ball.attackTarget,  min(2.45, team.setTarget.height + 0.5))
		yield(team.get_tree(),"idle_frame")
		ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, ball.attackTarget,  min(2.45, team.setTarget.height + 0.5))
		ball.difficultyOfReception = team.chosenSpiker.stats.spike/4
		team.setTarget = null
	team.get_tree().get_root().get_node("MatchScene").BallOverNet(team.isHuman)

	
