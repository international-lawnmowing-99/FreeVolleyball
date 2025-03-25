extends Node
class_name TeamNode

var data:TeamData
var AthleteScene = preload("res://Scenes/MatchScene/Athlete/Athlete.tscn")

var mManager:MatchManager

var matchPlayerNodes = []
var courtPlayerNodes = []
var benchPlayerNodes = []

var setter:Athlete
var middleBack:Athlete
var outsideBack:Athlete
var oppositeHitter:Athlete
var middleFront:Athlete
var outsideFront:Athlete
var libero:Athlete
var libero2:Athlete
var teamCaptain:Athlete
var originalRotation1Player:Athlete


var activeLibero:Athlete
var chosenSetter:Athlete
var chosenSpiker:Athlete
var chosenReceiver:Athlete

var receiveRotations
# who will be subbed for the libero in each rotation ie rot [will be subbed bool, player, libero to use if we have two (or more!)]
var playerToBeLiberoedOnServe:Array = [[false,null,null],[false,null,null],[false,null,null],[false,null,null],[false,null,null], [false,null,null]]
var playerToBeLiberoedOnReceive:Array = [[false,null,null],[false,null,null],[false,null,null],[false,null,null],[false,null,null], [false,null,null]]
var playerCurrentlyLiberoedOff:Athlete = null

var server:int = 0
var numberOfSubsUsed:int = 0

var flip = 1

var receptionTarget:Vector3
# What does this do?? Was it meant to do something?
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
var celebrateState = load("res://Scripts/State/Team/TeamState.gd").new()
var commiserateState = load("res://Scripts/State/Team/TeamState.gd").new()

func _init():
	stateMachine.SetCurrentState(chillState)



#func CopyGameWorldPlayers(gameWorld:GameWorld, choiceState:PlayerChoiceState, clubOrInternational:Enums.ClubOrInternational):
	#if matchPlayers.size() > 0:
		#Console.AddNewLine("ERROR! Couldn't add more players to local team from world equivalent")
		#return
#
	#var team = gameWorld.GetTeam(choiceState, clubOrInternational)
	#if team is NationalTeam:
		#if team.nationalPlayers.size() == 0:
			#gameWorld.PopulateTeam(team)
	#else:
		#if team.matchPlayers.size() == 0:
			#gameWorld.PopulateTeam(team)
#
	#if data is NationalTeam:
		#(data as NationalTeam).nationalPlayers = team.nationalPlayers.duplicate(true)
	#else:
		#matchPlayers = team.matchPlayers.duplicate(true)

func Init(matchManager):
	mManager = matchManager
	ball = mManager.ball

	receiveRotations = data.teamStrategy.receiveRotations["default"].duplicate(true)

	stateMachine._init(self)
	stateMachine.SetCurrentState(chillState)


	AutoSelectTeamLineup()

	PlaceTeam()


	CachePlayers()
	CreateDefaultLiberoStrategy()

func PlaceTeam():
	# in the case that both teams are the same, don't have the players share stats, it confuses the liberos
	if data == defendState.otherTeam.data:
		Console.AddNewLine("The teams are the same, duplicating objects to avoid conflict")

	Console.AddNewLine(str(data.matchPlayers.size()) + " players for us and " + str(defendState.otherTeam.data.matchPlayers.size()) + " players for them")
	if defendState.otherTeam.data.matchPlayers.size() != data.matchPlayers.size():
		Console.AddNewLine("! The teams are the same but not with the same number of players!")

	for i in range(data.matchPlayers.size()):
		if data.matchPlayers[i] in defendState.otherTeam.data.matchPlayers:
			data.matchPlayers[i] = data.matchPlayers[i].duplicate(false)
			Console.AddNewLine("Duplicating " + data.matchPlayers[i].lastName)

	for i in range(data.matchPlayers.size()):
		var pos:Vector3
		var rot:Vector3

		if i < 6:
			pos = flip * defaultPositions[i]
			rot = Vector3(0, flip * -PI/2, 0)

		else:

			#bench
			pos = Vector3(flip * (i + 3), 0, 10)
			rot = Vector3(0,flip * PI,0)

		var lad:Athlete = AthleteScene.instantiate()
		lad._ready()

		lad.stats = data.matchPlayers[i]
		add_child(lad)
		#TODO - eventually there will be a set of blendshapes that will make the people look different
		# when applied to their models
		#lad.ChangeAppearanceBasedOnStats()
		var ladscale = lad.stats.height /1.8

		lad.model.scale = Vector3(ladscale, ladscale, ladscale)

		lad.name = lad.stats.firstName + " " + lad.stats.lastName
		lad.position = pos
		lad.model.rotation = rot
		lad.team = self
#		lad.spikeState.athlete = lad
		lad.CreateSpikes()
		lad.moveTarget = Vector3(pos.x,0,pos.z)

		if !data.isHuman:
			#TODO~ this creates multiple materials that are the same colour -
			# would be much better to just have the one shared material
			lad.model.ChangeShirtColour(Color(0,3,0))
		if i  < 6 :
			lad.stats.rotationPosition = i + 1
			courtPlayerNodes.append(lad)
		else:
			benchPlayerNodes.append(lad)
			if !libero:
				if lad.stats.role == Enums.Role.Libero:
					libero = lad
			elif !libero2:
				if lad.stats.role == Enums.Role.Libero:
					libero2 = lad




		lad.ball = ball

		if data.isHuman:
			lad.serveState = load("res://Scripts/State/Athlete/AthleteHuman/AthleteHumanServeState.gd").new()
		else:
			lad.serveState = load("res://Scripts/State/Athlete/AthleteComputer/AthleteComputerServeState.gd").new()


		matchPlayerNodes.append(lad)

	if libero:
		libero.get_child(0).ChangeShirtColour()
	if libero2:
		libero2.get_child(0).ChangeShirtColour(Color(randf(),0,0))

	for athlete:Athlete in benchPlayerNodes:
		athlete.stateMachine.SetCurrentState(athlete.chillState)

	CachePlayers()

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
	if !data.isHuman && mManager && mManager.TESTteamRepresentation.courtPlayers:
		mManager.TESTteamRepresentation.UpdateRepresentation(get_process_delta_time())

func Rotate():
#	if isHuman:
#		print(teamName + "  ROTATING")
#
#		for i in courtPlayers.size():
#			print(courtPlayers[i].stats.lastName + "  |  " + str(Enums.Role.keys()[courtPlayers[i].stats.role]) + " " + str(courtPlayers[i].rotationPosition))

	if data.markUndoChangesToRoles:
		outsideFront.stats.role = Enums.Role.Outside
		oppositeHitter.stats.role = Enums.Role.Opposite
		data.markUndoChangesToRoles = false

	server += 1
	if server >= 6:
		server = 0

	for athlete in courtPlayerNodes:
		if athlete.stats.rotationPosition < 1:
			Console.AddNewLine("Court Player in odd rotationPosition: " + athlete.stats.lastName + " is in rotation: " + str(athlete.stats.rotationPosition), Color.YELLOW)
		elif athlete.stats.rotationPosition == 1:
			athlete.stats.rotationPosition = 6
		else:
			athlete.stats.rotationPosition -= 1

	CachePlayers()
	CheckForLiberoChange()
	CachePlayers()

func CheckForLiberoChange():
	if data.isHuman:
		Console.AddNewLine("Checking for libero change, are we serving? " + str(mManager.isTeamAServing == data.isHuman), Color.GREEN_YELLOW)
		if playerCurrentlyLiberoedOff:
			Console.AddNewLine("Player off for lib: " + playerCurrentlyLiberoedOff.name)
		else:
			Console.AddNewLine("Libero(s) not on court")

	#if mManager.isTeamAServing == isHuman:
		## we are serving
		#if playerToBeLiberoedOnServe[originalRotation1Player.rotationPosition - 1][0]:
			#var playerToBeLiberoed = playerToBeLiberoedOnServe[originalRotation1Player.rotationPosition - 1][1]
			#var liberoToUse = playerToBeLiberoedOnServe[originalRotation1Player.rotationPosition - 1][2]
			#if isHuman:
				#if playerToBeLiberoed in courtPlayers:
					#Console.AddNewLine("We need to make a libero change", Color.DEEP_PINK)
				#elif playerToBeLiberoed in benchPlayers:
					#Console.AddNewLine("We (probably) don't need to make a libero change", Color.DEEP_PINK)
				#else:
					#Console.AddNewLine("Error, player to be liberoed not in bench or court players", Color.DEEP_PINK)
				#
	#else:
		#if playerToBeLiberoedOnReceive[originalRotation1Player.rotationPosition - 1][0]:
			#var playerToBeLiberoed = playerToBeLiberoedOnReceive[originalRotation1Player.rotationPosition - 1][1]
			#var liberoToUse = playerToBeLiberoedOnReceive[originalRotation1Player.rotationPosition - 1][2]
			#if isHuman:
				#if playerToBeLiberoed in courtPlayers:
					#Console.AddNewLine("We need to make a libero change", Color.DEEP_PINK)
				#elif playerToBeLiberoed in benchPlayers:
					#Console.AddNewLine("We (probably) don't need to make a libero change", Color.DEEP_PINK)
				#else:
					#Console.AddNewLine("Error, player to be liberoed not in bench or court players", Color.DEEP_PINK)


	if data.isLiberoOnCourt:
		var inactiveLibero:Athlete

		if libero in courtPlayerNodes:
			if data.isHuman:
				Console.AddNewLine("Active libero is: " + libero.name + " (Libero 1)")
			if libero2:
				inactiveLibero = libero2
				if data.isHuman:
					Console.AddNewLine("Inactive libero is: " + libero2.name)

		elif libero2 in courtPlayerNodes:
			if data.isHuman:
				Console.AddNewLine("Active libero is: " + libero2.name + " (Libero 2)")
				Console.AddNewLine("Inactive libero is: " + libero.name)
			inactiveLibero = libero

		if !activeLibero:
			Console.AddNewLine("ERROR! isLiberoOnCourt true, but lib not found", Color.RED)
			data.isLiberoOnCourt = false
			return

		if activeLibero.FrontCourt():
			if data.isHuman:
				Console.AddNewLine("Swapping active libero for player liberoed off, active libero enters front court")
			InstantaneouslySwapPlayers(activeLibero, playerCurrentlyLiberoedOff)
			playerCurrentlyLiberoedOff = null
			data.isLiberoOnCourt = false

		elif mManager.isTeamAServing != data.isHuman: # We receive
			if !playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][0]:
				if data.isHuman:
					Console.AddNewLine("Taking off the libero, no replacement")
				InstantaneouslySwapPlayers(activeLibero, playerCurrentlyLiberoedOff)
				playerCurrentlyLiberoedOff = null
				data.isLiberoOnCourt = false

			else:
				if playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][2] != activeLibero:
					if data.isHuman:
						Console.AddNewLine("Changing liberos on receive")
					InstantaneouslySwapPlayers(activeLibero, inactiveLibero)
					var temp = inactiveLibero
					inactiveLibero = activeLibero
					activeLibero = temp

				if playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][1] != playerCurrentlyLiberoedOff:
					if data.isHuman:
						Console.AddNewLine("Changed the player the libero is used for on receive, step 1 - player off comes back on for libero")
					InstantaneouslySwapPlayers(activeLibero, playerCurrentlyLiberoedOff)
					playerCurrentlyLiberoedOff = null
					data.isLiberoOnCourt = false


		elif mManager.isTeamAServing == data.isHuman: # We serve
			if !playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][0]:
				if data.isHuman:
					Console.AddNewLine("Taking off the libero, no replacement")
				InstantaneouslySwapPlayers(activeLibero, playerCurrentlyLiberoedOff)
				playerCurrentlyLiberoedOff = null
				data.isLiberoOnCourt = false

			else:
				if playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][2] != activeLibero:
					if data.isHuman:
						Console.AddNewLine("Changing liberos on serve")
					InstantaneouslySwapPlayers(activeLibero, inactiveLibero)
					var temp = inactiveLibero
					inactiveLibero = activeLibero
					activeLibero = temp

				if playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][1] != playerCurrentlyLiberoedOff:
					if data.isHuman:
						Console.AddNewLine("Changed the player the libero is used for on serve, step 1 - player comes back on for libero")
					InstantaneouslySwapPlayers(activeLibero, playerCurrentlyLiberoedOff)
					playerCurrentlyLiberoedOff = null
					data.isLiberoOnCourt = false


	elif !data.isLiberoOnCourt:
		if mManager.isTeamAServing != data.isHuman: # i.e. we're receiving
			if playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][0]:
				var outgoingPlayer = playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][1]
				var incomingLibero = playerToBeLiberoedOnReceive[originalRotation1Player.stats.rotationPosition - 1][2]

				InstantaneouslySwapPlayers(outgoingPlayer, incomingLibero)
				data.isLiberoOnCourt = true
				playerCurrentlyLiberoedOff = outgoingPlayer
				activeLibero = incomingLibero
				if data.isHuman:
					Console.AddNewLine("Swapping " + outgoingPlayer.name + " for " + incomingLibero.name + " on receive")
		else: #serving
			if playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][0]:
				var outgoingPlayer = playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][1]
				var incomingLibero = playerToBeLiberoedOnServe[originalRotation1Player.stats.rotationPosition - 1][2]
				InstantaneouslySwapPlayers(outgoingPlayer, incomingLibero)
				data.isLiberoOnCourt = true
				playerCurrentlyLiberoedOff = outgoingPlayer
				activeLibero = incomingLibero
				if data.isHuman:
					Console.AddNewLine("Swapping " + outgoingPlayer.name + " for " + incomingLibero.name + " on serve")
	if data.isHuman:
		Console.AddNewLine("End check for libero change", Color.BLUE)
		if playerCurrentlyLiberoedOff:
			Console.AddNewLine("playerCurrentlyLiberoedOff = " + playerCurrentlyLiberoedOff.name, Color.DARK_KHAKI)
		else:
			Console.AddNewLine("No player Currently Liberoed Off", Color.DARK_KHAKI)
	#if !isLiberoOnCourt && middleBack:
#
		#if !isNextToSpike:
##			print(teamName + " current server: " + courtPlayers[server].stats.lastName)
			#if middleBack != courtPlayers[server]:
##				print("\nMiddleBack: " + middleBack.stats.lastName)
##				print("courtPlayers[server]: " + courtPlayers[server].stats.lastName + "\n")
				#InstantaneouslySwapPlayers(middleBack, libero)
				#isLiberoOnCourt = true
#
		#else:
			#InstantaneouslySwapPlayers(middleBack, libero)
			#isLiberoOnCourt = true

func InstantaneouslySwapPlayers(outgoing:Athlete, incoming:Athlete):
	if data.isHuman:
		Console.AddNewLine("Swapping " + outgoing.name + " for " + incoming.name)
	if !outgoing:
		Console.AddNewLine("ERROR, outgoing player does not exist", Color.RED)
		return
	if !incoming:
		Console.AddNewLine("ERROR, incoming player does not exist", Color.RED)
		return


	if outgoing == originalRotation1Player:
		originalRotation1Player = incoming

	if outgoing.stats.rotationPosition == -1:
		for athlete:Athlete in courtPlayerNodes:
			Console.AddNewLine("Position " + str(athlete.stats.rotationPosition) + ": " + athlete.stats.lastName)

	incoming.stats.rotationPosition = outgoing.stats.rotationPosition
	outgoing.stats.rotationPosition = -1

	var outgoingIndex = courtPlayerNodes.find(outgoing)
	if outgoingIndex == -1:
		# maybe the player is liberoed off at the time
		if data.isHuman:
			Console.AddNewLine("Outgoing player not found in courtPlayers", Color.LIME)
		outgoingIndex = benchPlayerNodes.find(outgoing)
		if outgoingIndex == -1:
			Console.AddNewLine("Player not found for substitution: " + outgoing.name)
			print("Not found outgoing player: " + outgoing.name)
			for lad in courtPlayerNodes:
				print ("court: " + lad.name + " " + str(lad.stats.rotationPosition))
			for lad in benchPlayerNodes:
				print ("bench: " + lad.name)

		else:
			Console.AddNewLine("Outgoing player was found in benchPlayerNodes", Color.LIME)
			var _incomingIndex = benchPlayerNodes.find(incoming)
			if _incomingIndex == -1:
				Console.AddNewLine("Not found bench swap player: " + incoming.name)
			else:
				playerCurrentlyLiberoedOff = incoming

				#benchPlayers.erase(incoming)
				#benchPlayers.erase(outgoing)
#
				#incoming.stats.rotationPosition = outgoing.stats.rotationPosition
				#outgoing.stats.rotationPosition = -1
				#
				#Console.AddNewLine("Outgoing index: " + str(outgoingIndex))
				#Console.AddNewLine("Incoming index: " + str(_incomingIndex))
				#
				#if outgoingIndex > _incomingIndex:
					#benchPlayers.insert(_incomingIndex, outgoing)
					#benchPlayers.insert(outgoingIndex, incoming)
				#else:
					#benchPlayers.insert(outgoingIndex, incoming)
					#benchPlayers.insert(_incomingIndex, outgoing)

				# if a player is being liberoed, do we want to keep the new player liberoed in the same circumstances as their predecessor?
				Console.AddNewLine("Show libero options for newly subbed player here", Color.BLUE_VIOLET)
				Console.AddNewLine("Show libero options for newly subbed player here", Color.BLUE_VIOLET)
				Console.AddNewLine("Show libero options for newly subbed player here", Color.BLUE_VIOLET)

				for subArray in playerToBeLiberoedOnServe:
					if subArray[1] == outgoing:
						subArray[1] = incoming
				for subArray in playerToBeLiberoedOnReceive:
					if subArray[1] == outgoing:
						subArray[1] = incoming

				if (incoming.stats.role != Enums.Role.Libero && outgoing.stats.role != Enums.Role.Libero):
					incoming.stats.role = outgoing.stats.role

				outgoing.stateMachine.SetCurrentState(outgoing.chillState)
				incoming.stateMachine.SetCurrentState(incoming.chillState)

			assert(incoming.stats.rotationPosition != -1)
			return


	courtPlayerNodes.erase(outgoing)

	var incomingIndex = benchPlayerNodes.find(incoming)
	if incomingIndex == -1:
		print("Not found incoming player: " + incoming.name)
		for lad in courtPlayerNodes:
			print ("court: " + lad.name)
		for lad in benchPlayerNodes:
			print ("bench: " + lad.name)
	benchPlayerNodes.erase(incoming)

	var tempPos = Vector3(incoming.position.x, 0, incoming.position.z)
	incoming.position = outgoing.position
	outgoing.position = tempPos
	outgoing.moveTarget = outgoing.position
#
	#incoming.stats.rotationPosition = outgoing.stats.rotationPosition
	#outgoing.stats.rotationPosition = -1

	courtPlayerNodes.insert(outgoingIndex, incoming)
	benchPlayerNodes.insert(incomingIndex, outgoing)

	assert(incoming.stats.rotationPosition != -1)

	if (incoming.stats.role != Enums.Role.Libero && outgoing.stats.role != Enums.Role.Libero):
		incoming.stats.role = outgoing.stats.role

	incoming.moveTarget = incoming.position
	outgoing.moveTarget = outgoing.position

	var tempRot = incoming.model.rotation
	incoming.model.rotation = outgoing.model.rotation
	outgoing.model.rotation = tempRot

	#if incoming.rotationPosition == 1 && mManager.isTeamAServing == isHuman && (stateMachine.currentState == serveState || stateMachine.currentState == prereceiveState):
		#incoming.stateMachine.SetCurrentState(incoming.serveState)

	outgoing.stateMachine.SetCurrentState(outgoing.chillState)
	incoming.ReEvaluateState()
	assert(incoming.stats.rotationPosition != -1)


func CachePlayers():
	for player:Athlete in courtPlayerNodes:
		if player.stats.role == Enums.Role.Setter:
			setter = player
		elif player.stats.role == Enums.Role.Middle && player.FrontCourt():
			middleFront = player
		elif player.stats.role == Enums.Role.Middle && !player.FrontCourt():
			middleBack = player
		elif player.stats.role == Enums.Role.Outside && player.FrontCourt():
			outsideFront = player
		elif player.stats.role == Enums.Role.Outside && !player.FrontCourt():
			outsideBack = player
		elif player.stats.role == Enums.Role.Opposite:
			oppositeHitter = player
	if setter == null || middleFront == null || middleBack == null \
	|| outsideFront == null || !outsideBack || !oppositeHitter:
		for athlete:Athlete in courtPlayerNodes:
			Console.AddNewLine(athlete.stats.lastName + " " + Enums.Role.keys()[athlete.stats.role] + " " + str(athlete.stats.rotationPosition), Color.ORANGE_RED)

func AutoSelectTeamLineup():
	data.matchPlayers.sort_custom(Callable(AthleteStats,"SortSet"))
	var orderedSetterList:Array[AthleteStats] =  data.matchPlayers.duplicate(false)

	data.matchPlayers.sort_custom(Callable(AthleteStats,"SortOutside"))
	var orderedOutsideList:Array[AthleteStats] = data.matchPlayers.duplicate(false)

	data.matchPlayers.sort_custom(Callable(AthleteStats,"SortLibero"))
	var orderedLiberoList:Array[AthleteStats] = data.matchPlayers.duplicate(false)

	data.matchPlayers.sort_custom(Callable(AthleteStats,"SortOpposite"))
	var orderedOppositeList:Array[AthleteStats] = data.matchPlayers.duplicate(false)

	data.matchPlayers.sort_custom(Callable(AthleteStats,"SortMiddle"))
	var orderedMiddleList:Array[AthleteStats] = data.matchPlayers.duplicate(false)

	var aptitudeLists:Array[Array] = [orderedSetterList,orderedLiberoList,orderedOutsideList,orderedOppositeList,orderedMiddleList]


	var nsetter:AthleteStats = orderedSetterList[0]
	SwapPlayer(nsetter, 0)
	nsetter.role = Enums.Role.Setter
	for list in aptitudeLists:
		list.erase(nsetter)

	var nmiddle1:AthleteStats = orderedMiddleList[0]
	var nmiddle2:AthleteStats = orderedMiddleList[1]
	nmiddle1.role = Enums.Role.Middle
	nmiddle2.role = Enums.Role.Middle
	SwapPlayer(nmiddle1, 2)
	SwapPlayer(nmiddle2, 5)
	for list in aptitudeLists:
		list.erase(nmiddle1)
		list.erase(nmiddle2)

	var noutside1:AthleteStats = orderedOutsideList[0]
	var noutside2:AthleteStats = orderedOutsideList[1]
	noutside1.role = Enums.Role.Outside
	noutside2.role = Enums.Role.Outside
	SwapPlayer(noutside1, 1)
	SwapPlayer(noutside2, 4)
	for list in aptitudeLists:
		list.erase(noutside1)
		list.erase(noutside2)
	var nopposite:AthleteStats = orderedOppositeList[0]
	nopposite.role = Enums.Role.Opposite
	SwapPlayer(nopposite, 3)
	for list in aptitudeLists:
		list.erase(nopposite)

	if data.matchPlayers.size() > 6:
		var nlibero:AthleteStats = orderedLiberoList[0]
		nlibero.role = Enums.Role.Libero

		SwapPlayer(nlibero, 6)
		for list in aptitudeLists:
			list.erase(nlibero)
		#libero = nlibero

	if data.matchPlayers.size() > 7:
		var backupSetter:AthleteStats = orderedSetterList[0]
		SwapPlayer(backupSetter, 7)
		backupSetter.role = Enums.Role.Setter
		for list in aptitudeLists:
			list.erase(backupSetter)

		for athlete in orderedLiberoList:
			athlete.role = Enums.Role.UNDEFINED

	if data.matchPlayers.size() > 12:
		var nlibero2:AthleteStats = orderedLiberoList[0]
		nlibero2.role = Enums.Role.Libero
		SwapPlayer(nlibero2, data.matchPlayers.size() - 1)
		for list in aptitudeLists:
			list.erase(nlibero2)
		#libero2 = nlibero2
	#nsetter.verticalJump += .5
	#nsetter.jumpSetHeight += .5
	#nsetter.spikeHeight += .5

func SwapPlayer(player:AthleteStats,newPostion:int):
	#print("-----------")
	#print("")
	var index = -1
	for i in range(data.matchPlayers.size()):
		if (data.matchPlayers[i] == player):
			index = i
			break

	#for i in range(matchPlayers.size()):
	#	print(str(matchPlayers[i].stats.role) + " " + str(i))

	#print ("")
	var temp = data.matchPlayers[newPostion]
	data.matchPlayers[newPostion] = player
	data.matchPlayers[index] = temp

	#for i in range(matchPlayers.size()):
	#	print(str(matchPlayers[i].stats.role) + " " + str(i))

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
		if data.markUndoChangesToRoles:
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
	elif athlete == middleBack || athlete == libero || athlete == libero2:
		return CheckIfFlipped(transitionPositionsSetterBack[5])

	elif athlete == middleFront:
		return CheckIfFlipped(transitionPositionsSetterBack[2])
	else:
		return Vector3.ZERO

func CheckIfFlipped(vectorToBeChecked:Vector3):
	return Vector3(flip * vectorToBeChecked.x, vectorToBeChecked.y, flip * vectorToBeChecked.z)

func Chill():
	stateMachine.SetCurrentState(chillState)
	for athlete:Athlete in courtPlayerNodes:
		athlete.stateMachine.isStateLocked = false
		if athlete == chosenReceiver:
			athlete.WaitThenChill(.75)
			continue
		athlete.stateMachine.SetCurrentState(athlete.chillState)

func AttemptBlock(spiker:Athlete):
	var blockingChance:float = 0
	#how many blockers are there?
	var blockers:Array = []
	for blocker in courtPlayerNodes:
		if blocker.FrontCourt():
			if blocker.stateMachine.currentState.nameOfState == "Block":
				if blocker.blockState.blockingTarget == spiker:
					blockers.append(blocker)

	#No block
	if len(blockers) == 0:
		mManager.BallOverNet(!data.isHuman)
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
		mManager.BallOverNet(!data.isHuman)
		return

	ball.blockResolver.AddUpcomingBlock(!data.isHuman, blockers, spiker)




		#stats.shirtNumber = shirtNumbers[j];
		#stats.image = images[j];
		#var athlete = Athlete.new()
		#athlete.stats = stats
		#matchPlayers.append(athlete)

		#DateTime oldest = new DateTime(1975, 1, 1);

		#int daysRange = (DateTime.Today.AddYears(-17) - oldest).Days;
		#stats.dob = oldest.AddDays( r.Next(daysRange));

		#team.CalculateMacroStats();

func CreateDefaultLiberoStrategy():
	# A note: the convention is that the setter is in one in the first rotation,
	# regardless of where the player rotates them to before the set.
	playerToBeLiberoedOnServe[0] = [true, middleBack, libero]
	# Middle will serve when setter in 2
	playerToBeLiberoedOnServe[1] = [false, null, null]
	playerToBeLiberoedOnServe[2] = [true, middleFront, libero]
	playerToBeLiberoedOnServe[3] = [true, middleFront, libero]
	# Middle will serve when setter in 5
	playerToBeLiberoedOnServe[4] = [false, null, null]
	playerToBeLiberoedOnServe[5] = [true, middleBack, libero]

	playerToBeLiberoedOnReceive[0] = [true, middleBack, libero]
	playerToBeLiberoedOnReceive[1] = [true, middleBack, libero]
	playerToBeLiberoedOnReceive[2] = [true, middleFront, libero]
	playerToBeLiberoedOnReceive[3] = [true, middleFront, libero]
	playerToBeLiberoedOnReceive[4] = [true, middleFront, libero]
	playerToBeLiberoedOnReceive[5] = [true, middleBack, libero]

	# Yeah, let's give libero2 a go!
	if libero2:
		for i in range(playerToBeLiberoedOnServe.size()):
			playerToBeLiberoedOnServe[i][2] = libero2
