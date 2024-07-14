extends Node
class_name Tournament

var listOfMatches = []
var standings

func CreateRoundRobin(teams:Array, maxRounds:int):
	var amendedTeams = teams
	
	if (teams.size()%2): # ie there are odd teams
		var bye = Team.new()
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

	
	for i in numberOfRounds:

		for j in numberOfTeams/2:
			var scheduledMatch:ScheduledMatch = ScheduledMatch.new()
			scheduledMatch.teamA = grid2D[0][j]
			scheduledMatch.teamB = grid2D[1][j]
			
			listOfMatches.append(scheduledMatch)
			print("Creating new game, " + scheduledMatch.teamA.teamName + " vs " + scheduledMatch.teamB.teamName)
		# Rotate the grid clockwise, holding the top left
		if numberOfTeams < 4:
			continue
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
		
