extends Label

var teamA:Team
# Called when the node enters the scene tree for the first time.
func _ready():
	teamA = $"../../TeamA"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	text = str(teamA.stateMachine.currentState.nameOfState)
	pass
