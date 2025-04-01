extends Node

const gravity = 9.8

func _ready():
	assert(gravity == ProjectSettings.get_setting("physics/3d/default_gravity"))

func XZVector(vec:Vector3) -> Vector3:
	return Vector3(vec.x, 0, vec.z)

func SignedAngle(from:Vector3, to:Vector3, up:Vector3):
	if from == to or from == up or up == to:
		print("signed angle issue(?)")
		print("from: " + str(from))
		print("to: " + str(to))
		print("up: " + str(up))
		return 0.001
	var cross_to = from.cross(to)
	var unsigned_angle = atan2(cross_to.length(), from.dot(to))
	var theSign = cross_to.dot(up)

	if theSign < 0:
		return -unsigned_angle
	else:
		return unsigned_angle

func FindParabolaForGivenSpeed(startPos:Vector3, target:Vector3, speed:float, aimingUp:bool, gravity_scale:float):
	var g =  gravity * gravity_scale
	var xzDirection = target - startPos
	xzDirection.y = 0

	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var yDist =  target.y - startPos.y

	var idealAngle
	var angle1
	var angle2

	var determinant = pow(speed, 4) - g * (g * xzDist * xzDist + 2 * yDist * speed * speed)
	if determinant < 0:
		Console.AddNewLine("Can't make that parabola work mate", Color.POWDER_BLUE)
		return null
		#Console.AddNewLine("Can't make that parabola work mate, giving you the best we've got", Color.POWDER_BLUE)
#
		#idealAngle = PI/4
	else:
		angle1 = atan((speed * speed + sqrt(determinant)) / (g * xzDist))
		angle2 = atan((speed * speed - sqrt(determinant)) / (g * xzDist))

		if aimingUp:
			idealAngle = max(angle1, angle2)
		else:
			idealAngle = min(angle1, angle2)

	var projectileVelocity:Vector3 = Vector3.ZERO
	projectileVelocity.y = speed * sin(idealAngle)
	var xzProjectileVel = speed * cos(idealAngle)

	xzDirection = xzDirection.normalized()

	projectileVelocity.x = xzDirection.x * xzProjectileVel
	projectileVelocity.z = xzDirection.z * xzProjectileVel

	return projectileVelocity

func TimeTillBallReachesHeight(position:Vector3, linear_velocity:Vector3, height:float, gravity_scale:float):
	# Returns the 2nd time the ball reaches a height if it is travelling up, and the height is above or equal to the ball's height
	var g = gravity * gravity_scale

	var finalV = sqrt(linear_velocity.y * linear_velocity.y + 2 * g * (position.y - height))
	if is_nan(finalV):
		Console.AddNewLine("Tried to find TimeTillBallReachesHeight - ball won't reach height", Color.CORNFLOWER_BLUE)
		Console.AddNewLine("Det = " + str(linear_velocity.y * linear_velocity.y + 2 * g * (position.y - height)), Color.CORNFLOWER_BLUE)
	var remainingTime = (finalV + linear_velocity.y) / g

	return remainingTime

func BallPositionAtGivenHeight(position:Vector3, linear_velocity:Vector3, height:float, gravity_scale:float):

	var timeOfFlight = TimeTillBallReachesHeight(position, linear_velocity, height, gravity_scale)
	var xzPos = Vector2(position.x, position.z)
	var xzVel = Vector2(linear_velocity.x, linear_velocity.z)
	var newXZPos = xzPos + xzVel * timeOfFlight

	return Vector3(newXZPos.x, height, newXZPos.y)

func SetTimeDownwardsParabola(startPos:Vector3, endPos:Vector3):
	var ballVel = FindDownwardsParabola(startPos, endPos)
	if ballVel == Vector3.ZERO || null:
		return 9999.9

	return TimeTillBallReachesHeight(startPos, ballVel, endPos.y, 1)


func BallMaxHeight(position:Vector3, linear_velocity:Vector3, gravity_scale:float) -> float:
	var g = gravity * gravity_scale
	if linear_velocity.y<0:
		return position.y
	else:
		var timeOfFLight = linear_velocity.y/g
		var distanceToTravel = linear_velocity.y * timeOfFLight + 0.5 * g * timeOfFLight * timeOfFLight
		return position.y + distanceToTravel

func CalculateBallOverNetVelocity(startPos:Vector3, target:Vector3, heightOverNet:float, gravity_scale:float):
	var g = gravity * gravity_scale
	var distanceFactor = startPos.x / (abs(startPos.x) + abs(target.x))
	if startPos.x < 0:
		distanceFactor *= -1

	var netPass:Vector3 = startPos + (target - startPos) * distanceFactor
	netPass.y = heightOverNet

	var xzDistToTarget = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var xzDistToNet = Vector3(target.x, 0, target.z).distance_to(Vector3(netPass.x, 0, netPass.z))


#angle the ball wil be received checked. I now have no idea how this formula was derived
	var theta = atan((netPass.y * xzDistToTarget * xzDistToTarget - startPos.y * xzDistToNet * xzDistToNet) / (xzDistToNet * xzDistToTarget * xzDistToTarget - xzDistToTarget * xzDistToNet * xzDistToNet))

#final vel(in reverse)
	var determinant = g * xzDistToNet * xzDistToTarget * (xzDistToTarget - xzDistToNet) * (1 + tan(theta) * tan(theta)) / (2 * (xzDistToTarget * netPass.y - xzDistToNet * startPos.y))
#this will happen if the middle point is lower than or equal to the straight-line point at the net of the start and end, ie the parabola curves the wrong way
	if determinant < 0:
		print("Can't make that work chap")
		return Vector3.ZERO

	var vel = sqrt(determinant)

#Calculate new y vel
	var xzVel = cos(theta) * vel
	var time = xzDistToTarget / xzVel

	var finalYVel = -(sin(theta) * vel - g * time)


	var xzTheta = Maths.SignedAngle(Vector3(1, 0, 0), Vector3(target.x, 0, target.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	#xzTheta *= Mathf.Deg2Rad

	var velocity = Vector3(vel * cos(theta) * cos(-xzTheta), finalYVel, vel * cos(theta) * sin(-xzTheta))
	return velocity

func TimeTillBallAtPosition(position:Vector3, linear_velocity:Vector3, receptionTarget:Vector3, _gravity_scale) -> float:
	var ballXZVel = Vector3(linear_velocity.x, 0, linear_velocity.z).length()

	if ballXZVel <= 0:
		return 9999.9

	var ballXZDist = Vector3(position.x - receptionTarget.x, 0, position.z - receptionTarget.z).length()

	var time = ballXZDist/ ballXZVel
	#print("Time till ball at reception target: " + str(time))
	return time

func FindWellBehavedParabola(startPos:Vector3, endPos:Vector3, maxHeight:float):
	if maxHeight <= startPos.y || maxHeight < endPos.y:
		print("impossible parabola|| maxHeight = " + str(maxHeight) + ", startPos = " + str(startPos) + ", endPos = " + str(endPos))
		return Vector3.ZERO

	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x,0, endPos.z))
	var yVel = sqrt(2 * gravity * (maxHeight - startPos.y))

	var time = yVel / gravity + sqrt(2 * gravity * (maxHeight - endPos.y)) / gravity
	var xzVel = xzDist / time

	var xzTheta = Maths.SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)

#	print("\"Well-behaved\" parabola: " + str( Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))))
	return Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))

func FindDownwardsParabola(startPos:Vector3, endPos:Vector3):
	var maxSetVelocity = 10

	var yDist = startPos.y - endPos.y
	if yDist < 0:
		Console.AddNewLine("Downwards parabola requested in inappropriate situation")
		return null
	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x, 0, endPos.z))
	var xzTheta = Maths.SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)


	# Can the xzDistance be traversed by a ball set horizontally at the maximum allowable speed?
	# Can the set get down fast enough if you're setting from 10 metres in the air?
	# for every angle there's a corresponding velocity, should we find the most aggressive?

	# attempt to set horizontally, zero yVel
	var yTravelTime = sqrt(yDist/gravity)
	var maxXZTravelTime = xzDist/maxSetVelocity

	if yTravelTime <= maxXZTravelTime:
		var xzVel = xzDist/ yTravelTime
		Console.AddNewLine("Horizontal parabola")
		return Vector3(xzVel * cos(-xzTheta), 0, xzVel * sin(-xzTheta))


	else:
		#Console.AddNewLine("downwards parabola with lowest possible velocity", Color.POWDER_BLUE)

		#https://physics.stackexchange.com/questions/744596/calculate-the-angle-of-a-projectile-to-minimalize-the-initial-velocity
		var theta = atan((yDist + sqrt(yDist * yDist + xzDist * xzDist))/xzDist)
		#var theta2 = atan((yDist - sqrt(yDist * yDist + xzDist * xzDist))/xzDist)


		#var theta:float = PI/4 + .5 * atan(yDist/xzDist)
		#Console.AddNewLine("theta: " + str(theta))
		#Console.AddNewLine("theta2: " + str(theta2))

		var test = -gravity * xzDist * xzDist/(2*cos(theta)*cos(theta) * (yDist - xzDist*tan(theta)))
		#var test2 = -gravity * xzDist * xzDist/(2*cos(theta2)*cos(theta2) * (yDist - xzDist*tan(theta2)))

		var speed = 0
		#var speed2 = 0

		if test > 0:
			speed = sqrt(test)
		#if test2 > 0:
			#speed2 = sqrt(test2)

		#Console.AddNewLine("speed: " + str(speed))
		#Console.AddNewLine("speed2: " + str(speed2))

		if speed == 0:# && speed2 == 0:
			Console.AddNewLine("Couldn't find parabola with lowest velocity")
			return Vector3.ZERO

		#var speed = gravity*xzDist*xzDist/(sqrt(xzDist*xzDist + yDist*yDist) + yDist)

		var xzVel = speed * cos(theta)
		var yvel = speed * sin(theta)

		var theoreticalV = Vector3(xzVel * cos(-xzTheta), -yvel, xzVel * sin(-xzTheta))

		return theoreticalV



func SetTimeWellBehavedParabola(startPos:Vector3, endPos:Vector3, maxHeight:float):
	var setVelocity = FindWellBehavedParabola(startPos, endPos, maxHeight)
	if setVelocity.length() == 0:
		return 0
	var timeToPeak = setVelocity.y / gravity
	var timeDown = sqrt(2 * gravity * abs(maxHeight - endPos.y))/gravity
	return timeToPeak + timeDown

func FindNetPass(startPos:Vector3, attackTarget:Vector3, linear_velocity:Vector3, gravity_scale:float)->Vector3:
	var g = gravity * gravity_scale
	var distanceFactor = startPos.x / (abs(startPos.x) + abs(attackTarget.x))
	if startPos.x < 0:
		distanceFactor *= -1

	var netPass:Vector3 = startPos + (attackTarget - startPos) * distanceFactor
	var timeTillNet = abs(startPos.x/linear_velocity.x)
	netPass.y = startPos.y + linear_velocity.y * timeTillNet + .5 * - g * timeTillNet * timeTillNet

	return netPass
