extends Spatial

class_name MatchManager

enum GameState {
	Initialisation,
	PreService,
	Service,
	Receive,
	Set,
	MiddleBlock,
	Spike,
	BlockInProgress,
	PointJustScored
}

var gameState = GameState.Initialisation
 
var gameWorld #= #preload()

var teamA# = preload("res://Scripts/HumanTeam.gd")
var teamB# = preload("res://Scripts/ComputerTeam.gd")


func _on_ServingMachine_ballServed(_a,_b):
	gameState = GameState.Receive
	pass # Replace with function body.
func _ready():
	if !gameWorld:
		#gameWorld = teamA.new()
		pass
	
