extends Node

class_name NewMatchData

enum ClubOrInternational {
NotSelected,
Club,
International
}
enum Gender {
NotSelected,
Male,
Female
}

enum HomeTeam {
NotSelected,
TeamA,
TeamB
}

var teamASelected = false
var teamBSelected = false
var aChoiceState
var bChoiceState

var clubOrInternational = ClubOrInternational.NotSelected;
var gender = Gender.NotSelected;
var homeTeam = HomeTeam.NotSelected;

func ChooseRandom(gameWorld):
	var r = RandomNumberGenerator.new()
	r.randomize()
	if (r.randi(0,1) == 1):
		clubOrInternational = ClubOrInternational.International;
	else:
		clubOrInternational = ClubOrInternational.Club;
	
	if (r.randi(0,1)==1):
		gender = Gender.Female;
	else:
		gender = Gender.Male;
		
	if (r.randi(0,1)==1):
		homeTeam = HomeTeam.TeamA;
	else:
		homeTeam = HomeTeam.TeamB;
		
	aChoiceState = PlayerChoiceState.new(gameWorld);
	bChoiceState = PlayerChoiceState.new(gameWorld);
	aChoiceState = aChoiceState.ChooseRandom(gameWorld, clubOrInternational);
	bChoiceState = bChoiceState.ChooseRandom(gameWorld, clubOrInternational);
