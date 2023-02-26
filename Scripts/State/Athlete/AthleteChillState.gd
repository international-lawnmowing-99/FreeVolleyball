extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Chilling"

	if athlete.rb.freeze:
		athlete.rb.linear_velocity = Vector3.ZERO
		athlete.position.y = 0
		#athlete.rotation = Vector3.ZERO
		athlete.rb.angular_velocity = Vector3.ZERO
		
func Update(athlete:Athlete):
	if athlete.position.y < 0.05:
		athlete.rb.freeze = true
		athlete.rb.gravity_scale = 0
		athlete.rb.linear_velocity = Vector3.ZERO
		athlete.position.y = 0
		#athlete.rotation = Vector3.ZERO
		athlete.rb.angular_velocity = Vector3.ZERO


func Exit(_athlete:Athlete):
	pass
