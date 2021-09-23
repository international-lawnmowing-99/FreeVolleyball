extends Spatial

class_name MatchManager

enum GameState {

	PreService,
	MiddleBlock,
	Spike,
	BlockInProgress,
	PointJustScored
}

#var gameState = GameState.Initialisation
 
var gameWorld = load("res://Scripts/World/GameWorld.gd").new()
var isTeamAServingFirst:bool = false
#var ath = load("res://Scenes/Athlete.tscn")
onready var teamA = $TeamA
onready var teamB = $TeamB

onready var ball = $ball

func _ready():
	gameWorld.GenerateDefaultWorld()
	
	
	teamA.init(self, ball)
	teamB.init(self, ball)


	var _zzz = connect("teamBBallOverNet", teamA, "BallHitOverNet")
	var _zzzz = connect("teamABallOverNet", teamB, "BallHitOverNet")
	var rand = RandomNumberGenerator.new()
	rand.randomize()

	if rand.randi_range(0,1) == 1:
		isTeamAServingFirst = true

	
	if isTeamAServingFirst:
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.receiveState)
	
	else:
		teamA.stateMachine.SetCurrentState(teamA.receiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
		
	
	if !gameWorld:
		#gameWorld = teamA.new()
		pass
	
