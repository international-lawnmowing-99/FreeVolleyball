extends Spatial

class_name MatchManager

var gameWorld = load("res://Scripts/World/GameWorld.gd").new()
var newMatch:NewMatchData = preload("res://Scripts/World/NewMatchData.gd").new()

onready var teamA:Team = $TeamA
onready var teamB:Team = $TeamB

onready var ball = $ball

onready var score = $CanvasLayer/Score
onready var preMatchUI = $PreMatchUI
#onready var teamInfoUI = 

var isTeamAServing:bool

func _ready():
	gameWorld.GenerateDefaultWorld()
	newMatch.ChooseRandom(gameWorld)
	
	ball.mManager = self
	
	teamA.isHuman = true
	teamB.isHuman = false
	
	teamA.init(ball, newMatch.aChoiceState, gameWorld, newMatch.clubOrInternational)
	teamB.init(ball, newMatch.bChoiceState, gameWorld, newMatch.clubOrInternational)
	teamA.defendState.otherTeam = teamB
	teamB.defendState.otherTeam = teamA

	var rand = RandomNumberGenerator.new()
	rand.randomize()

	if rand.randi_range(1,2) == 0:
		isTeamAServing = false
		teamA.isNextToSpike = false
		teamB.isNextToSpike = true
	else:
		isTeamAServing = true
		teamA.isNextToSpike = true
		teamB.isNextToSpike = false

	if isTeamAServing:
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.prereceiveState)

	else:
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)

	
	score.teamANameText.text = teamA.teamName
	score.teamBNameText.text = teamB.teamName
	
	preMatchUI.PopulateUI(teamA, teamB)
	#preMatchUI.skipUI()

func BallOverNet(hitByTeamA:bool):
	teamA.isNextToSpike = !teamA.isNextToSpike
	teamB.isNextToSpike = !teamB.isNextToSpike
	
	if hitByTeamA:
		ball.wasLastTouchedByA = true
		teamA.stateMachine.SetCurrentState(teamA.defendState)
		teamB.stateMachine.SetCurrentState(teamB.receiveState)
	else:
		ball.wasLastTouchedByA = false
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
	if spikedByTeamA:
		pass
func _input(_event):
#	if Input.is_action_just_pressed("ui_accept"):
#		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
#		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
	if Input.is_key_pressed(KEY_Z):
		PointToTeamA()
	elif Input.is_key_pressed(KEY_C):
		PointToTeamB()
	
	if Input.is_action_just_pressed("ui_focus_next"):
		pass

func PointToTeamA():
	score.PointToTeamA()
	teamA.isNextToSpike = false
	
	if !isTeamAServing:
		teamA.Rotate()
	isTeamAServing = true
	
	#teamA celebrate, watch the ball bounce
	teamA.Chill()
	teamB.Chill()
	yield(get_tree().create_timer(1), "timeout")
	
	teamA.stateMachine.SetCurrentState(teamA.preserviceState)
	teamB.stateMachine.SetCurrentState(teamB.prereceiveState)
	
func PointToTeamB():
	score.PointToTeamB()
	teamB.isNextToSpike = false
	
	if isTeamAServing:
		teamB.Rotate()
	isTeamAServing = false
	
	#teamB celebrate, watch the ball bounce
	teamA.Chill()
	teamB.Chill()
	yield(get_tree().create_timer(1), "timeout")
	
	teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
	teamB.stateMachine.SetCurrentState(teamB.preserviceState)
	
func SetToTeamA():
	#reset everyone and allow lineup changes
	pass

func SetToTeamB():
	pass

func GameOver(teamAWon:bool):
	if teamAWon:
		#celebrate
		pass
	else:
		pass
