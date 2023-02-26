extends Node

class_name NewMatchData



var teamASelected = false
var teamBSelected = false
var aChoiceState
var bChoiceState

const Enums = preload("res://Scripts/World/Enums.gd")
var clubOrInternational = Enums.ClubOrInternational.NotSelected
var gender = Enums.Gender.NotSelected
var homeTeam = Enums.HomeTeam.NotSelected

func ChooseRandom(gameWorld:GameWorld):
	var r = RandomNumberGenerator.new()
	r.randomize()
	if (r.randi_range(0,1) == 1):
		clubOrInternational = Enums.ClubOrInternational.International
	else:
		clubOrInternational = Enums.ClubOrInternational.Club
	
	if (r.randi_range(0,1)==1):
		gender = Enums.Gender.Female
	else:
		gender = Enums.Gender.Male
		
	if (r.randi_range(0,1)==1):
		homeTeam = Enums.HomeTeam.TeamA
	else:
		homeTeam = Enums.HomeTeam.TeamB
		
	aChoiceState = PlayerChoiceState.new(gameWorld)
	bChoiceState = PlayerChoiceState.new(gameWorld)
	aChoiceState = aChoiceState.ChooseRandom(gameWorld, clubOrInternational)
	bChoiceState = bChoiceState.ChooseRandom(gameWorld, clubOrInternational)
	

	var teamA:Team = gameWorld.GetTeam(aChoiceState, clubOrInternational)
	var teamB:Team = gameWorld.GetTeam(bChoiceState, clubOrInternational)

	if teamA.allPlayers.size() != 12:
		var now = Time.get_ticks_msec()
		for team in teamA.nation.league:
			team.Populate(gameWorld.firstNames, gameWorld.lastNames, r)
			teamA.nation.nationalTeam.players += team.allPlayers
		for team in teamB.nation.league:
			team.Populate(gameWorld.firstNames, gameWorld.lastNames, r)
			teamB.nation.nationalTeam.players += team.allPlayers
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " make teams")
		
	if clubOrInternational == Enums.ClubOrInternational.International:
		var now = Time.get_ticks_msec()
		teamA.SelectNationalTeam()
		teamB.SelectNationalTeam()
		var later = Time.get_ticks_msec()
		print(str((later-now)) + " select national team")
