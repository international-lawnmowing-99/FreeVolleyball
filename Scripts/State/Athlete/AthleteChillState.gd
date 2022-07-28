extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Chilling"

	if athlete.rb.mode == RigidBody.MODE_KINEMATIC:
		athlete.rb.mode = RigidBody.MODE_KINEMATIC
		athlete.rb.gravity_scale = 0
		athlete.rb.linear_velocity = Vector3.ZERO
		athlete.translation.y = 0
		athlete.rotation = Vector3.ZERO
		athlete.rb.angular_velocity = Vector3.ZERO
		
	pass
func Update(athlete:Athlete):
	if athlete.translation.y < 0.05:
		athlete.rb.mode = RigidBody.MODE_KINEMATIC
		athlete.rb.gravity_scale = 0
		athlete.rb.linear_velocity = Vector3.ZERO
		athlete.translation.y = 0
		athlete.rotation = Vector3.ZERO
		athlete.rb.angular_velocity = Vector3.ZERO


func Exit(athlete:Athlete):
	pass
