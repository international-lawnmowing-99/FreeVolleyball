extends RigidBody3D

class_name Ball

#var g
var _parented:bool = false
var _pseudoParent
var wasLastTouchedByA:bool
var attackTarget
var mManager:MatchManager
var inPlay:bool = true
var blockWillBeAttempted = false
var blockResolver = load("res://Scripts/MatchScene/BlockResolver.gd").new(self)

var floating:bool = false
var floatDisplacement:Vector3 = Vector3.ZERO
@onready var mesh = $CollisionShape3D/ballv2

var topspin:float = 1.0
const MAX_SERVE_SPEED = 140
var difficultyOfReception:float = 0
#var lads = Vector3(-0.5,2.5,0)

func _process(_delta):
	if floating:
		if mesh.position.distance_to(floatDisplacement) < 0.1:
			floatDisplacement = Vector3(0, randf_range(-.3,.3), randf_range(-.3,.3))
			#ball will be passed at 0.5 metres high for now...
	floatDisplacement = lerp(floatDisplacement, Vector3.ZERO, _delta /min(.1,abs(position.y - 0.5)))
	if position.y <= 0.5:
		floatDisplacement = Vector3.ZERO
		floating = false
	mesh.position = lerp(mesh.position, floatDisplacement, _delta * 4.5)
		
	if position.y < -10:
		if wasLastTouchedByA:
			mManager.PointToTeamB()
		else:
			mManager.PointToTeamA()
	
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
		elif body.is_in_group("Net"):
			Console.AddNewLine("Netflipper", Color.CORAL)
		
func PretendToBeParented(node):
	_parented = true
	_pseudoParent = node

	
#func SetTimeWellBehavedParabolaII(startPos:Vector3, endPos:Vector3):
#	var g = ProjectSettings.get_setting("physics/3d/default_gravity") * (gravity_scale)
#	var yVel = sqrt(2 * g * abs(endPos.y - startPos.y))
#		return yVel / g + sqrt(2 * g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / g

func Serve(startPos, _attackTarget, serveHeight, _topspin):
	mManager.cube.position = Vector3.ZERO
	mManager.sphere.position = Vector3.ZERO
	mManager.cylinder.position = Vector3.ZERO
	
	topspin = _topspin
	var visualTopspin = topspin - 1
	gravity_scale = topspin
	
	rotation = Vector3.ZERO
	if (_attackTarget - startPos).x > 0:
		visualTopspin *= -1
	angular_velocity = Vector3 ( randf_range(-.5,.5),randf_range(-.5,.5), visualTopspin * 80)
	#linear_velocity = Vector3.ZERO
	attackTarget = _attackTarget
	
	var impulse = Maths.CalculateBallOverNetVelocity(startPos, _attackTarget, serveHeight, gravity_scale)

	# :( no fun!
	if impulse.length() * 3.6 > MAX_SERVE_SPEED || impulse.length_squared() == 0:
		print(str(impulse.length() * 3.6))
		impulse = Maths.FindParabolaForGivenSpeed(startPos, _attackTarget, (MAX_SERVE_SPEED - randf_range(0,10))/3.6, false, topspin)
		linear_velocity = impulse
		attackTarget = _attackTarget
		print("SERVE TOO FAST, New net pass: " + str(Maths.FindNetPass(position, attackTarget, linear_velocity, gravity_scale)))
		if Maths.FindNetPass(position, attackTarget, linear_velocity, gravity_scale).y< 2.5:
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
