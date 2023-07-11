extends RigidBody3D

class_name Ball

#var g
var _parented:bool = false
var _pseudoParent
var wasLastTouchedByA:bool
var attackTarget
var mManager
var inPlay:bool = true
var blockWillBeAttempted = false
var blockResolver = load("res://Scripts/MatchScene/BlockResolver.gd").new(self)

var floating:bool = false
var floatDisplacement:Vector3 = Vector3.ZERO
@onready var mesh = $CollisionShape3D/ballv2

const MAX_SERVE_SPEED = 140
var difficultyOfReception:float = 0
#var lads = Vector3(-0.5,2.5,0)

func _process(_delta):
	if floating:
		if mesh.position.distance_to(floatDisplacement) < 0.1:
			floatDisplacement = Vector3(0, randf_range(-.3,.3), randf_range(-.3,.3))
			#ball will be passed at 0.5 metres high for now...
	floatDisplacement = lerp(floatDisplacement, Vector3.ZERO, _delta /min(.1,abs(position.y - 0.5)))
	mesh.position = lerp(mesh.position, floatDisplacement, _delta * 4.5)
		
#	if is_inside_tree() && _parented && _pseudoParent:
#		position = _pseudoParent.global_transform.origin
	#lads = Vector3(-0.5,2.5,0) - transform.origin
	pass
	
func _ready():
	add_child(blockResolver)
	#DebugOverlay.draw.add_vector(self, "lads", 1, 4, Color(0,1,1, 0.5))
	for i in range(10):
		#var velocity = CalculateBallOverNetVelocity(Vector3(i,
		pass
	
func _on_ball_body_entered(body):
	gravity_scale = 1
#	print (body.name)
	if inPlay:
		if body.is_in_group("ZoneOut"):
#		print("out got him yes")
			floating = false
			floatDisplacement = Vector3.ZERO
			inPlay = false
			if wasLastTouchedByA:
				Console.AddNewLine("ball out, point to b")
				mManager.PointToTeamB()
				
			else:
				Console.AddNewLine("ball out, point to a")
				mManager.PointToTeamA()
		elif body.is_in_group("ZoneInA"):
			floating = false
			floatDisplacement = Vector3.ZERO
			inPlay = false
			mManager.PointToTeamA()
			Console.AddNewLine("Ball in, point to a")

		elif body.is_in_group("ZoneInB"):
			floating = false
			floatDisplacement = Vector3.ZERO
			inPlay = false
			mManager.PointToTeamB()
			Console.AddNewLine("Ball in, point to b", Color.BISQUE)
		elif body.is_in_group("ZoneUnderNet"):
			inPlay = false
			if wasLastTouchedByA:
				Console.AddNewLine("ball under net, point to b", Color.GOLD)
				mManager.PointToTeamB()
				
			else:
				Console.AddNewLine("ball under net, point to a", Color.GOLD)
				mManager.PointToTeamA()
func PretendToBeParented(node):
	_parented = true
	_pseudoParent = node



func BallPositionAtGivenHeight(height:float):

	var timeOfFlight = TimeTillBallReachesHeight(height)
	var xzPos = Vector2(position.x, position.z)
	var xzVel = Vector2(linear_velocity.x, linear_velocity.z)
	var newXZPos = xzPos + xzVel * timeOfFlight

	return Vector3(newXZPos.x, height, newXZPos.y)
	
func TimeTillBallReachesHeight(height:float):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)

	var finalV = sqrt(linear_velocity.y * linear_velocity.y + 2 * g * (position.y - height))
	var remainingTime = (finalV + linear_velocity.y) / g

	return remainingTime

func TimeTillBallAtPosition(ball:Ball, receptionTarget:Vector3) -> float:
	var ballXZVel = Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length()
	
	if ballXZVel <= 0:
		return 0.0
	
	var ballXZDist = Vector3(ball.position.x - receptionTarget.x, 0, ball.position.z - receptionTarget.z).length()
	
	var time = ballXZDist/ ballXZVel
	#print("Time till ball at reception target: " + str(time))
	return time

func FindWellBehavedParabola(startPos: Vector3,endPos: Vector3, maxHeight:float):
	if maxHeight <= startPos.y || maxHeight < endPos.y:
		print("impossible parabola|| maxHeight = " + str(maxHeight) + ", startPos = " + str(startPos) + ", endPos = " + str(endPos))
		return Vector3.ZERO
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x,0, endPos.z))
	var yVel = sqrt(2 * gravity * (maxHeight - startPos.y))
	
	var time = yVel / gravity + sqrt(2 * gravity * (maxHeight - endPos.y)) / gravity
	var xzVel = xzDist / time
	
	var xzTheta = SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	
#	print("\"Well-behaved\" parabola: " + str( Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))))
	return Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))

func FindDownwardsParabola(startPos:Vector3, endPos:Vector3):
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var maxSetVelocity = 10
	
	var yDist = startPos.y - endPos.y
	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x, 0, endPos.z))
	var xzTheta = SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
		
	
	# Can the xzDistance be traversed by a ball set horizontally at the maximum allowable speed?
	# Can the set get down fast enough if you're setting from 10 metres in the air? 
	# for every angle there's a corresponding velocity, should we find the most aggressive?
	
	# attempt to set horizontally, zero yVel
	var yTravelTime = sqrt(yDist/gravity)
	var maxXZTravelTime = xzDist/maxSetVelocity
	
	if yTravelTime <= maxXZTravelTime:
		var xzVel = xzDist/ yTravelTime
		return Vector3(xzVel * cos(-xzTheta), 0, xzVel * sin(-xzTheta))
		
	else:
		# use max set speed
		return FindParabolaForGivenSpeed(startPos, endPos, maxSetVelocity, false)
		
		
		print("downwards parabola with yVel, not sure if that's possible, yet")

	
func SetTimeWellBehavedParabola(startPos:Vector3, endPos:Vector3, maxHeight:float):
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var setVelocity = FindWellBehavedParabola(startPos, endPos, maxHeight)
	if setVelocity.length() == 0:
		return 0
	var timeToPeak = setVelocity.y / gravity
	var timeDown = sqrt(2 * gravity * abs(maxHeight - endPos.y))/gravity
	return timeToPeak + timeDown
	
#func SetTimeWellBehavedParabolaII(startPos:Vector3, endPos:Vector3):
#	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
#	var yVel = sqrt(2 * g * abs(endPos.y - startPos.y))
#		return yVel / g + sqrt(2 * g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / g

func SetTimeDownwardsParabola(startPos:Vector3, endPos:Vector3):
	var ballVel = FindDownwardsParabola(startPos, endPos)
	if ballVel == Vector3.ZERO:
		return 0.0
		
	var ballXZDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x, 0, endPos.z))
	var ballXZVel = Vector3(ballVel.x, 0, ballVel.z).length()
	return ballXZDist/ballXZVel

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

func BallMaxHeight() -> float:
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	if linear_velocity.y<0:
		return position.y
	else:
		var timeOfFLight = linear_velocity.y/g
		var distanceToTravel = linear_velocity.y * timeOfFLight + 0.5 * g * timeOfFLight * timeOfFLight
		return position.y + distanceToTravel

func CalculateBallOverNetVelocity(startPos:Vector3, target:Vector3, heightOverNet:float):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
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


	var xzTheta = SignedAngle(Vector3(1, 0, 0), Vector3(target.x, 0, target.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	#xzTheta *= Mathf.Deg2Rad

	var velocity = Vector3(vel * cos(theta) * cos(-xzTheta), finalYVel, vel * cos(theta) * sin(-xzTheta))
	return velocity


func FindParabolaForGivenSpeed(startPos:Vector3, target:Vector3, speed:float, aimingUp:bool):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
	var xzDirection = target - startPos
	xzDirection.y = 0

	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var yDist =  target.y - startPos.y

	var idealAngle
	var angle1
	var angle2
	
	var determinant = pow(speed, 4) - g * (g * xzDist * xzDist + 2 * yDist * speed * speed)
	if determinant < 0:
		print("Can't make that parabola work mate, giving you the best we've got")
		idealAngle = PI/4
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

func Serve(startPos, _attackTarget, serveHeight, topspin):
	gravity_scale = 1 + topspin
	
	rotation = Vector3.ZERO
	if (_attackTarget - startPos).x > 0:
		topspin *= -1
	angular_velocity = Vector3 ( randf_range(-.5,.5),randf_range(-.5,.5), topspin * 80)
	#linear_velocity = Vector3.ZERO
	attackTarget = _attackTarget
	
	var impulse = CalculateBallOverNetVelocity(startPos, _attackTarget, serveHeight)

	# :( no fun!
	if impulse.length() * 3.6 > MAX_SERVE_SPEED || impulse.length_squared() == 0:
		print(str(impulse.length() * 3.6))
		impulse = FindParabolaForGivenSpeed(startPos, _attackTarget, (MAX_SERVE_SPEED - randf_range(0,10))/3.6, false)
		linear_velocity = impulse
		attackTarget = _attackTarget
		print("SERVE TOO FAST, New net pass: " + str(FindNetPass()))
		if FindNetPass().y< 2.5:
			print("serve hits net")
			Console.AddNewLine("Serve hits net!!!!!!!", Color.BLUE_VIOLET)
		print(str(impulse.length() * 3.6))
		
	
	#impulse *= mass
	linear_velocity = impulse
	if impulse.length_squared() == 0:
		attackTarget = Maths.XZVector(position)
	

	inPlay = true
		
func TouchedByB():
	wasLastTouchedByA = false
	
func TouchedByA():
	wasLastTouchedByA = true

func FindNetPass()->Vector3:
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
	var distanceFactor = position.x / (abs(position.x) + abs(attackTarget.x))
	if position.x < 0:
		distanceFactor *= -1

	var netPass:Vector3 = position + (attackTarget - position) * distanceFactor
	var timeTillNet = abs(position.x/linear_velocity.x)
	netPass.y = position.y + linear_velocity.y * timeTillNet + .5 * - g * timeTillNet * timeTillNet
	
	return netPass
