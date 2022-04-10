extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Chilling"
	athlete.rb.mode = RigidBody.MODE_KINEMATIC
	athlete.rb.gravity_scale = 0
	athlete.rb.linear_velocity = Vector3.ZERO
	athlete.translation.y = 0
	pass
func Update(athlete:Athlete):
	#athlete.rotate_y(0.5)
	pass
func Exit(athlete:Athlete):
	pass
