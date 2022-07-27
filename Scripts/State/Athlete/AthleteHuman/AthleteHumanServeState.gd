extends "res://Scripts/State/AthleteState.gd"

enum ServeState{
NotServing,
Walking,
Aiming,
Tossing,
WatchingTheBallInTheAir,
Runup,
Jump,
Landing
}

enum ServeType{
	UNDEFINED,
	Jump,
	Float,
	Underarm
}

enum ServeAggression{
	UNDEFINED,
	Controlled,
	Moderate,
	Aggressive
	}

var serveState = ServeState.NotServing
var serveAggression = ServeAggression.UNDEFINED
var serveType = ServeType.UNDEFINED
var serveTarget
var serveUI
	
func Enter(athlete:Athlete):
	nameOfState="HumanServe"
	
	serveState = ServeState.Walking
	serveTarget = athlete.get_tree().root.get_node("MatchScene").get_node("ServeTarget")
	serveUI = athlete.get_tree().root.get_node("MatchScene").get_node("ServeUI")
	
	serveUI.humanServeState = self
	serveUI.ShowServeChoice()
	
func Update(athlete:Athlete):
	
	match serveState:
		ServeState.Walking:
			if Input.is_key_pressed(KEY_I):
				athlete.moveTarget.x -= .1
			if Input.is_key_pressed(KEY_J):
				athlete.moveTarget.z += .1
			if Input.is_key_pressed(KEY_L):
				athlete.moveTarget.z -= .1
			if Input.is_key_pressed(KEY_K):
				athlete.moveTarget.x += .1
			
			if Input.is_key_pressed(KEY_SPACE):
				serveState = ServeState.Aiming
			
			pass
		ServeState.Aiming:
			if Input.is_key_pressed(KEY_I):
				serveTarget.translation.x -= .1
			if Input.is_key_pressed(KEY_J):
				serveTarget.translation.z += .1
			if Input.is_key_pressed(KEY_L):
				serveTarget.translation.z -= .1
			if Input.is_key_pressed(KEY_K):
				serveTarget.translation.x += .1
				
			if Input.is_key_pressed(KEY_SPACE):
				serveState = ServeState.Aiming
				
func CommenceServe():
	pass


func Exit(athlete:Athlete):
	pass
