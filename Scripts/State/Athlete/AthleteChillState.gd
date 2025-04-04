extends "res://Scripts/State/AthleteState.gd"
class_name AthleteChillState


func Enter(athlete:Athlete):
	nameOfState="Chilling"
	athlete.animTree.set("parameters/state/transition_request", "moving")
	athlete.moveTarget = Vector3(athlete.position.x, 0, athlete.position.z)
	athlete.spikeState.spikeState == athlete.spikeState.SpikeState.NotSpiking
	athlete.blockState.internalBlockState == athlete.blockState.InternalBlockState.NotBlocking

func Update(athlete:Athlete):
	if !athlete.rb.freeze:
		if athlete.position.y < 0:
			athlete.rb.linear_velocity = Vector3.ZERO
			athlete.position.y = 0
			athlete.rotation = Vector3.ZERO
			athlete.rb.angular_velocity = Vector3.ZERO
			athlete.rb.freeze = true
			athlete.spikeState.spikeState == athlete.spikeState.SpikeState.NotSpiking
			athlete.blockState.internalBlockState == athlete.blockState.InternalBlockState.NotBlocking
	else:
		athlete.model.look_at(Maths.XZVector(athlete.ball.position), Vector3.UP, true)
func Exit(_athlete:Athlete):
	pass
