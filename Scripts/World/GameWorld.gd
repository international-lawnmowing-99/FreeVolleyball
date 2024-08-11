extends Resource
class_name GameWorld
const Enums = preload("res://Scripts/World/Enums.gd")

var firstNames:Array[String] = []
var lastNames:Array[String] = []
var nationsText:Array[String] = []

var worldRankings:Array[NationalTeam]
#There are players, organised in teams, in competitions, national teams, national competitions, and it's organised by continent for ease of navigation
@export var continents:Array[Continent] = []

@export var inGameUnixDate:int = 0

@export var previousMatches:Array[ScheduledMatch] = []
# Imagining this should be kept sorted in order of date
@export var upcomingMatches:Array[ScheduledMatch] = []

var matchesToSimulate:Array[ScheduledMatch] = []

func GenerateDefaultWorld(generatematchPlayers:bool):
	LoadText()
	randomize()

	for i in range(1,nationsText.size()):
		if (nationsText[i - 1].length() == 0 && nationsText[i + 1].length() == 0):
			continents.append(Continent.new(nationsText[i]))

		elif nationsText[i].length() > 0 && nationsText[i] != '/end':
			var _split = split(nationsText[i], [" ", '\t'])

			if _split[_split.size() - 2] == "-----":
				_split[_split.size() - 2] = _split[_split.size() - 1]

			var finalName = ""

			for j in range(_split.size()-3):
				finalName += _split[j] + " "

			var pop:int = 0

			pop =  int(_split[_split.size() - 3])

			continents[continents.size() - 1].nations.append(Nation.new(finalName, pop))
			#var continentIndex:int = continents.size() - 1
			#var nationIndex:int = continents[continents.size() - 1].nations.size() - 1

	for continentIndex:int in continents.size():
		for nationIndex:int in continents[continentIndex].nations.size():
			var currentNation:Nation = continents[continentIndex].nations[nationIndex]

			var choiceState:PlayerChoiceState = PlayerChoiceState.new(self)
			choiceState.continentIndex = continentIndex
			choiceState.nationIndices[choiceState.continentIndex] = nationIndex

			currentNation.Populate(choiceState, firstNames, lastNames, generatematchPlayers)

func GetNation(choiceState:PlayerChoiceState) -> Nation:
	return continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]]

func GetTeam(choiceState:PlayerChoiceState, mode) -> TeamData:
	if (mode == Enums.ClubOrInternational.Club):
		return continents[choiceState.continentIndex].\
				nations[choiceState.nationIndices[choiceState.continentIndex]].\
				league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]]
	else:
		return continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam

func LoadText():
	var f = FileAccess.open("res://Data/firstNames.txt", FileAccess.READ_WRITE)
	var g = FileAccess.open("res://Data/lastNames.txt", FileAccess.READ_WRITE)
	var n = FileAccess.open("res://Data/nationsAndPop.txt", FileAccess.READ)

	while not f.eof_reached():
		var line = f.get_line()
		if line != "\n":
			firstNames.append(line)
	while not g.eof_reached():
		lastNames.append(g.get_line())
	while not n.eof_reached():
		nationsText.append(n.get_line())

	f.close()
	g.close()
	n.close()

func split(s: String, delimeters, allow_empty: bool = false) -> Array:
	var parts := []

	var start := 0
	var i := 0

	while i < s.length():
		if s[i] in delimeters:
			if allow_empty or start < i:
				parts.push_back(s.substr(start, i - start))
			start = i + 1
		i += 1

	if allow_empty or start < i:
		parts.push_back(s.substr(start, i - start))

	return parts

## Maybe this doesn't really belong here, and should be left to the team
func PopulateTeam(playerChoiceState:PlayerChoiceState, team:TeamData):
	if team is NationalTeam:
		for clubTeamIndex in GetNation(playerChoiceState).league.size():
			var clubTeam:TeamData = GetNation(playerChoiceState).league[clubTeamIndex]
			if clubTeam.matchPlayers.size() > 0:
				Console.AddNewLine("ERROR! Couldn't add more players to full club team!")
			else:
				var clubTeamChoiceState:PlayerChoiceState = playerChoiceState.duplicate(false)
				clubTeamChoiceState.clubTeamIndices[clubTeamChoiceState.continentIndex][clubTeamChoiceState.nationIndices[clubTeamChoiceState.continentIndex]] = clubTeamIndex
				clubTeam.Populate(clubTeamChoiceState, firstNames, lastNames)

			if clubTeam.matchPlayers[0] in team.nationalPlayers:
				print("Stopping previously generated club players being inserted twice+ into national player list")
				continue
			team.nationalPlayers += clubTeam.matchPlayers
	else:
		if team.matchPlayers.size() > 0:
			Console.AddNewLine("ERROR! Couldn't add more players to full team!")
		else:
			team.Populate(playerChoiceState, firstNames, lastNames)

func SimulateDay():
	# Find all the games that need to be simulated
	#
	var earlier = Time.get_ticks_msec()
	for i in upcomingMatches.size():
		if upcomingMatches[i].unixDate == inGameUnixDate:
			if upcomingMatches[i].toBeSimulated:
				matchesToSimulate.append(upcomingMatches[i])
		elif false: # if the date is greater than the current date then stop
			break
		else: # catch errors
			pass

	var now = Time.get_ticks_msec()
	Console.AddNewLine(str(now - earlier) + "ms set up")
#

	var taskID = WorkerThreadPool.add_group_task(SimulateMatch,matchesToSimulate.size())
	WorkerThreadPool.wait_for_group_task_completion(taskID)

	var later = Time.get_ticks_msec()
	Console.AddNewLine(str(later - now) + "ms simulate " + str(matchesToSimulate.size()) + "match(es)")

	previousMatches += matchesToSimulate

	#for i in range(matchesToSimulate.size()):
	for scheduledMatch:ScheduledMatch in matchesToSimulate:
		print(scheduledMatch.string1)
		print(scheduledMatch.string2)

		#upcomingMatches.remove_at(matchesToSimulate.size()-i)


	matchesToSimulate.clear()

	var evenLater = Time.get_ticks_msec()
	Console.AddNewLine(str(evenLater - later) + "ms clean up after simulation")

func SimulateMatch(scheduledMatchIndex:int):
	var scheduledMatch:ScheduledMatch = matchesToSimulate[scheduledMatchIndex]
	scheduledMatch.string1 = ("Simulating: " + scheduledMatch.teamA.teamName + " vs " + scheduledMatch.teamB.teamName + " on " + str(Time.get_date_dict_from_unix_time(scheduledMatch.unixDate)))

	if scheduledMatch.teamA.teamName == "Bye" || scheduledMatch.teamB.teamName == "Bye":
		scheduledMatch.string2 = "Bye, no points"
		return


	##Perform pre-match stuff.
	#game.teamA.AssessRival(game.teamB)
	#game.teamB.AssessRival(game.teamA)
	#game.teamA.SelectSquad()
	#game.teamB.SelectSquad()

	var matchWon:bool = false
	var teamASetScore:int = 0
	var teamBSetScore:int = 0
	while !matchWon:
		##Perform pre-set stuff
		#game.teamA.AssignStartingRoles()
		#game.teamA.ChooseStartingRotation()

		var setWon:bool = false
		var teamAScore:int = 0
		var teamBScore:int = 0
		while !setWon:
			##Do pre-point stuff
			#game.teamA.ConsiderSubstitutes()
			#game.teamA.ConsiderLiberoUse()
			#game.teamA.GenerateAttackStrategy() # This is going to be complicated!
			#game.teamA.GenerateServeStrategy()
			#game.teamA.GenerateReceiveStrategy()
			#game.teamA.GenerateBlockStrategy()
			#game.teamA.GenerateDefenceStrategy()

			##Finally actually play a point!
			#SimulatePoint()
			if randi()%2 == 1:
				teamAScore += 1
			else:
				teamBScore += 1


			#CheckForWin()
			if teamASetScore == 2 && teamBSetScore == 2:
				if teamAScore >= 15 && teamAScore - 2 >= teamBScore:
					scheduledMatch.teamACompletedScores.append(teamAScore)
					scheduledMatch.teamBCompletedScores.append(teamBScore)
					setWon = true
					teamASetScore += 1

				elif teamBScore >= 15 && teamBScore - 2 >= teamAScore:
					scheduledMatch.teamACompletedScores.append(teamAScore)
					scheduledMatch.teamBCompletedScores.append(teamBScore)
					setWon = true
					teamBSetScore += 1
			else:
				if teamAScore >= 25 && teamAScore - 2 >= teamBScore:
					scheduledMatch.teamACompletedScores.append(teamAScore)
					scheduledMatch.teamBCompletedScores.append(teamBScore)
					setWon = true
					teamASetScore += 1

				elif teamBScore >= 25 && teamBScore - 2 >= teamAScore:
					scheduledMatch.teamACompletedScores.append(teamAScore)
					scheduledMatch.teamBCompletedScores.append(teamBScore)
					setWon = true
					teamBSetScore += 1

		if teamASetScore >= 3:
			matchWon = true
			scheduledMatch.winner = scheduledMatch.teamA
		elif teamBSetScore >= 3:
			matchWon = true
			scheduledMatch.winner = scheduledMatch.teamB

	scheduledMatch.completed = true

	var scoresString = ""
	for i in range(teamASetScore + teamBSetScore):
		scoresString += str(scheduledMatch.teamACompletedScores[i]) + ":" + str(scheduledMatch.teamBCompletedScores[i]) + " "
	scheduledMatch.string2 = ("Match over, " + scheduledMatch.winner.teamName + " won! " + str(max(teamASetScore, teamBSetScore)) + ":" + str(min(teamASetScore, teamBSetScore)) + " ... Scores: " + scoresString)


func CreateYearlyTournaments():
	var currentYear:int = Time.get_date_dict_from_unix_time(inGameUnixDate)["year"]
	if currentYear%4 == 0:
		print("The Olypmics will happen this year, barring a war or a virus! \nThe dates of all other tournaments will be adjusted")
		# Schedule an event where the qualification of the final teams will take place.
	if currentYear%2 == 0:
		print("The Continental Championships will happen this year - can you contain your enthusiasm???")
	else:
		print("The World Championships will happen this year")

	print("The VNL will happen this year")
	print("The Club World Championships will happen this year")
	print("Everyone's local leagues will happen, as every year")


func UpdateWorldRankings():
	worldRankings.sort_custom(func(a,b):return a.rankingPoints > b.rankingPoints )
