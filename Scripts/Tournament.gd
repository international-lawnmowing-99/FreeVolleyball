extends Resource
class_name Tournament

@export var listOfMatches:Array[ScheduledMatch] = []
@export var standings:Array = []
@export var startDateUnix:int
@export var endDateUnix:int
@export var tournamentName:String = "Default Tournament"
@export var mainColour:Color

@export var numberOfParticipants:int
@export var participants:Array[TeamData]
@export var isMultiNationalTournament:bool = false
@export var homeTeams:Array[TeamData]
@export var poolSize:int

enum FinalsType {
	UNDEFINED,
	NONE,
	KNOCKOUT,
	SECONDCHANCEFORTOPTEAM
}
@export var finalsType:FinalsType
func CreateRoundRobin(teams:Array[TeamData], maxRounds:int, daysBetweenRounds:int, _startDateUnix:int):
	var amendedTeams:Array[TeamData] = teams

	if (teams.size()%2): # ie there are odd teams
		var bye = TeamData.new()
		bye.teamName = "Bye"
		amendedTeams.append(bye)


	var numberOfTeams:int = amendedTeams.size()
	print("numberOfTeams: " + str(numberOfTeams))
	var numberOfRounds = min(numberOfTeams-1, maxRounds)

	var grid2D = []

	for i in range(2):
		grid2D.append([])
		for j in range(numberOfTeams/2):
			grid2D[i].append(amendedTeams[i*numberOfTeams/2 + j])
			print(amendedTeams[i*numberOfTeams/2 + j].teamName)
		print("\n")


	var dateOfCurrentRoundUnix:int = _startDateUnix
	for i in numberOfRounds:
		print("Current round date: " + str(Time.get_date_dict_from_unix_time(dateOfCurrentRoundUnix)))
		for j in numberOfTeams/2:
			var scheduledMatch:ScheduledMatch = ScheduledMatch.new()
			var teamA:TeamData = grid2D[0][j]
			var teamB:TeamData = grid2D[1][j]
			scheduledMatch.teamA = teamA
			scheduledMatch.teamB = teamB
			scheduledMatch.tournamentRound = i
			scheduledMatch.unixDate = dateOfCurrentRoundUnix
			scheduledMatch.toBeSimulated = true
			listOfMatches.append(scheduledMatch)
			print("Creating new game, " + teamA.teamName + " vs " + teamB.teamName)
		# Rotate the grid clockwise, holding the top left
		if numberOfTeams < 4:
			print("WARNING: This probably shouldn't appear, but we're not shuffling the teams while making a round robin because there aren't enough")
		else:
			var temp = grid2D[1][0]
			for k in numberOfTeams/2 - 1:
				grid2D[1][k] = grid2D[1][k + 1]
			grid2D[1][numberOfTeams/2 - 1] = grid2D[0][numberOfTeams/2 - 1]
			for l in range(numberOfTeams/2-1, 1, -1):
				grid2D[0][l] = grid2D[0][l - 1]
			grid2D[0][1] = temp

			for q in range(2):
				for w in range(numberOfTeams/2):

					print(str(q) + ", " + str(w) + ": " + grid2D[q][w].teamName)
				print("\n")

		dateOfCurrentRoundUnix += 24*60*60 * daysBetweenRounds

func FillHomeTeams():
	for team:TeamData in homeTeams:
		participants.append(team)

func FillPreviousWinners(lastTournament:Tournament, numberToFill:int):
	for i in numberToFill:
		participants.append(lastTournament.standings[i])

func FillByWorldRankings(gameWorld:GameWorld, numberToFill:int):
	for i in numberToFill:
		participants.append(gameWorld.worldRankings[i])
