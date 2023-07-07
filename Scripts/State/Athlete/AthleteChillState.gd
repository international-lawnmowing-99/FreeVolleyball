extends "res://Scripts/State/AthleteState.gd"
class_name AthleteChillState


func Enter(athlete:Athlete):
	nameOfState="Chilling"
#	athlete.animTree.set("parameters/state/transition_request", "moving")
	athlete.moveTarget = Vector3(athlete.position.x, 0, athlete.position.z)
	
	# bizzare bug where if players are airborne when a point is scored they 
	# rescale to 1,1,1 if a point is scored
	athlete.scale = Vector3(athlete.stats.height /1.8, athlete.stats.height /1.8, athlete.stats.height /1.8)
	# well it sort of works, even though players are still super-sizing...
		
func Update(athlete:Athlete):
	if !athlete.rb.freeze:
		if athlete.position.y < 0:
			#athlete.rb.linear_velocity = Vector3.ZERO
			athlete.position.y = 0
			#athlete.rotation = Vector3.ZERO
#			athlete.rb.angular_velocity = Vector3.ZERO
			athlete.rb.freeze = true
	
	pass
	### !!! Something associated with this causes the athletes to rescale to 1,1,1
	### Why???
	### It happens when every indiviual line is switched off

	
#	if athlete.position.y < 0:
#
#
#		athlete.rb.gravity_scale = 0
#
#		athlete.position = Vector3(athlete.position.x, 0, athlete.position.z)#.y = 0
#		athlete.rb.angular_velocity = Vector3.ZERO
#		athlete.rb.freeze = true
#		athlete.rb.linear_velocity = Vector3.ZERO

func Exit(_athlete:Athlete):
	pass
