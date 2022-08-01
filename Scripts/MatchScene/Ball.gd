extends RigidBody

class_name Ball

#var g
var _parented:bool = false
var _pseudoParent
var wasLastTouchedByA:bool
var attackTarget
var mManager
var inPlay:bool = true
var isDestingedToBeBlocked = false

#var lads = Vector3(-0.5,2.5,0)

func _process(_delta):
	if is_inside_tree() && _parented && _pseudoParent:
		translation = _pseudoParent.global_transform.origin
	#lads = Vector3(-0.5,2.5,0) - transform.origin
	pass
	
func _ready():

	#DebugOverlay.draw.add_vector(self, "lads", 1, 4, Color(0,1,1, 0.5))
	
	pass
	
func _on_ball_body_entered(body):
	gravity_scale = 1
#	print (body.name)
	if inPlay:
		if body.is_in_group("ZoneOut"):
#		print("out got him yes")
			inPlay = false
			if wasLastTouchedByA:
				Console.AddNewLine("ball out, point to b")
				mManager.PointToTeamB()
				
			else:
				Console.AddNewLine("ball out, point to a")
				mManager.PointToTeamA()
		if body.is_in_group("ZoneInA"):
			inPlay = false
			mManager.PointToTeamA()
			Console.AddNewLine("Ball in, point to a")

		if body.is_in_group("ZoneInB"):
			inPlay = false
			mManager.PointToTeamB()
			Console.AddNewLine("Ball in, point to b", Color.bisque)
func PretendToBeParented(node):
	_parented = true
	_pseudoParent = node



func BallPositionAtGivenHeight(height:float):

	var timeOfFlight = TimeTillBallReachesHeight(height)
	var xzPos = Vector2(translation.x, translation.z)
	var xzVel = Vector2(linear_velocity.x, linear_velocity.z)
	var newXZPos = xzPos + xzVel * timeOfFlight

	return Vector3(newXZPos.x, height, newXZPos.y)
	
func TimeTillBallReachesHeight(height:float):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
#I'm assuming this is on the way down...
	var finalV = sqrt(linear_velocity.y * linear_velocity.y + 2 * g * (translation.y - height))
	var remainingTime = (finalV + linear_velocity.y) / g

	return remainingTime


func FindWellBehavedParabola(startPos: Vector3,endPos: Vector3, maxHeight:float):
	if maxHeight <= startPos.y || maxHeight < endPos.y:
		print("impossible parabola|| maxHeight = " + str(maxHeight) + ", startPos = " + str(startPos) + ", endPos = " + str(endPos))
		return Vector3.ZERO
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x,0, endPos.z))
	var yVel = abs(sqrt(2 * gravity * (maxHeight - startPos.y)))
	
	var time = yVel / gravity + sqrt(2 * gravity * (maxHeight - endPos.y)) / gravity
	var xzVel = xzDist / time
	
	var xzTheta = SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	
	return Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))


func SignedAngle(from, to, up):
	var cross_to = from.cross(to)
	var unsigned_angle = atan2(cross_to.length(), from.dot(to))
	var theSign = cross_to.dot(up)
	if theSign < 0:
		return -unsigned_angle
	else:
		return unsigned_angle

func BallMaxHeight():
	return 2.4

func CalculateBallOverNetVelocity(startPos:Vector3, target:Vector3, heightOverNet:float):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
	var distanceFactor = startPos.x / (abs(startPos.x) + abs(target.x))
	if startPos.x < 0:
		distanceFactor *= -1

	var netPass:Vector3 = startPos + (target - startPos) * distanceFactor
	netPass.y = heightOverNet

	var xzDistToTarget = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var xzDistToNet = Vector3(target.x, 0, target.z).distance_to(Vector3(netPass.x, 0, netPass.z))


#angle the ball wil be received on. I now have no idea how this formula was derived
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
		idealAngle = 45
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

func Serve(startPos, _attackTarget, topspin):
		gravity_scale = 1 + topspin
		
		rotation = Vector3.ZERO
		if (_attackTarget - startPos).x > 0:
			topspin *= -1
		angular_velocity = Vector3 ( rand_range(-.5,.5),rand_range(-.5,.5), topspin * 80)
		linear_velocity = Vector3.ZERO
		
		var impulse = CalculateBallOverNetVelocity(startPos, _attackTarget, 2.6)
		impulse *= mass
		linear_velocity = impulse
		
		attackTarget = _attackTarget
		inPlay = true
		
func TouchedByB():
	wasLastTouchedByA = false
	
func TouchedByA():
	wasLastTouchedByA = true

func FindNetPass()->Vector3:
	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
	var distanceFactor = translation.x / (abs(translation.x) + abs(attackTarget.x))
	if translation.x < 0:
		distanceFactor *= -1

	var netPass:Vector3 = translation + (attackTarget - translation) * distanceFactor
	var timeTillNet = abs(translation.x/linear_velocity.x)
	netPass.y = translation.y + linear_velocity.y * timeTillNet + .5 * - g * timeTillNet * timeTillNet
	
	print(netPass)
	
	return netPass
