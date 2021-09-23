extends Node

class_name Team


var AthleteScene = preload("res://Scenes/Athlete.tscn")

var teamName:String

var isLiberoOnCourt:bool
var isNextToAttack:bool
var markUndoChangesToRoles:bool

var allPlayers = []
var courtPlayers = []
var benchPlayers = []

var setter
var middleBack
var outsideBack
var oppositeHitter
var middleFront
var outsideFront
var libero

var chosenSetter
var chosenSpiker
var chosenReceiver

var leftSideBlocker
var rightSideBlocker

var defaultReceiveRotations =  [
	[
		Vector3(5.5, 0, 4),
		Vector3(5.0, 0, 2.8),
		Vector3(3, 0, -1.3),
		Vector3(3.5, 0, -4),
		Vector3(5.3, 0, -2.6),
		Vector3(6.5, 0, 0)
	],
	[
		Vector3(5.5, 0, 1),
		Vector3(3.0, 0, 3.8),
		Vector3(.5, 0, 2.5),
		Vector3(3.5, 0, -4),
		Vector3(5, 0, -1),
		Vector3(1, 0, 0)
	],
	[#setter in 5
		Vector3(5.5, 0, 3.25),
		Vector3(2.75, 0, 3.0),
		Vector3(5, 0, -2.5),
		Vector3(.5, 0, -4),
		Vector3(1.5, 0, -1.3),
		Vector3(6.5, 0, 0)
	],
	[#setter 4
		Vector3(5.5, 0, 4),
		Vector3(5.0, 0, -2.5),
		Vector3(2.75, 0, -3.25),
		Vector3(.5, 0, -4),
		Vector3(6.5, 0, 0),
		Vector3(5, 0, 3.5)
	],
	[#setter 3
		Vector3(5.5, 0, 2.75),
		Vector3(2.75, 0, 1),
		Vector3(5, 0, 0),
		Vector3(4.5, 0, -2.5),
		Vector3(6.5, 0, 0),
		Vector3(7.5, 0, 1.75)
	],
	[
		Vector3(5.5, 0, 3),
		Vector3(.5, 0, 0),
		Vector3(5, 0, -2.75),
		Vector3(1.5, 0, -3.75),
		Vector3(7.75, 0, -.6),
		Vector3(6.5, 0, 0)
	]
]

var server:int = 0

var flip = 1

var receptionTarget:Vector3
var setTarget:Set

var timeTillDigTarget:float

var mManager:MatchManager
var ball:Ball
# Setter in 1 so outside, middle, oppo etc in 2,3,4...
var transitionPositionsSetterBack = [ Vector3(0.5, 0, 0), Vector3(4, 0, 3.75), Vector3(4, 0, 0), Vector3(4, 0, -3.75), Vector3(8, 0, 0), Vector3(5.5, 0, -3.15) ]
#    //Setter in 4
var transitionPositionsSetterFront = [Vector3(7.75, 0, 4), Vector3(8, 0, 0), Vector3(5.5, 0, -3.15), Vector3(0.5, 0, 0), Vector3(4, 0, -3.5), Vector3(4, 0, 0) ]
var defaultPositions = [
	Vector3(6,0,-4),
	Vector3(2,0,-4),
	Vector3(2,0,0),
	Vector3(2,0,4),
	Vector3(6,0,4),
	Vector3(6,0,0)]

var defaultDefensivePositions = [
	Vector3(5.5, 0, -2.2),
	Vector3(.5,0,-3),
	Vector3(.5,0,0),
	Vector3(.5,0,3),
	Vector3(5.5,0,2.2),
	Vector3(7.5,0,0)]
	
var stateMachine:StateMachine = load("res://Scripts/State/StateMachine.gd").new(self)
var serveState:State = load("res://Scripts/State/TeamServe.gd").new()
var receiveState:State = load("res://Scripts/State/TeamReceive.gd").new()
var setState:State = load("res://Scripts/State/TeamState.gd").new()
var spikeState:State = load("res://Scripts/State/TeamSpike.gd").new()
var preserviceState:State = load("res://Scripts/State/TeamPreService.gd").new()

#var serveState:State = load("res://Scripts/State/TeamServe.gd").new()

func init(mM, _ball):
	mManager = mM
	ball = _ball
	
	stateMachine._init(self)
	stateMachine.SetCurrentState(serveState)
	
	
	AutoSelectTeamLineup()
	
	CachePlayers()

func PlaceTeam():
	for i in range(12):
		var pos
		var rot

		if i < 6:
			pos = flip * defaultPositions[i]
			rot = Vector3(0, flip*-PI/2, 0)

		else:

			#//bench
			pos = Vector3(flip * (i + 3), 0, 10)
			rot = Vector3(0,flip*PI,0)

		var lad = AthleteScene.instance()
		
		add_child(lad)
		lad.name = str(i + 1) + " " + self.name 
		lad.translation = pos
		lad.rotation = rot
		
		allPlayers.append(lad)
		
		if i  < 6 :
			lad.rotationPosition = i + 1
			courtPlayers.append(lad)
		else:
			benchPlayers.append(lad)
		
		if i == 6:
			libero = lad
			lad.rotate_y(18)


func xzVector(vec:Vector3):
	return Vector3(vec.x, 0, vec.z)

func UpdateTimeTillDigTarget():
	return
	if (mManager.gameState == MatchManager.GameState.Set):
		timeTillDigTarget = xzVector(ball.translation).distance_to(xzVector(receptionTarget)) / xzVector(ball.linear_velocity).length();

	elif mManager.gameState == mManager.GameState.Spike:
		timeTillDigTarget = 0;

	elif mManager.gameState == mManager.GameState.Receive:
		timeTillDigTarget = 12345;

	else:
		timeTillDigTarget = 54321;
		
func CacheBlockers():
	if setter.FrontCourt():	
		rightSideBlocker = setter;
		leftSideBlocker = outsideFront;

	else:
		if markUndoChangesToRoles:
			rightSideBlocker = outsideFront;
			leftSideBlocker = oppositeHitter;
		else:
			rightSideBlocker = oppositeHitter;
			leftSideBlocker = outsideFront;

func SpikeBall():
	pass

func Rotate():
	if markUndoChangesToRoles:
		outsideFront.roleCurrentlyPerforming = Athlete.Role.Outside;
		oppositeHitter.roleCurrentlyPerforming = Athlete.Role.Opposite;
		markUndoChangesToRoles = false;
	
	server += 1
	if server >= 6:
		
		server = 0
	
	for athlete in courtPlayers:
		if athlete.rotationPosition == 1:
			athlete.rotationPosition = 6
		else:
			athlete.rotationPosition -= 1
			
	CheckForLiberoChange();
	CachePlayers();

func BallHitOverNet():
	stateMachine.SetCurrentState(receiveState)

func CheckForLiberoChange():
#// if the libero is entering the frontcourt, get rid of them
	if isLiberoOnCourt && libero.FrontCourt():
		InstantaneouslySwapPlayers(libero, benchPlayers[0]);
		isLiberoOnCourt = false;

#// if the back middle isn't serving, get rid of them
	if !isLiberoOnCourt && middleBack:
		if !isNextToAttack:
			if middleBack != courtPlayers[server]:
				InstantaneouslySwapPlayers(middleBack, libero);
				isLiberoOnCourt = true;

			else:
				return
		else:
			InstantaneouslySwapPlayers(middleBack, libero);
			isLiberoOnCourt = true;

func InstantaneouslySwapPlayers(outgoing, incoming):

	var tempPos = incoming.translation
	incoming.translation = outgoing.translation
	outgoing.translation = tempPos

	incoming.rotationPosition = outgoing.rotationPosition
	outgoing.rotationPosition = -1

	courtPlayers.append(incoming)
	benchPlayers.append(outgoing)

	courtPlayers.remove(outgoing)
	benchPlayers.remove(incoming)

	if (incoming.roleCurrentlyPerforming != Athlete.Role.Libero && outgoing.roleCurrentlyPerforming != Athlete.Role.Libero):

		incoming.roleCurrentlyPerforming = outgoing.roleCurrentlyPerforming;

		incoming.moveTarget = incoming.translation;
		outgoing.moveTarget = outgoing.translation;

		var tempRot = incoming.rotation;
		incoming.rotation = outgoing.rotation;
		outgoing.rotation = tempRot;
		outgoing.Chill()

func CachePlayers():
	for player in courtPlayers:
		if player.role == Athlete.Role.Setter:
			setter = player
		elif player.role == Athlete.Role.Middle && player.FrontCourt():
			middleFront = player
		elif player.role == Athlete.Role.Middle && !player.FrontCourt():
			middleBack = player
		elif player.role == Athlete.Role.Outside && player.FrontCourt():
			outsideFront = player
		elif player.role == Athlete.Role.outside && !player.FrontCourt():
			outsideBack = player
		elif player.role == Athlete.Role.Opposite:
			oppositeHitter = player

func AutoSelectTeamLineup():
	var orderedSetterList = allPlayers.sort_custom(Athlete, "SortSet")
	var orderedOutsideList = allPlayers.sort_custom(Athlete, "SortOutside")
	var orderedLiberoList = allPlayers.sort_custom(Athlete, "SortLibero")
	var orderedOppositeList = allPlayers.sort_custom(Athlete, "SortOpposite")
	var orderedMiddleList = allPlayers.sort_custom(Athlete, "SortMiddle")

	var aptitudeLists = [orderedSetterList,orderedLiberoList,orderedOutsideList,orderedOppositeList,orderedMiddleList]


	var nsetter = orderedSetterList[0]
	SwapPlayer(nsetter, 0)
	nsetter.role = Athlete.Role.Setter
	for list in aptitudeLists:
		list.Remove(setter)

	var middle1 = orderedMiddleList[0]
	var middle2 = orderedMiddleList[1]
	middle1.role = Athlete.Role.Middle
	middle2.role = Athlete.Role.Middle
	SwapPlayer(middle1, 2)
	SwapPlayer(middle2, 5)
	for list in aptitudeLists:
		list.Remove(middle1)
		list.Remove(middle2)
	var outside1 = orderedOutsideList[0]
	var outside2 = orderedOutsideList[1]
	outside1.role = Athlete.Role.Outside
	outside2.role = Athlete.Role.Outside
	SwapPlayer(outside1, 1)
	SwapPlayer(outside2, 4)
	for list in aptitudeLists:
		list.Remove(outside1)
		list.Remove(outside2)
	var opposite = orderedOppositeList[0]
	opposite.role = Athlete.Role.Opposite
	SwapPlayer(opposite, 3)
	for list in aptitudeLists:
		list.Remove(opposite)
	var nlibero = orderedLiberoList[0]
	nlibero.role = Athlete.Role.Libero
	SwapPlayer(nlibero, 6)
	for list in aptitudeLists:
		list.Remove(libero)
	var backupSetter = orderedSetterList[0]
	SwapPlayer(backupSetter, 7)
	backupSetter.role = Athlete.Role.Setter
	for list in aptitudeLists:
		list.Remove(backupSetter)

func SwapPlayer(player,newPostion):
	var index = -1;
	for i in range(allPlayers.size()):
		if (allPlayers[i] == player):
			index = i;
			break

	var temp = allPlayers[newPostion]
	allPlayers[newPostion] = player
	allPlayers[index] = temp
