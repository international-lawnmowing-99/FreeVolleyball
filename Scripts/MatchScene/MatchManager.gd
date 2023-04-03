extends Node3D

class_name MatchManager

var gameWorld = load("res://Scripts/World/GameWorld.gd").new()
var newMatch:NewMatchData = preload("res://Scripts/World/NewMatchData.gd").new()


@onready var teamA:Team = $TeamA
@onready var teamB:Team = $TeamB

@onready var ball = $ball

@onready var score = $UI/ScoreCanvasLayer/Score
@onready var preMatchUI = $UI/PreMatchUI
@onready var teamInfoUI = $UI/TeamInfoUI
@onready var TESTteamRepresentation = $UI/TeamTacticsUICanvas/TeamTacticsUI/ServeOptionsUI/Athlete1ServeOptionsUI/CourtRepresentationUI
@onready var serveUI = $UI/ServeUI
var isTeamAServing:bool

func _ready():
	var now = Time.get_ticks_msec()
	gameWorld.GenerateDefaultWorld(false)
	var later = Time.get_ticks_msec()
	print(str(later - now) + "ms generate world")
	newMatch.ChooseRandom(gameWorld)
	
	ball.mManager = self
	
	teamA.isHuman = true
	teamB.isHuman = false
	
	teamA.init(ball, newMatch.aChoiceState, gameWorld, newMatch.clubOrInternational, self)
	teamB.init(ball, newMatch.bChoiceState, gameWorld, newMatch.clubOrInternational, self)
	teamA.defendState.otherTeam = teamB
	teamB.defendState.otherTeam = teamA

	var rand = RandomNumberGenerator.new()
	rand.randomize()

	if rand.randi_range(1,2) == 1:
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
	preMatchUI.skipUI()
	$UI/TeamInfoUI.InitialiseOnCourtPlayerUI()

func _physics_process(_delta: float) -> void:
#	if ball.blockWillBeAttempted:
#		if teamA.isNextToSpike:
#			pass
	pass
	
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
		teamB.defendState.EvaluateOppositionPass(teamA)
	else:
		teamB.stateMachine.SetCurrentState(teamB.setState)
		teamA.defendState.EvaluateOppositionPass(teamA)

func BallSet(setByTeamA:bool):
	if setByTeamA:
		teamA.stateMachine.SetCurrentState(teamA.spikeState)
		teamB.defendState.ReactToSet(teamB)
	else:
		teamB.stateMachine.SetCurrentState(teamB.spikeState)
		teamA.defendState.ReactToSet(teamA)

func BallSpiked(spikedByTeamA:bool):
	if spikedByTeamA:
		teamB.AttemptBlock(teamA.chosenSpiker)
		pass
	else:
		teamA.AttemptBlock(teamB.chosenSpiker)
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
	await get_tree().create_timer(1).timeout
	
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
	await get_tree().create_timer(1).timeout
	
	teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
	teamB.stateMachine.SetCurrentState(teamB.preserviceState)
	
func SetToTeamA():
	$TeamInfoUI/TeamSelectionUI/TeamSelectionUI.EnableRotate()
	RotateTheBoard()
	#reset everyone and allow lineup changes
	pass

func SetToTeamB():
	$TeamInfoUI/TeamSelectionUI/TeamSelectionUI.EnableRotate()
	RotateTheBoard()
	pass

func GameOver(teamAWon:bool):
	if teamAWon:
		#celebrate
		pass
	else:
		pass

func RotateTheBoard():
	RotateAroundOrigin($Lights, PI)
	RotateAroundOrigin($ZoneOut, PI)
	RotateAroundOrigin($Building, PI)
	RotateAroundOrigin($ZoneOut, PI)
	
func RotateAroundOrigin(node3D, angle):
	#https://godotengine.org/qa/34248/rotate-around-a-fixed-point-in-3d-space
	var pivot_point = Vector3.ZERO
	# pivot_radius is the vector from the pivot
	# to the starting position of the object being rotated.
	# this is where the object is relative to the pivot before
	# rotation has been applied.
	var pivot_radius = node3D.position - pivot_point
	# create a transform centred at the pivot
	var pivot_transform = Transform3D(transform.basis, pivot_point)
	# first we rotate our transform.
	# Because the axes are rotated, 
	# translations will happen along those rotated axes.
	# so we can translate it using pivot_radius.
	# the position moves the object away from the
	# centre of the pivot_transform. 
	node3D.transform = pivot_transform.rotated(Vector3.UP, node3D.transform.basis.get_euler().y + angle).translated(pivot_radius)
	print(str(node3D.transform.basis.get_euler()) + "  rotating around origin")
	
