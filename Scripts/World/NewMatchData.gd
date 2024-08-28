extends RefCounted

class_name NewMatchData

var aChoiceState:PlayerChoiceState
var bChoiceState:PlayerChoiceState

var clubOrInternational = Enums.ClubOrInternational.NotSelected

var gender = Enums.Gender.NotSelected
var homeTeam = Enums.HomeTeam.NotSelected

var location
var date
var isTeamAServing:bool

func ChooseRandom(gameWorld:GameWorld):
	randomize()
	if (randi_range(0,1) == 1):
		clubOrInternational = Enums.ClubOrInternational.International
	else:
		clubOrInternational = Enums.ClubOrInternational.Club

	if (randi_range(0,1)==1):
		gender = Enums.Gender.Female
	else:
		gender = Enums.Gender.Male

	if (randi_range(0,1)==1):
		homeTeam = Enums.HomeTeam.TeamA
	else:
		homeTeam = Enums.HomeTeam.TeamB

	if randi_range(1,2) == 1:
		isTeamAServing = false
	else:
		isTeamAServing = true

	aChoiceState = PlayerChoiceState.new(gameWorld)
	bChoiceState = PlayerChoiceState.new(gameWorld)
	aChoiceState = aChoiceState.ChooseRandom(gameWorld, clubOrInternational)
	bChoiceState = aChoiceState# bChoiceState.ChooseRandom(gameWorld, clubOrInternational)
	#bChoiceState = aChoiceState


	var teamA:TeamData = gameWorld.GetTeam(aChoiceState, clubOrInternational)
	var teamB:TeamData = gameWorld.GetTeam(bChoiceState, clubOrInternational)

	if clubOrInternational == Enums.ClubOrInternational.Club:
		var now = Time.get_ticks_msec()
		teamA.Populate(aChoiceState, gameWorld.firstNames, gameWorld.lastNames)
		if teamA != teamB:
			teamB.Populate(bChoiceState, gameWorld.firstNames, gameWorld.lastNames)
		else:
			print("Team A and Team B are the same, though chosen randomly!")
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " make 2 team(s)")

	if clubOrInternational == Enums.ClubOrInternational.International:
		var now = Time.get_ticks_msec()
		var nationA:Nation = gameWorld.GetNation(aChoiceState)
		var nationB:Nation = gameWorld.GetNation(bChoiceState)
		for team in nationA.league:
			team.Populate(aChoiceState, gameWorld.firstNames, gameWorld.lastNames)
			nationA.nationalTeam.nationalPlayers += team.matchPlayers
		if teamA != teamB:
			for team in nationB.league:
				team.Populate(bChoiceState, gameWorld.firstNames, gameWorld.lastNames)
				nationB.nationalTeam.nationalPlayers += team.matchPlayers
		else:
			print("Team A and Team B are the same national teams! Randomly chosen. ")
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " make all teams in nation(s)")
