extends Node
class_name  PseudoTeam

# a team that copies the information of another team so it can rotate without
# actually changing the game situation - in order to display potential future 
# rotations

var setter:Athlete
var middleBack:Athlete
var outsideBack:Athlete
var oppositeHitter:Athlete
var middleFront:Athlete
var outsideFront:Athlete
var libero:Athlete
var originalRotation1Player:Athlete

var pseudoLeftBlocker:Athlete
var pseudoRightBlocker:Athlete
var pseudoMiddleBlocker:Athlete

var server:int = 0

var isLiberoOnCourt:bool
var isNextToSpike:bool

var courtPlayers = []
var benchPlayers = []

func CopyTeam(team:Team):
	courtPlayers = team.courtPlayers.duplicate(false)
	benchPlayers = team.benchPlayers.duplicate(false)
	
	libero = team.libero
	
	server = team.server
	originalRotation1Player = team.originalRotation1Player
	isLiberoOnCourt = team.isLiberoOnCourt
	
	for athlete in courtPlayers:
		athlete.pseudoRotationPosition = athlete.rotationPosition
		
	for athlete in benchPlayers:
		athlete.pseudoRotationPosition = athlete.rotationPosition
	
func PseudoRotate():
	server += 1
	if server >= 6:
		server = 0
	
	for athlete in courtPlayers:
		if athlete.pseudoRotationPosition == 1:
			athlete.pseudoRotationPosition = 6
		else:
			athlete.pseudoRotationPosition -= 1
			
	#CheckForScheduledSubs()
	
	CachePlayers()
	CheckForLiberoChange()
	CachePlayers()
	
	
	
func CachePlayers():
	for player in courtPlayers:
		#Console.AddNewLine("Athlete: " + player.stats.lastName + ": " + str(player.pseudoRotationPosition))
		if player.role == Enums.Role.Setter:
			setter = player
		elif player.role == Enums.Role.Middle && AthleteWouldBeFrontCourt(player):
			middleFront = player
		elif player.role == Enums.Role.Middle && !AthleteWouldBeFrontCourt(player):
			middleBack = player
		elif player.role == Enums.Role.Outside && AthleteWouldBeFrontCourt(player):
			outsideFront = player
		elif player.role == Enums.Role.Outside && !AthleteWouldBeFrontCourt(player):
			outsideBack = player
		elif player.role == Enums.Role.Opposite:
			oppositeHitter = player
	
func PseudoSub(outgoing:Athlete, incoming:Athlete):
	if outgoing == originalRotation1Player:
		originalRotation1Player = incoming
	
	var outgoingIndex = courtPlayers.find(outgoing)
	if outgoingIndex == -1:
		print("Not found outgoing player: " + outgoing.name)
		for lad in courtPlayers:
			print ("court: " + lad.name + " " + str(lad.rotationPosition))
		for lad in benchPlayers:
			print ("bench: " + lad.name)
	courtPlayers.erase(outgoing)
	
	var incomingIndex = benchPlayers.find(incoming)
	if incomingIndex == -1:
		print("Not found outgoing player: " + incoming.name)
		for lad in courtPlayers:
			print ("court: " + lad.name)
		for lad in benchPlayers:
			print ("bench: " + lad.name)
	benchPlayers.erase(incoming)


	incoming.pseudoRotationPosition = outgoing.pseudoRotationPosition
	outgoing.pseudoRotationPosition = -1

	courtPlayers.insert(outgoingIndex, incoming)
	benchPlayers.insert(incomingIndex, outgoing)
	
func CheckForLiberoChange():
	if isLiberoOnCourt && libero.FrontCourt():
		PseudoSub(libero, benchPlayers[0])
		isLiberoOnCourt = false
		
	if !isLiberoOnCourt && middleBack:
			PseudoSub(middleBack, libero)
			isLiberoOnCourt = true

func PseudoCacheBlockers(teamServing:bool):
	if teamServing:
		pseudoLeftBlocker = outsideFront
		pseudoMiddleBlocker = middleFront
		if AthleteWouldBeFrontCourt(setter):
			pseudoRightBlocker = setter
		else:
			pseudoRightBlocker = oppositeHitter
		
func AthleteWouldBeFrontCourt(athlete:Athlete):
	if (athlete.pseudoRotationPosition == 1 || athlete.pseudoRotationPosition>4):
		return false
	else:
		return true
