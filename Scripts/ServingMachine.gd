extends Node

signal ballServed

onready var ball:RigidBody = get_node("../ball")
onready var targetModel = get_node("../new new woman")
onready var attackTargetModel = get_node("../target")
onready var posAt12 = get_node("../target2")



func _ready():
	#Engine.time_scale = 0.2
	targetModel.get_node("Target").realTarget = ball
	targetModel.ball = ball
	targetModel.matchManager = get_node("../")
	randomize()
	pass


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		LaunchBall()
		
func LaunchBall():
	if !ball:
		print("no balls")
	else:
		
		var topspin = rand_range(.5,1.8)
		ball.gravity_scale = 1 + topspin
		
		ball.rotation = Vector3.ZERO
		ball.angular_velocity = Vector3 ( rand_range(-.5,.5),rand_range(-.5,.5), topspin * 80)
		ball.linear_velocity = Vector3.ZERO
		
		ball.translation = self.translation + Vector3(0,rand_range(3.4,3.5),0)
		#print (str(ball.translation.y) + " height, " + str(topspin) + " topspin")
		var attackTarget = Vector3(rand_range(-1,-9), 0, rand_range(-4.5,4.5))

		
		var impulse = ball.CalculateBallOverNetVelocity(ball.translation, attackTarget, 2.6)
		impulse *= ball.mass
		ball.linear_velocity = impulse
		#print(str(impulse.length()*3.6))
		
		emit_signal("ballServed", attackTarget, ball.translation)
		attackTargetModel.translation = attackTarget
#		yield(get_tree(), "idle_frame")
		

		
