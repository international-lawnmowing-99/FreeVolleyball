extends Node3D

class_name MatchManager

var gameWorld:GameWorld = load("res://Scripts/World/GameWorld.gd").new()
var newMatch:NewMatchData = preload("res://Scripts/World/NewMatchData.gd").new()

@export var debugCylinder:PackedScene
@export var debugCube:PackedScene
@export var debugSphere:PackedScene
var cube
var cylinder
var sphere

var preSet:bool = true

var teamA:Team
var teamB:Team

var timer:Timer
@onready var ball = $ball

@onready var score:Score = $UI/ScoreCanvasLayer/Score
@onready var preMatchUI:PreMatchUI = $UI/PreMatchUI
@onready var teamInfoUI = $UI/TeamInfoUI
@onready var TESTteamRepresentation = $UI/TeamTacticsUICanvas/TeamTacticsUI/ServeOptionsUI/Athlete1ServeOptionsUI/CourtRepresentationUI
@onready var serveUI = $UI/ServeUI
@onready var teamTacticsUI = $UI/TeamTacticsUICanvas/TeamTacticsUI
@onready var camera = $Camera3D
@onready var liberoOptionsPanel:LiberoOptionsPanel = $UI/PreMatchUI/TeamSubstitutionUI/LiberoOptionsPanel
@onready var postMatchUI:PostMatchUI = $UI/PostMatchUI

var isTeamAServing:bool
var isPaused:bool = false
var fifthSetSwapSidesCompleted = false

func _ready():
	ball.mManager = self
	ball.blockResolver.mManager = self
	
	cube = debugCube.instantiate()
	cylinder = debugCylinder.instantiate()
	sphere = debugSphere.instantiate()
	add_child(cube)
	add_child(sphere)
	add_child(cylinder)
	
	var now = Time.get_ticks_msec()
	gameWorld.GenerateDefaultWorld(false)
	var later = Time.get_ticks_msec()
	print(str(later - now) + "ms generate world")
	
	
	preMatchUI.Init(self)
	
	camera._gui.LockCamera()

func ConfirmTeams():
	teamA.Init(self)
	teamB.Init(self)
	
	teamA.set_process(true)
	teamB.set_process(true)
	
	score.teamANameText.text = teamA.teamName
	score.teamBNameText.text = teamB.teamName
	
	$UI/sillydebug.StartDebug(teamA)
	
	for athlete:Athlete in teamA.courtPlayers:
		if athlete.rotationPosition == 1:
			teamA.originalRotation1Player = athlete
			Console.AddNewLine("Orig rot 1 for teamA is: " + teamA.originalRotation1Player.stats.lastName)
		if athlete.role != Enums.Role.Libero:
			athlete.substitutionInfo.startingRotationPosition = athlete.rotationPosition
			#Console.AddNewLine(athlete.stats.lastName + " starting in position " + str(athlete.substitutionInfo.startingRotationPosition))
		else:
			athlete.substitutionInfo.startingRotationPosition = athlete.rotationPosition
			#Console.AddNewLine(athlete.stats.lastName + " starting in position " + str(athlete.rotationPosition))
	
	for athlete:Athlete in teamB.courtPlayers:
		if athlete.rotationPosition == 1:
			teamB.originalRotation1Player = athlete
		
		if athlete.role != Enums.Role.Libero:
			athlete.substitutionInfo.startingRotationPosition = athlete.rotationPosition
			#Console.AddNewLine(athlete.stats.lastName + " starting in position " + str(athlete.substitutionInfo.startingRotationPosition))
		else:
			athlete.substitutionInfo.startingRotationPosition = athlete.rotationPosition
			#Console.AddNewLine(athlete.stats.lastName + " starting in position " + str(athlete.rotationPosition))
	
	if preMatchUI.usingAcceleratedStart:
		teamA.teamCaptain = teamA.matchPlayers[randi_range(0, teamA.matchPlayers.size() - 1)]
		
	teamB.teamCaptain = teamB.matchPlayers[randi_range(0, teamB.matchPlayers.size() - 1)]
	
func StartGame():
	preSet = false
	
	if newMatch.isTeamAServing:
		isTeamAServing = true
		teamA.isNextToSpike = true
		teamB.isNextToSpike = false
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.prereceiveState)
	else:
		teamA.isNextToSpike = false
		teamB.isNextToSpike = true
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
	
	teamTacticsUI.Init(teamA, teamB)
	liberoOptionsPanel.Init(teamA)
	
	$UI/TeamInfoUI.InitialiseOnCourtPlayerUI()
	camera._gui.UnlockCamera()
	
func StartSet():
	preSet = false
	if isTeamAServing:
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.prereceiveState)
	else:
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)

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
	if Input.is_key_pressed(KEY_Z) && !preSet:
		PointToTeamA()
	elif Input.is_key_pressed(KEY_C) && !preSet:
		PointToTeamB()
	
	if Input.is_action_just_pressed("ui_focus_next"):
		pass
		
	if Input.is_key_pressed(KEY_F2):
		if isPaused:
			UnPause()
		else:
			Pause()
		

func PointToTeamA():
	# We're already waiting to watch a ball go out of bounds, stop that and start waiting again
	if timer != null:
		CheckForFifthSetSideSwap()
		timer.free()

	if !isTeamAServing:
		teamA.Rotate()
	
	isTeamAServing = true
	
	score.PointToTeamA()
	
	Console.AddNewLine("=============================================================")
	Console.AddNewLine("Point: Score is " + score.teamAScoreText.text + ":" + score.teamBScoreText.text)
	Console.AddNewLine("=============================================================")
	
	teamA.isNextToSpike = false
	teamB.isNextToSpike = true
	
	#teamA celebrate, watch the ball bounce
	teamA.Chill()
	teamB.Chill()
	
	timer = Timer.new()
	add_child(timer)
	timer.start(1.0)
	await timer.timeout
	if !preSet:
		Console.AddNewLine("timeout ", Color.RED)
		teamA.stateMachine.SetCurrentState(teamA.preserviceState)
		teamB.stateMachine.SetCurrentState(teamB.prereceiveState)
		ball.inPlay = false

		CheckForFifthSetSideSwap()
	timer.queue_free()


func PointToTeamB():
	# We're already waiting to watch a ball go out of bounds, stop that and start waiting again
	if timer != null:
		CheckForFifthSetSideSwap()
		timer.free()
	
	if isTeamAServing:
		teamB.Rotate()
	
	isTeamAServing = false
	
	score.PointToTeamB()
	
	Console.AddNewLine("=============================================================")
	Console.AddNewLine("Point: Score is " + score.teamAScoreText.text + ":" + score.teamBScoreText.text)
	Console.AddNewLine("=============================================================")
	
	teamB.isNextToSpike = false
	teamA.isNextToSpike = true
	
	#teamB celebrate, watch the ball bounce
	teamA.Chill()
	teamB.Chill()
	
	timer = Timer.new()
	add_child(timer)
	timer.start(1.0)
	await timer.timeout
	
	if !preSet:
		teamA.stateMachine.SetCurrentState(teamA.prereceiveState)
		teamB.stateMachine.SetCurrentState(teamB.preserviceState)
		ball.inPlay = false

		CheckForFifthSetSideSwap()
		
	timer.queue_free()

func NewSet():
	teamA.Chill()
	teamB.Chill()
	
	if score.teamASetScore == 2 && score.teamBSetScore == 2:
		for i in range (32):
			Console.AddNewLine("5th set, do the toss again", Color(randf(), randf(), randf()))
	
	# If an even number of sets have been completed, the original team serves first
	Console.AddNewLine(str(score.teamASetScore + score.teamBSetScore) + " score.teamASetScore + score.teamBSetScore")
	Console.AddNewLine(str((score.teamASetScore + score.teamBSetScore) % 2) + " (score.teamASetScore + score.teamBSetScore) % 2")
	if (score.teamASetScore + score.teamBSetScore) % 2 == 0:
		isTeamAServing = newMatch.isTeamAServing
	else:
		isTeamAServing = !newMatch.isTeamAServing
		
	Console.AddNewLine(str(isTeamAServing) + " isTeamAServing", Color.RED)
	camera._gui.LockCamera()
	preSet = true
	teamA.numberOfSubsUsed = 0
	teamB.numberOfSubsUsed = 0
	$UI/TeamInfoUI/TeamSubstitutionUI.visible = true
	$UI/TeamInfoUI/TeamSubstitutionUI/TeamSubstitutionUI.EnableRotate()
	$UI/TeamInfoUI/TeamSubstitutionUI/TeamSubstitutionUI.Refresh()
	RotateTheBoard()
	#reset everyone and allow lineup changes
	pass

func GameOver(teamAWon:bool):
	postMatchUI.Show(score)
	if teamAWon:
		#celebrate
		teamA.stateMachine.SetCurrentState(teamA.celebrateState)
		teamB.stateMachine.SetCurrentState(teamB.commiserateState)
		pass
	else:
		teamB.stateMachine.SetCurrentState(teamB.celebrateState)
		teamA.stateMachine.SetCurrentState(teamA.commiserateState)
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
	
func Pause():
	Engine.time_scale = 0
	isPaused = true
	Console.AddNewLine("Game Paused - F2 to unpause")

func UnPause():
	Engine.time_scale = 1
	isPaused = false
	Console.AddNewLine("Game unpaused")

func BallBlocked(spikedByA:bool):
	await get_tree().create_timer(.25).timeout
	
	if spikedByA:
		teamA.stateMachine.SetCurrentState(teamA.receiveState)
		teamB.stateMachine.SetCurrentState(teamB.defendState)
	else:
		teamB.stateMachine.SetCurrentState(teamB.receiveState)
		teamA.stateMachine.SetCurrentState(teamA.defendState)

func PrepareLocalTeamObjects(newMatchData:NewMatchData):
	var teamANode = $TeamA
	var teamBNode = $TeamB
	
	var natTeamScript = load("res://Scripts/World/NationalTeam.gd")
	var teamScript = load("res://Scripts/Team.gd")
	
	if newMatch.clubOrInternational == Enums.ClubOrInternational.International:
		teamANode.set_script(natTeamScript)
		teamBNode.set_script(natTeamScript)
	else:
		teamANode.set_script(teamScript)
		teamBNode.set_script(teamScript)
		
	teamA = teamANode
	teamB = teamBNode
	
	teamA.isHuman = true
	teamB.isHuman = false
	teamB.flip = -1
	
	teamA.defendState.otherTeam = teamB
	teamB.defendState.otherTeam = teamA
	
	teamA.CopyGameWorldPlayers(gameWorld, newMatchData.aChoiceState, newMatchData.clubOrInternational)
	teamB.CopyGameWorldPlayers(gameWorld, newMatchData.bChoiceState, newMatchData.clubOrInternational)

func CheckForFifthSetSideSwap():
	if fifthSetSwapSidesCompleted:
		return
	if score.teamASetScore == 2 && score.teamBSetScore == 2:
		if score.teamAScore == 8 || score.teamBScore == 8:
			Console.AddNewLine("It's the 5th set, swapping sides at 8 points")
			RotateTheBoard()
			fifthSetSwapSidesCompleted = true
