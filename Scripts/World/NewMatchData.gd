extends Node

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
	bChoiceState = bChoiceState.ChooseRandom(gameWorld, clubOrInternational)
	#bChoiceState = aChoiceState

	var teamA:Team = gameWorld.GetTeam(aChoiceState, clubOrInternational)
	var teamB:Team = gameWorld.GetTeam(bChoiceState, clubOrInternational)

	if clubOrInternational == Enums.ClubOrInternational.Club:
		var now = Time.get_ticks_msec()
		teamA.Populate(gameWorld.firstNames, gameWorld.lastNames)
		if teamA != teamB:
			teamB.Populate(gameWorld.firstNames, gameWorld.lastNames)
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " make 2 team(s)")

	if clubOrInternational == Enums.ClubOrInternational.International:
		var now = Time.get_ticks_msec()
		for team in teamA.nation.league:
			team.Populate(gameWorld.firstNames, gameWorld.lastNames)
			teamA.nation.nationalTeam.nationalPlayers += team.matchPlayers
		if teamA != teamB:
			for team in teamB.nation.league:
				team.Populate(gameWorld.firstNames, gameWorld.lastNames)
				teamB.nation.nationalTeam.nationalPlayers += team.matchPlayers
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " make all teams in nation(s)")
