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

func ChooseRandom(gameWorld):
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
