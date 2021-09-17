extends Spatial

signal ballPassed


#onready var anim = $AnimationPlayer2

onready var target = $Target

onready var animTree = $AnimationTree

var matchManager:MatchManager
var ball:Ball
var skel:Skeleton

var spineBone01Id
var spineBone02Id
var neckBone01Id
var neckBone02Id

var customPose01
var customPose02
var customPoseNeck01
var customPoseNeck02

var basisx = transform.basis.z
var anglewanted = transform.basis.y

#func play_randomized(animation_name : String):
	#randomize()
	#anim.play(animation_name)
	#var offset : float = rand_range(0, anim.current_animation_length)
	#anim.advance(offset)
var digAngle = 0
var timeTillBallReachesMe = 9999


func _ready():
	
	#DebugOverlay.draw.add_vector(self, "basisx", 1, 4, Color(0,1,0, 0.5))
	#DebugOverlay.draw.add_vector(self, "anglewanted", 1, 4, Color(1,1,0, 0.5))
	
	skel = get_node("godette volleyball/Skeleton")
	spineBone01Id = skel.find_bone("spine01")
	spineBone02Id = skel.find_bone("spine02")
	neckBone01Id = skel.find_bone("neck01")
	neckBone02Id = skel.find_bone("neck02")
	
	customPose01 = skel.get_bone_custom_pose(spineBone01Id)
	customPose02 = skel.get_bone_custom_pose(spineBone02Id)
	customPoseNeck01 = skel.get_bone_custom_pose((neckBone01Id))
	customPoseNeck02 = skel.get_bone_custom_pose((neckBone02Id))

	#print(spineBoneId)
	#Engine.time_scale = .1
	#play_randomized("Idle take 1")
	pass
func _physics_process(_delta):
	if ball.translation.y < 1 && \
		(Vector3(ball.translation.x,0, ball.translation.z)).distance_to(translation) < 1\
		&& matchManager.gameState == MatchManager.GameState.Receive:
	#	if ball.translation.distance_to(self.translation) < 1 && matchManager.gameState == matchManager.GameState.Receive:
			PassBall()
		
func _process(_delta):

	if matchManager.gameState == matchManager.GameState.Receive && ball.linear_velocity.x!=0:
		timeTillBallReachesMe = Vector3(ball.translation.x, 0, ball.translation.z).distance_to(Vector3(translation.x, 0, translation.z))\
				/Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length()
		var animFactor = 1.3-  timeTillBallReachesMe 
		animTree.set("parameters/BlendSpace1D/blend_position", animFactor)
		RotateDigPlatform(lerp(0,digAngle,(min(1,1/timeTillBallReachesMe - 2))))
	else:
		var a = animTree.get("parameters/BlendSpace1D/blend_position")
		animTree.set("parameters/BlendSpace1D/blend_position", lerp(a, 0, 5*_delta))
		digAngle = lerp(digAngle,0,3*_delta)
		RotateDigPlatform(digAngle)
func PassBall():
	#Engine.time_scale = 0.25
	matchManager.gameState = MatchManager.GameState.Set
	emit_signal("ballPassed")
	
	ball.linear_velocity = Vector3.ZERO
	ball.gravity_scale = 1

	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, Vector3(-0.5, 2.5, 0), rand_range(3,9)))
	yield(get_tree(),"idle_frame")
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, Vector3(-0.5, 2.5, 0), rand_range(3,9)))

func RotateDigPlatform(angle):
	
	var acustomPose01 = customPose01.rotated(Vector3.UP, deg2rad(angle/2))
	var acustomPose02 = customPose02.rotated(Vector3.UP, deg2rad(angle/2))
	var acustomPoseNeck01 = customPoseNeck01.rotated(Vector3.UP, deg2rad(-angle/2))
	var acustomPoseNeck02 = customPoseNeck02.rotated(Vector3.UP, deg2rad(-angle/2))
	
	skel.set_bone_custom_pose(spineBone01Id, acustomPose01)
	skel.set_bone_custom_pose(spineBone02Id, acustomPose02)
	skel.set_bone_custom_pose(neckBone01Id, acustomPoseNeck01)
	skel.set_bone_custom_pose(neckBone02Id, acustomPoseNeck02)


func _on_ServingMachine_ballServed(_attackTarget, servePos):

	translation =  ball.BallPositionAtGivenHeight(0.9) + Vector3(0,-.9, rand_range(-.5,.51))
	look_at(Vector3(servePos.x,0, servePos.z), Vector3.UP)
	rotate(Vector3.UP, PI)
	basisx = transform.basis.z
	
	#var ballPassingV3 = ball.BallPositionAtGivenHeight(.85)
	#translation = attackTarget
	#var moveFactor = Vector3(ballPassingV3.x,0, ballPassingV3.z).distance_to( attackTarget)/1.5
	
	translate(transform.basis.x/2)# * moveFactor)
	
	#point where a circle will intersect with the xz vector of the ball's motion
	#circle is (x-h)^2 + (y-k)^2 = r^2
	var h = translation.x
	var k = translation.z
	var r = .66 #Dig radius is this much?
	#line is ...
	var xPart = ball.linear_velocity.x
	var zPart = ball.linear_velocity.z # (It's y!)
	
	
	
	
	var m
	if xPart == 0 && zPart == 0:
		pass
		#print("no vel to work with")
	elif zPart == 0:
		m = 0
		#print("m = 0")
	elif xPart == 0:
		m = 999999
		#print("m = big")
	else:
		m = zPart/xPart 
	#y=mx+b
	#b = y - mx
	var b = servePos.z - m * servePos.x
	
	#Will the two meet??
	# circle = line 
	
	var aDet = m*m + 1
	var bDet = -2*h + 2*m*b - 2*k*m
	var cDet = h*h + b*b + k*k -2*k*b - r*r
	
	var determinate = bDet * bDet - 4 *aDet * cDet
	
	var intersectionPointX
	
	if determinate == 0:
		#Congrats, you have a tangent
		intersectionPointX = (-bDet + sqrt(determinate))/(2*aDet)
	elif determinate > 0:
		# Choose t
		var point1x =  (-bDet + sqrt(determinate))/(2*aDet)
		var point2x = (-bDet - sqrt(determinate))/(2*aDet)
		intersectionPointX = max(point1x, point2x)
	else:
		# No intersections
		intersectionPointX = h
		print("can't make that work chap")
		
	var intersectionPointZ = m*intersectionPointX + b
	
	#get_node("../target").translation =  Vector3(intersectionPointX,0,intersectionPointZ)
	
	digAngle = rad2deg(  ball.SignedAngle(transform.basis.z, -translation + Vector3(intersectionPointX,0,intersectionPointZ), Vector3.UP))

	anglewanted = - translation + Vector3(intersectionPointX,0,intersectionPointZ)
	
