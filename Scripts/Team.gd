extends Node
class_name Team

var AthleteScene = preload("res://Scenes/MatchScene/Athlete/Athlete.tscn")
var teamName:String

var teamStrategy = preload("res://Scripts/TeamStrategy.gd").new()

var nation
var mManager:MatchManager
var isHuman:bool = false

var isLiberoOnCourt:bool
var isNextToSpike:bool
var markUndoChangesToRoles:bool

var matchPlayers = []
var courtPlayers = []
var benchPlayers = []

var setter:Athlete
var middleBack:Athlete
var outsideBack:Athlete
var oppositeHitter:Athlete
var middleFront:Athlete
var outsideFront:Athlete
var libero:Athlete
var originalRotation1Player:Athlete
var rotationsElapsed:int = 0

var chosenSetter:Athlete
var chosenSpiker:Athlete
var chosenReceiver:Athlete

var receiveRotations

var server:int = 0

var flip = 1

var receptionTarget:Vector3
var ballPositionWhenSet:Vector3
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
var serveState:TeamServe = load("res://Scripts/State/Team/TeamServe.gd").new()
var receiveState:TeamReceive = load("res://Scripts/State/Team/TeamReceive.gd").new()
var setState:TeamSet = load("res://Scripts/State/Team/TeamSet.gd").new()
var spikeState:TeamSpike = load("res://Scripts/State/Team/TeamSpike.gd").new()
var preserviceState:TeamPreService = load("res://Scripts/State/Team/TeamPreService.gd").new()
var defendState:TeamDefend = load("res://Scripts/State/Team/TeamDefend.gd").new()
var prereceiveState:TeamPreReceive = load("res://Scripts/State/Team/TeamPreReceive.gd").new()
var chillState = load("res://Scripts/State/Team/TeamState.gd").new()

func CopyGameWorldPlayers(gameWorld:GameWorld, choiceState:PlayerChoiceState, clubOrInternational:Enums.ClubOrInternational):
	if matchPlayers.size() > 0:
		Console.AddNewLine("ERROR! Couldn't add more players to local team from world equivalent")
		return
		
	var team = gameWorld.GetTeam(choiceState, clubOrInternational)
	if team is NationalTeam:
		if team.nationalPlayers.size() == 0:
			gameWorld.PopulateTeam(team)
	else:
		if team.matchPlayers.size() == 0:
			gameWorld.PopulateTeam(team)

	teamName = team.teamName
	nation = team.nation
	
	if self is NationalTeam:
		(self as NationalTeam).nationalPlayers = team.nationalPlayers.duplicate(true)
	else:
		matchPlayers = team.matchPlayers.duplicate(true)

func Init(matchManager):
	mManager = matchManager
	ball = mManager.ball
	
	receiveRotations = teamStrategy.receiveRotations["default"].duplicate(true)
	
	stateMachine._init(self)
	stateMachine.SetCurrentState(chillState)
	
	
	AutoSelectTeamLineup()
	
	PlaceTeam()
	CachePlayers()
	
func PlaceTeam():

	for i in range(12):
		var pos
		var rot

		if i < 6:
			pos = flip * defaultPositions[i]
			rot = Vector3(0, flip * -PI/2, 0)

		else:

			#bench
			pos = Vector3(flip * (i + 3), 0, 10)
			rot = Vector3(0,flip * PI,0)

		var lad = AthleteScene.instantiate()
		lad._ready()
		lad.stats = matchPlayers[i].stats
		lad.role = matchPlayers[i].role
		
		
		add_child(lad)
		var ladscale = lad.stats.height /1.8
		
		lad.model.scale = Vector3(ladscale, ladscale, ladscale)
		
		lad.name = lad.stats.firstName + " " + lad.stats.lastName 
		lad.position = pos
		lad.model.rotation = rot
		lad.team = self
#		lad.spikeState.athlete = lad
		lad.CreateSpikes()
		lad.moveTarget = Vector3(pos.x,0,pos.z)
		#matchPlayers.append(lad)
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

		originalRotation1Player = courtPlayers[0]

func UpdateTimeTillDigTarget():
	
	if (stateMachine.currentState == setState):
		
		timeTillDigTarget = Maths.TimeTillBallReachesHeight(ball.position, ball.linear_velocity, receptionTarget.y, 1.0) # Maths.XZVector(ball.position).distance_to(Maths.XZVector(receptionTarget)) / max(Maths.XZVector(ball.linear_velocity).length(),.0001) 
#		if !mManager.isPaused:
#			Console.AddNewLine(str("%.2f" % timeTillDigTarget) + " time till dig target updated")
	
	elif stateMachine.currentState == spikeState:
		timeTillDigTarget = 0

	elif stateMachine.currentState == receiveState:
		timeTillDigTarget = 12345

	else:
		timeTillDigTarget = 54321
	


func _process(_delta):
	stateMachine.Update()
	if !isHuman && mManager && mManager.TESTteamRepresentation.courtPlayers:
		mManager.TESTteamRepresentation.UpdateRepresentation(get_process_delta_time())

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
#				print("\nMiddleBack: " + middleBack.stats.lastName)
#				print("courtPlayers[server]: " + courtPlayers[server].stats.lastName + "\n")
				InstantaneouslySwapPlayers(middleBack, libero)
				isLiberoOnCourt = true

		else:
			InstantaneouslySwapPlayers(middleBack, libero)
			isLiberoOnCourt = true

func InstantaneouslySwapPlayers(outgoing:Athlete, incoming:Athlete):
#	if isHuman:
#		print("Swapping " + outgoing.name + " for " + incoming.name)
	
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

	var tempPos = Vector3(incoming.position.x, 0, incoming.position.z)
	incoming.position = outgoing.position
	outgoing.position = tempPos
	outgoing.moveTarget = outgoing.position

	incoming.rotationPosition = outgoing.rotationPosition
	outgoing.rotationPosition = -1

	courtPlayers.insert(outgoingIndex, incoming)
	benchPlayers.insert(incomingIndex, outgoing)


	if (incoming.role != Enums.Role.Libero && outgoing.role != Enums.Role.Libero):
		incoming.role = outgoing.role

	incoming.moveTarget = incoming.position
	outgoing.moveTarget = outgoing.position

	var tempRot = incoming.model.rotation
	incoming.model.rotation = outgoing.model.rotation
	outgoing.model.rotation = tempRot
	
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
	matchPlayers.sort_custom(Callable(Athlete,"SortSet"))
	var orderedSetterList =  matchPlayers.duplicate(false)
	
	matchPlayers.sort_custom(Callable(Athlete,"SortOutside"))
	var orderedOutsideList = matchPlayers.duplicate(false)
	
	matchPlayers.sort_custom(Callable(Athlete,"SortLibero"))
	var orderedLiberoList = matchPlayers.duplicate(false)
	
	matchPlayers.sort_custom(Callable(Athlete,"SortOpposite"))
	var orderedOppositeList = matchPlayers.duplicate(false) 
	
	matchPlayers.sort_custom(Callable(Athlete,"SortMiddle"))
	var orderedMiddleList = matchPlayers.duplicate(false)

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

#	nsetter.stats.verticalJump += 3
#	nsetter.stats.jumpSetHeight += 3
#	nsetter.stats.spikeHeight += 3

func SwapPlayer(player,newPostion):
	#print("-----------")
	#print("")
	var index = -1
	for i in range(matchPlayers.size()):
		if (matchPlayers[i] == player):
			index = i
			break
	
	#for i in range(matchPlayers.size()):
	#	print(str(matchPlayers[i].role) + " " + str(i))

	#print ("")
	var temp = matchPlayers[newPostion]
	matchPlayers[newPostion] = player
	matchPlayers[index] = temp
	
	#for i in range(matchPlayers.size()):
	#	print(str(matchPlayers[i].role) + " " + str(i))
	
func GetTransitionPosition(athlete):
	if (setter.FrontCourt()):
		if athlete == setter:
			return CheckIfFlipped(transitionPositionsSetterBack[1])
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
			return CheckIfFlipped(transitionPositionsSetterFront[0])
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
	stateMachine.SetCurrentState(chillState)
	for player in courtPlayers:
		if player == chosenReceiver:
			player.WaitThenChill(.75)
			continue
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
	
	var netPass = Maths.FindNetPass(ball.position, ball.attackTarget, ball.linear_velocity, 3.0)
	
	if netPass.y - highestBlockHeight > 0.3:
		Console.AddNewLine("OTT!!!", Color.AZURE)
		Console.AddNewLine("Spike height: " + str(spiker.stats.spikeHeight), Color.AZURE)
		Console.AddNewLine("Block height: " + str(highestBlockHeight), Color.AZURE)
		mManager.BallOverNet(!isHuman)
		return
	
	ball.blockResolver.AddUpcomingBlock(!isHuman, blockers, spiker)


func Populate(firstNames, lastNames):
	if matchPlayers.size() != 0:
		for i in range (32):
			Console.AddNewLine("!Not Generating additional unnecessary players!!")
		return
			
	for _j in range(12):
		var stats = Stats.new()
		var skill = randf_range(0,10) + randf_range(0,10) + randf_range(0,10) + randf_range(0,10) + randf_range(0,10)
		stats.firstName = firstNames[randi_range(0, firstNames.size() - 1)]
		stats.lastName = lastNames[randi_range(0, lastNames.size() - 1)]
		stats.nation = nation.countryName
		stats.serve = skill + randf_range(0,25) + randf_range(0,25)
		stats.reception = skill + randf_range(0,25) + randf_range(0,25)
		stats.block = skill + randf_range(0,25) + randf_range(0,25)
		stats.set = skill + randf_range(0,25) + randf_range(0,25)
		stats.spike = skill + randf_range(0,25) + randf_range(0,25)
		stats.verticalJump = randf_range(0.1, .5) + randf_range(.1,.5) + randf_range(.1,.5) + randf_range(.35,.6)
		stats.height = randf_range(.25,.6) + randf_range(.25,.6) + randf_range(.35,.6) + randf_range(.35,.6)
		stats.speed = randf_range(5.5,7.5)
		stats.dump = skill + randf_range(0,25) + randf_range(0,25)
		#1.25 is the arm factor of newWoman
		stats.spikeHeight = stats.height * (1.25) + stats.verticalJump
		stats.blockHeight = stats.height * (1.2) + stats.verticalJump

		stats.digHeight = stats.height/1.6 
		stats.standingSetHeight = stats.height * 1.2
		stats.jumpSetHeight = stats.standingSetHeight + stats.verticalJump
		var age = 17 + randi()%28

		stats.dob["year"] = 2023 - age
		stats.gameRead = skill/50.0 +  randf()/2.0 * age/(17.0+28.0)

		#stats.shirtNumber = shirtNumbers[j];
		#stats.image = images[j];
		var athlete = Athlete.new()
		athlete.stats = stats
		matchPlayers.append(athlete)
		
		#DateTime oldest = new DateTime(1975, 1, 1);

		#int daysRange = (DateTime.Today.AddYears(-17) - oldest).Days;
		#stats.dob = oldest.AddDays( r.Next(daysRange));

		#team.CalculateMacroStats();
