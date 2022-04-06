extends Spatial

class_name MatchManager

enum GameState {

	UNDEFINED,
	BlockInProgress,
	PointJustScored
}

#var gameState = GameState.Initialisation
 
var gameWorld = load("res://Scripts/World/GameWorld.gd").new()
var isTeamAServingFirst:bool = false
var newMatch:NewMatchData = preload("res://Scripts/World/NewMatchData.gd").new()

onready var teamA:Team = $TeamA
onready var teamB:Team = $TeamB



onready var ball = $ball

func _ready():
	gameWorld.GenerateDefaultWorld()
	newMatch.ChooseRandom(gameWorld)
	
	#lel
	teamA.isHuman = true
	teamA.init(ball, newMatch.aChoiceState, gameWorld, newMatch.clubOrInternational)
	teamB.init(ball, newMatch.bChoiceState, gameWorld, newMatch.clubOrInternational)
	teamA.defendState.otherTeam = teamB
	teamB.defendState.otherTeam = teamA
	#var _zzz = connect("teamBBallOverNet", teamA, "BallHitOverNet")
	#var _zzzz = connect("teamABallOverNet", teamB, "BallHitOverNet")
	var rand = RandomNumberGenerator.new()
	rand.randomize()

	if rand.randi_range(1,2) == 1:
		pass
	isTeamAServingFirst = false

	if isTeamAServingFirst:
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.receiveState)

	else:
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)

	for athlete in teamA.allPlayers:
		athlete.translation += Vector3.UP*10


func BallOverNet(hitByTeamA:bool):
	if hitByTeamA:
		teamA.stateMachine.SetCurrentState(teamA.defendState)
		teamB.stateMachine.SetCurrentState(teamB.receiveState)
	else:
		teamB.stateMachine.SetCurrentState(teamB.defendState)
		teamA.stateMachine.SetCurrentState(teamA.receiveState)

func BallReceived(receivedByTeamA:bool):
	if receivedByTeamA:
		teamA.stateMachine.SetCurrentState(teamA.setState)
	else:
		teamB.stateMachine.SetCurrentState(teamB.setState)

func BallSet(setByTeamA:bool):
	if setByTeamA:
		teamA.stateMachine.SetCurrentState(teamA.spikeState)
	else:
		teamB.stateMachine.SetCurrentState(teamB.spikeState)

func BallSpiked(spikedByTeamA:bool):
	pass

func _input(_event):
	
	if Input.is_action_just_pressed("ui_accept"):
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
