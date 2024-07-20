extends Label

var teamA:TeamNode
var running:bool = false
# Called when the node enters the scene tree for the first time.
func StartDebug(team:TeamNode):
	teamA = team
	running = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if running:
		text = str(teamA.stateMachine.currentState.nameOfState)
