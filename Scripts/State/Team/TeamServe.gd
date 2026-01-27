extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamServe


func Enter(team:TeamNode):
	super.Enter(team)
	nameOfState = "Serve"
	var athleteToServe:Athlete = team.courtPlayerNodes[team.server]
	athleteToServe.stateMachine.SetCurrentState(athleteToServe.serveState)

	pass
func Update(team:TeamNode):
	pass
func Exit(_team:TeamNode):
	pass
