extends Node

class_name Team
const Enums = preload("res://Scripts/World/Enums.gd")
var AthleteScene = preload("res://Scenes/Athlete.tscn")

var teamName:String
var nation
var mManager
var isHuman:bool = false

var isLiberoOnCourt:bool
var isNextToSpike:bool
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
		Vector3(5.5, 0, -4),
		Vector3(5.0, 0, -2.8),
		Vector3(3, 0, 1.3),
		Vector3(3.5, 0, 4),
		Vector3(5.3, 0, 2.6),
		Vector3(6.5, 0, 0)
	],
	[
		Vector3(5.5, 0, -1),
		Vector3(3.0, 0, -3.8),
		Vector3(.5, 0, -2.5),
		Vector3(3.5, 0, 4),
		Vector3(5, 0, 1),
		Vector3(1, 0, 0)
	],
	[#setter in 5
		Vector3(5.5, 0, -3.25),
		Vector3(2.75, 0, -3.0),
		Vector3(5, 0, 2.5),
		Vector3(.5, 0, 4),
		Vector3(1.5, 0, 1.3),
		Vector3(6.5, 0, 0)
	],
	[#setter 4
		Vector3(5.5, 0, -4),
		Vector3(5.0, 0, 2.5),
		Vector3(2.75, 0, 3.25),
		Vector3(.5, 0, 4),
		Vector3(6.5, 0, 0),
		Vector3(5, 0, -3.5)
	],
	[#setter 3
		Vector3(5.5, 0, -2.75),
		Vector3(2.75, 0, -1),
		Vector3(0.5, 0, 0),
		Vector3(4.5, 0, 2.5),
		Vector3(6.5, 0, 0),
		Vector3(7.5, 0, -1.75)
	],
	[
		Vector3(5.5, 0, -3),
		Vector3(.5, 0, 0),
		Vector3(5, 0, 2.75),
		Vector3(1.5, 0, 3.75),
		Vector3(7.75, 0, .6),
		Vector3(6.5, 0, 0)
	]
]

var server:int = 0

var flip = 1

var receptionTarget:Vector3
var setTarget:Set

var timeTillDigTarget:float


var ball:Ball
# Setter in 1 so outside, middle, oppo etc in 2,3,4...
var transitionPositionsSetterBack = [ Vector3(0.5, 0, 0), Vector3(4, 0, -3.75), Vector3(4, 0, 0), Vector3(4, 0, 3.75), Vector3(8, 0, 0), Vector3(5.5, 0, 3.15) ]
#    Setter in 4
var transitionPositionsSetterFront = [Vector3(7.75, 0, -4), Vector3(8, 0, 0), Vector3(5.5, 0, 3.15), Vector3(0.5, 0, 0), Vector3(4, 0, 3.75), Vector3(4, 0, 0) ]
var defaultPositions = [
	Vector3(6,0,-4),
	Vector3(2,0,-4),
	Vector3(2,0,0),
	Vector3(2,0,4),
	Vector3(6,0,4),
	Vector3(6,0,0)]

#var defaultDefensivePositions = [
#	Vector3(5.5, 0, -2.2),
#	Vector3(.5,0,-3),
#	Vector3(.5,0,0),
#	Vector3(.5,0,3),
#	Vector3(5.5,0,2.2),
#	Vector3(7.5,0,0)]
	
var stateMachine:StateMachine = load("res://Scripts/State/StateMachine.gd").new(self)
var serveState:State = load("res://Scripts/State/Team/TeamServe.gd").new()
var receiveState:State = load("res://Scripts/State/Team/TeamReceive.gd").new()
var setState:State = load("res://Scripts/State/Team/TeamSet.gd").new()
var spikeState:State = load("res://Scripts/State/Team/TeamSpike.gd").new()
var preserviceState:State = load("res://Scripts/State/Team/TeamPreService.gd").new()
var defendState:State = load("res://Scripts/State/Team/TeamDefend.gd").new()
var prereceiveState:State = load("res://Scripts/State/Team/TeamPreReceive.gd").new()

func init(_ball, choiceState, gameWorld, clubOrInternational, matchManager):
	mManager = matchManager
	var team = gameWorld.GetTeam(choiceState, clubOrInternational)
	teamName = team.teamName
	allPlayers = team.allPlayers
	
	ball = _ball
	
	stateMachine._init(self)
	stateMachine.SetCurrentState(serveState)
	
	AutoSelectTeamLineup()
	PlaceTeam()
	CachePlayers()
	
func PlaceTeam():

	for i in range(12):
		var pos
		var rot

		if i < 6:
			pos = flip * defaultPositions[i]
			rot = Vector3(0, flip*-PI/2, 0)

		else:

			#bench
			pos = Vector3(flip * (i + 3), 0, 10)
			rot = Vector3(0,flip*PI,0)

		var lad = AthleteScene.instance()
		
		lad.stats = allPlayers[i].stats
		lad.role = allPlayers[i].role
		
		
		add_child(lad)
		var ladscale = lad.stats.height /1.8
		
		lad.scale = Vector3(ladscale, ladscale, ladscale)
		
		lad.name = lad.stats.firstName + " " + lad.stats.lastName 
		lad.translation = pos
		lad.rotation = rot
		lad.team = self
		lad.spikeState.athlete = lad
		lad.CreateSpikes()
		lad.moveTarget = Vector3(pos.x,0,pos.z)
		#allPlayers.append(lad)
		if !isHuman:
			lad.get_child(0).ChangeShirtColour(Color(1,3,0))
		if i  < 6 :
			lad.rotationPosition = i + 1
			courtPlayers.append(lad)
		else:
			benchPlayers.append(lad)
		
		if i == 6:
			libero = lad
			lad.get_child(0).ChangeShirtColour()
		
		lad.ball = ball
			
		if isHuman:
			lad.serveState = load("res://Scripts/State/Athlete/AthleteHuman/AthleteHumanServeState.gd").new()
		else:
			lad.serveState = load("res://Scripts/State/Athlete/AthleteComputer/AthleteComputerServeState.gd").new()

		

func xzVector(vec:Vector3):
	return Vector3(vec.x, 0, vec.z)

func UpdateTimeTillDigTarget():
	
	if (stateMachine.currentState == setState):
		timeTillDigTarget = xzVector(ball.translation).distance_to(xzVector(receptionTarget)) / max(xzVector(ball.linear_velocity).length(),.0001) 

	elif stateMachine.currentState == spikeState:
		timeTillDigTarget = 0

	elif stateMachine.currentState == receiveState:
		timeTillDigTarget = 12345

	else:
		timeTillDigTarget = 54321
		
func CacheBlockers():
	if setter.FrontCourt():	
		rightSideBlocker = setter
		leftSideBlocker = outsideFront

	else:
		if markUndoChangesToRoles:
			rightSideBlocker = outsideFront
			leftSideBlocker = oppositeHitter
		else:
			rightSideBlocker = oppositeHitter
			leftSideBlocker = outsideFront

func _process(_delta):
	stateMachine.Update()

func Rotate():
#	if isHuman:
#		print(teamName + "  ROTATING")
#
#		for i in courtPlayers.size():
#			print(courtPlayers[i].stats.lastName + "  |  " + str(Enums.Role.keys()[courtPlayers[i].role]) + " " + str(courtPlayers[i].rotationPosition))

	if markUndoChangesToRoles:
		outsideFront.role = Enums.Role.Outside
		oppositeHitter.role = Enums.Role.Opposite
		markUndoChangesToRoles = false
	
	server += 1
	if server >= 6:
		server = 0
	
	for athlete in courtPlayers:
		if athlete.rotationPosition == 1:
			athlete.rotationPosition = 6
		else:
			athlete.rotationPosition -= 1
	CachePlayers()
	CheckForLiberoChange()
	CachePlayers()

func BallHitOverNet():
	stateMachine.SetCurrentState(receiveState)

func CheckForLiberoChange():
#	if isHuman:
#		print("\nChecking for libero change \nisNextToSpike? " + str(isNextToSpike))
# if the libero is entering the frontcourt, get rid of them
	if isLiberoOnCourt && libero.FrontCourt():
		InstantaneouslySwapPlayers(libero, benchPlayers[0])
		isLiberoOnCourt = false
# if the back middle isn't serving, get rid of them
	if !isLiberoOnCourt && middleBack:

		if !isNextToSpike:
#			print(teamName + " current server: " + courtPlayers[server].stats.lastName)
			if middleBack != courtPlayers[server]:
				print("\nMiddleBack: " + middleBack.stats.lastName)
				print("courtPlayers[server]: " + courtPlayers[server].stats.lastName + "\n")
				InstantaneouslySwapPlayers(middleBack, libero)
				isLiberoOnCourt = true

		else:
			InstantaneouslySwapPlayers(middleBack, libero)
			isLiberoOnCourt = true

func InstantaneouslySwapPlayers(outgoing:Athlete, incoming:Athlete):
#	if isHuman:
#		print("Swapping " + outgoing.name + " for " + incoming.name)
	
	var outgoingIndex = courtPlayers.find(outgoing)
	if outgoingIndex == -1:
		print("Not found outgoing player: " + outgoing.name)
		for lad in courtPlayers:
			print ("court: " + lad.name + " " + str(lad.rotationPosition))
		for lad in benchPlayers:
			print ("bench: " + lad.name)
	courtPlayers.remove(outgoingIndex)
	
	var incomingIndex = benchPlayers.find(incoming)
	if incomingIndex == -1:
		print("Not found outgoing player: " + incoming.name)
		for lad in courtPlayers:
			print ("court: " + lad.name)
		for lad in benchPlayers:
			print ("bench: " + lad.name)
	benchPlayers.remove(incomingIndex)

	var tempPos = Vector3(incoming.translation.x, 0, incoming.translation.z)
	incoming.translation = outgoing.translation
	outgoing.translation = tempPos

	incoming.rotationPosition = outgoing.rotationPosition
	outgoing.rotationPosition = -1

	courtPlayers.insert(outgoingIndex, incoming)
	benchPlayers.insert(incomingIndex, outgoing)


	if (incoming.role != Enums.Role.Libero && outgoing.role != Enums.Role.Libero):
		incoming.role = outgoing.role

	incoming.moveTarget = incoming.translation
	outgoing.moveTarget = outgoing.translation

	var tempRot = incoming.rotation
	incoming.rotation = outgoing.rotation
	outgoing.rotation = tempRot
	
	outgoing.stateMachine.SetCurrentState(outgoing.chillState)
	incoming.ReEvaluateState()
	
func CachePlayers():
	for player in courtPlayers:
		if player.role == Enums.Role.Setter:
			setter = player
		elif player.role == Enums.Role.Middle && player.FrontCourt():
			middleFront = player
		elif player.role == Enums.Role.Middle && !player.FrontCourt():
			middleBack = player
		elif player.role == Enums.Role.Outside && player.FrontCourt():
			outsideFront = player
		elif player.role == Enums.Role.Outside && !player.FrontCourt():
			outsideBack = player
		elif player.role == Enums.Role.Opposite:
			oppositeHitter = player

func AutoSelectTeamLineup():
	allPlayers.sort_custom(Athlete, "SortSet")
	var orderedSetterList =  allPlayers.duplicate(false)
	
	allPlayers.sort_custom(Athlete, "SortOutside")
	var orderedOutsideList = allPlayers.duplicate(false)
	
	allPlayers.sort_custom(Athlete, "SortLibero")
	var orderedLiberoList = allPlayers.duplicate(false)
	
	allPlayers.sort_custom(Athlete, "SortOpposite")
	var orderedOppositeList = allPlayers.duplicate(false) 
	
	allPlayers.sort_custom(Athlete, "SortMiddle")
	var orderedMiddleList = allPlayers.duplicate(false)

	var aptitudeLists = [orderedSetterList,orderedLiberoList,orderedOutsideList,orderedOppositeList,orderedMiddleList]


	var nsetter = orderedSetterList[0]
	SwapPlayer(nsetter, 0)
	nsetter.role = Enums.Role.Setter
	for list in aptitudeLists:
		list.erase(nsetter)

	var nmiddle1 = orderedMiddleList[0]
	var nmiddle2 = orderedMiddleList[1]
	nmiddle1.role = Enums.Role.Middle
	nmiddle2.role = Enums.Role.Middle
	SwapPlayer(nmiddle1, 2)
	SwapPlayer(nmiddle2, 5)
	for list in aptitudeLists:
		list.erase(nmiddle1)
		list.erase(nmiddle2)
	
	var noutside1 = orderedOutsideList[0]
	var noutside2 = orderedOutsideList[1]
	noutside1.role = Enums.Role.Outside
	noutside2.role = Enums.Role.Outside
	SwapPlayer(noutside1, 1)
	SwapPlayer(noutside2, 4)
	for list in aptitudeLists:
		list.erase(noutside1)
		list.erase(noutside2)
	var nopposite = orderedOppositeList[0]
	nopposite.role = Enums.Role.Opposite
	SwapPlayer(nopposite, 3)
	for list in aptitudeLists:
		list.erase(nopposite)
	var nlibero = orderedLiberoList[0]
	nlibero.role = Enums.Role.Libero
	SwapPlayer(nlibero, 6)
	for list in aptitudeLists:
		list.erase(nlibero)
	var backupSetter = orderedSetterList[0]
	SwapPlayer(backupSetter, 7)
	backupSetter.role = Enums.Role.Setter
	for list in aptitudeLists:
		list.erase(backupSetter)
		
	for athlete in orderedLiberoList:
		athlete.role = Enums.Role.UNDEFINED



func SwapPlayer(player,newPostion):
	#print("-----------")
	#print("")
	var index = -1
	for i in range(allPlayers.size()):
		if (allPlayers[i] == player):
			index = i
			break
	
	#for i in range(allPlayers.size()):
	#	print(str(allPlayers[i].role) + " " + str(i))

	#print ("")
	var temp = allPlayers[newPostion]
	allPlayers[newPostion] = player
	allPlayers[index] = temp
	
	#for i in range(allPlayers.size()):
	#	print(str(allPlayers[i].role) + " " + str(i))
	
func GetTransitionPosition(athlete):
	if (setter.FrontCourt()):
		if athlete == setter:
			return CheckIfFlipped(transitionPositionsSetterFront[3])
		if athlete == outsideFront:
			return CheckIfFlipped(transitionPositionsSetterFront[4])
		if athlete == oppositeHitter:
			return CheckIfFlipped(transitionPositionsSetterFront[0])
		else:
			return CheckUnchangingTransitionPositions(athlete)
	else:
		if markUndoChangesToRoles:
			if athlete == outsideFront:
				return CheckIfFlipped(transitionPositionsSetterBack[1])
			if athlete == oppositeHitter:
				return CheckIfFlipped(transitionPositionsSetterBack[3])
		else:
			if athlete == outsideFront:
				return CheckIfFlipped(transitionPositionsSetterBack[3])
			if (athlete == oppositeHitter):
				return CheckIfFlipped(transitionPositionsSetterBack[1])
		if athlete == setter:
			return CheckIfFlipped(transitionPositionsSetterBack[0])
		else:
			return CheckUnchangingTransitionPositions(athlete)

func CheckUnchangingTransitionPositions(athlete):
	if athlete == outsideBack:
		return CheckIfFlipped(transitionPositionsSetterBack[4])
	elif athlete == middleBack || athlete == libero:
		return CheckIfFlipped(transitionPositionsSetterBack[5])

	elif athlete == middleFront:
		return CheckIfFlipped(transitionPositionsSetterBack[2])
	else:
		return Vector3.ZERO

func CheckIfFlipped(vectorToBeChecked:Vector3):
	return Vector3(flip * vectorToBeChecked.x, vectorToBeChecked.y, flip * vectorToBeChecked.z)

func Chill():
	for player in courtPlayers:
		player.stateMachine.SetCurrentState(player.chillState)

func AttemptBlock(spiker:Athlete):
	var blockingChance:float = 0
	#how many blockers are there?
	var blockers:Array = []
	for blocker in courtPlayers:
		if blocker.FrontCourt():
			if blocker.stateMachine.currentState.nameOfState == "Block":
				if blocker.blockState.blockingTarget == spiker:
					blockers.append(blocker)
	
	#No block
	if len(blockers) == 0:
		mManager.BallOverNet(!isHuman)
		return
	
	# Is the spiker just too tall?
	
	var highestBlockHeight = 0
	for blocker in blockers:
		if blocker.stats.blockHeight > highestBlockHeight:
			highestBlockHeight = blocker.stats.blockHeight

	#the height of the ball over the net
	
	var netPass = ball.FindNetPass()
	
	if netPass.y - highestBlockHeight > 0.3:
		Console.AddNewLine("OTT!!!", Color.azure)
		Console.AddNewLine("Spike height: " + str(spiker.stats.spikeHeight), Color.azure)
		Console.AddNewLine("Block height: " + str(highestBlockHeight), Color.azure)
		mManager.BallOverNet(!isHuman)
		return
	
	ball.blockResolver.AddUpcomingBlock(isHuman, blockers, spiker)
	
	pass

func Populate(firstNames, lastNames, r):
	for _j in range(12):
		var stats = Stats.new()
		var skill = rand_range(0,10) + rand_range(0,10) + rand_range(0,10) + rand_range(0,10) + rand_range(0,10)
		stats.firstName = firstNames[r.randi_range(0, firstNames.size() - 1)]
		stats.lastName = lastNames[r.randi_range(0, lastNames.size() - 1)]
		stats.nation = nation.countryName
		stats.serve = skill + rand_range(0,25) + rand_range(0,25)
		stats.reception = skill + rand_range(0,25) + rand_range(0,25)
		stats.block = skill + rand_range(0,25) + rand_range(0,25)
		stats.set = skill + rand_range(0,25) + rand_range(0,25)
		stats.spike = skill + rand_range(0,25) + rand_range(0,25)
		stats.verticalJump = rand_range(0,.5) + rand_range(.1,.5) + rand_range(.1,.5)
		stats.height = rand_range(.3,.8) + rand_range(.5,.8) + rand_range(.5,.8)
		stats.speed = rand_range(5.5,7.5)
		stats.dump = skill + rand_range(0,25) + rand_range(0,25)
		#1.25 is the arm factor of newWoman
		stats.spikeHeight = stats.height * (1.33) + stats.verticalJump
		stats.blockHeight = stats.height * (1.25) + stats.verticalJump
		stats.standingSetHeight = stats.height + 0.15
		stats.jumpSetHeight = stats.standingSetHeight + stats.verticalJump
		#stats.shirtNumber = shirtNumbers[j];
		#stats.image = images[j];
		var athlete = Athlete.new()
		athlete.stats = stats
		allPlayers.append(athlete)
		
		
		#DateTime oldest = new DateTime(1975, 1, 1);

		#int daysRange = (DateTime.Today.AddYears(-17) - oldest).Days;
		#stats.dob = oldest.AddDays( r.Next(daysRange));

		#team.CalculateMacroStats();
