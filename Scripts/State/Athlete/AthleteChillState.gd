extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Chilling"

	if athlete.rb.freeze:
		athlete.rb.linear_velocity = Vector3.ZERO
		athlete.position.y = 0
		#athlete.rotation = Vector3.ZERO
		athlete.rb.angular_velocity = Vector3.ZERO
		
func Update(athlete:Athlete):
	### !!! This causes the athletes to rescale to 1,1,1
	### Why???
	### It happens when every indiviual line is switched off
	### Id doesn't happen when the whole thing is removed, or if just angular and linear velocity are set to zero and nothing else
	
	if athlete.position.y < 0:


		athlete.rb.gravity_scale = 0

		athlete.position = Vector3(athlete.position.x, 0, athlete.position.z)#.y = 0
		athlete.rb.angular_velocity = Vector3.ZERO
		athlete.rb.freeze = true
		athlete.rb.linear_velocity = Vector3.ZERO

func Exit(_athlete:Athlete):
	pass
