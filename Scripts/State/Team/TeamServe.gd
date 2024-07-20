extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamServe


func Enter(team:TeamNode):
	super.Enter(team)
	nameOfState = "Serve"
	var athleteToServe:Athlete = team.courtPlayerNodes[team.server]
	athleteToServe.stateMachine.SetCurrentState(athleteToServe.serveState)

	pass
func Update(team:TeamNode):
	if team.ball.get_parent():
		# Reparenting just doesn't work yet, come back in 4.0
		pass
func Exit(_team:TeamNode):
	pass
