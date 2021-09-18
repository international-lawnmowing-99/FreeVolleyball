extends Node

var teamName:String

var isLiberoOnCourt:bool
var isNextToAttack:bool
var markUndoChangesToRoles:bool

var allPlayers
var courtPlayers
var benchPlayers

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

var server:int

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
	Vector3(6,0,4),
	Vector3(2,0,4),
	Vector3(2,0,0),
	Vector3(2,0,-4),
	Vector3(6,0,-4),
	Vector3(6,0,0)]

func init(mM, _ball):
	mManager = mM
	ball = _ball
	
func xzVector(vec:Vector3):
	return Vector3(vec.x, 0, vec.z)

func UpdateTimeTillDigTarget():
	if (mManager.gameState == MatchManager.GameState.Set):
		timeTillDigTarget = xzVector(ball.translation).distance_to(xzVector(receptionTarget)) / xzVector(ball.linear_velocity).length();

	elif mManager.gameState == mManager.GameState.Spike:
		timeTillDigTarget = 0;

	elif mManager.gameState == mManager.GameState.Receive:
		timeTillDigTarget = 12345;

	else:
		timeTillDigTarget = 54321;
		
func CheckForSpikeDistance():
	if mManager.gameState == mManager.GameState.Spike && isNextToAttack:
		if !chosenSpiker:
			print("Error inbound")
			#Log(setTarget.target)
	if ball.translation.y <= setTarget.y && abs(ball.translation.z) >= abs(setTarget.z) && ball.linear_velocity.y <= 0:
		SpikeBall()

func SpikeBall():
	pass

func Rotate():
	if markUndoChangesToRoles:
		outsideFront.roleCurrentlyPerforming = Athlete.Role.Outside;
		oppositeHitter.roleCurrentlyPerforming = Role.Opposite;
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

func CheckForLiberoChange():
#// if the libero is entering the frontcourt, get rid of them
	if isLiberoOnCourt && libero.FrontCourt():
		InstantaneouslySwapPlayers(libero, benchPlayers[0]);
		isLiberoOnCourt = false;

#// if the back middle isn't serving, get rid of them
	if !isLiberoOnCourt && middleBack:
		if !nextToAttack:
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

	if (incoming.roleCurrentlyPerforming != Role.Libero && outgoing.roleCurrentlyPerforming != Role.Libero):

		incoming.roleCurrentlyPerforming = outgoing.roleCurrentlyPerforming;

		incoming.moveTarget = incoming.translation;
		outgoing.moveTarget = outgoing.translation;

		var tempRot = incoming.rotation;
		incoming.rotation = outgoing.rotation;
		outgoing.rotation = tempRot;
		outgoing.Chill()

func CachePlayers():
	for player in courtPlayers:
		if player.roleCurrentlyPerforming == Role.Setter:
			setter = player
		elif player.roleCurrentlyPerforming == Role.Middle && player.FrontCourt():
			middleFront = player
		elif player.roleCurrentlyPerforming == Role.Middle && !player.FrontCourt():
			middleBack = player
		elif player.roleCurrentlyPerforming == Role.Outside && player.FrontCourt():
			outsideFront = player
		elif player.roleCurrentlyPerforming == Role.outside && !player.FrontCourt():
			outsideBack = player
		elif player.roleCurrentlyPerforming == Role.Opposite:
			oppositeHitter = player

func _process(delta):
	UpdateTimeTillDigTarget()
	CheckForSpikeDistance()
	
