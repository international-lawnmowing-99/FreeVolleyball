extends VBoxContainer
class_name TeamChoice

var choiceState:PlayerChoiceState
var gameWorld:GameWorld

var clubOrInternationalMode:Enums.ClubOrInternational = Enums.ClubOrInternational.NotSelected

@onready var clubOrInternationalLabel:Label = $ClubInternationalLabel
@onready var clubTeamLabel:Label = $ClubTeamLabel
@onready var continentLabel:Label = $ContinentLabel
@onready var nationLabel:Label = $NationLabel

func Init(_gameWorld, _choiceState):
	gameWorld = _gameWorld
	choiceState = _choiceState
	continentLabel.hide()
	nationLabel.hide()
	clubTeamLabel.hide()

func ValidChoice() -> bool:
	match clubOrInternationalMode:
		Enums.ClubOrInternational.NotSelected:
			return false
		Enums.ClubOrInternational.International:
			if choiceState.nationIndices[choiceState.continentIndex] < 0:
				return false
		Enums.ClubOrInternational.Club:
			if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
				return false
	return true

func _on_club_or_international_left_button_pressed():
	match clubOrInternationalMode:
		Enums.ClubOrInternational.NotSelected:
			clubOrInternationalMode = Enums.ClubOrInternational.Club
			clubOrInternationalLabel.text = "Club"
			continentLabel.show()
			if nationLabel.visible:
				clubTeamLabel.show()
		Enums.ClubOrInternational.Club:
			clubOrInternationalMode = Enums.ClubOrInternational.International
			clubOrInternationalLabel.text = "International"
			clubTeamLabel.hide()
		Enums.ClubOrInternational.International:
			clubOrInternationalMode = Enums.ClubOrInternational.Club
			clubOrInternationalLabel.text = "Club"
			if nationLabel.visible:
				clubTeamLabel.show()

func _on_club_or_international_right_button_pressed():
	match clubOrInternationalMode:
		Enums.ClubOrInternational.NotSelected:
			clubOrInternationalMode = Enums.ClubOrInternational.International
			clubOrInternationalLabel.text = "International"
			continentLabel.show()
			clubTeamLabel.hide()
		Enums.ClubOrInternational.Club:
			clubOrInternationalMode = Enums.ClubOrInternational.International
			clubOrInternationalLabel.text = "International"
			clubTeamLabel.hide()
		Enums.ClubOrInternational.International:
			clubOrInternationalMode = Enums.ClubOrInternational.Club
			clubOrInternationalLabel.text = "Club"
			if nationLabel.visible:
				clubTeamLabel.show()


func _on_continent_left_button_pressed():
	choiceState.continentIndex -= 1
	if choiceState.continentIndex < 0:
		choiceState.continentIndex = gameWorld.continents.size() - 1
		
	continentLabel.text = gameWorld.continents[choiceState.continentIndex].continentName
	nationLabel.show()
	
	if choiceState.nationIndices[choiceState.continentIndex] < 0:
		nationLabel.text = "Nation"
		clubTeamLabel.text = "Club Team"
	else:
		nationLabel.text = gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam.teamName
		if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
			clubTeamLabel.text = "Club Team"
		else:
			clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
			nations[choiceState.nationIndices[choiceState.continentIndex]].\
			league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName
	if clubOrInternationalMode == Enums.ClubOrInternational.Club:
		clubTeamLabel.show()
	

func _on_continent_right_button_pressed():
	choiceState.continentIndex += 1
	if choiceState.continentIndex > gameWorld.continents.size() - 1:
		choiceState.continentIndex = 0
		
	continentLabel.text = gameWorld.continents[choiceState.continentIndex].continentName
	nationLabel.show()
	
	if choiceState.nationIndices[choiceState.continentIndex] < 0:
		nationLabel.text = "Nation"
		clubTeamLabel.text = "Club Team"
	else:
		nationLabel.text = gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam.teamName
		if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
			clubTeamLabel.text = "Club Team"
		else:
			clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
			nations[choiceState.nationIndices[choiceState.continentIndex]].\
			league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName
	if clubOrInternationalMode == Enums.ClubOrInternational.Club:
		clubTeamLabel.show()

func _on_nation_left_button_pressed():
	choiceState.nationIndices[choiceState.continentIndex] -= 1
	if choiceState.nationIndices[choiceState.continentIndex] < 0:
		choiceState.nationIndices[choiceState.continentIndex] = gameWorld.continents[choiceState.continentIndex].nations.size() - 1
	
	nationLabel.text = gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam.teamName

	if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
		clubTeamLabel.text = "Club Team"
	else:
		clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
		nations[choiceState.nationIndices[choiceState.continentIndex]].\
		league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName

func _on_nation_right_button_pressed():
	choiceState.nationIndices[choiceState.continentIndex] += 1
	if choiceState.nationIndices[choiceState.continentIndex] > gameWorld.continents[choiceState.continentIndex].nations.size() - 1:
		choiceState.nationIndices[choiceState.continentIndex] = 0
	
	nationLabel.text = gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam.teamName
	if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
		clubTeamLabel.text = "Club Team"
	else:
		clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
		nations[choiceState.nationIndices[choiceState.continentIndex]].\
		league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName
		
func _on_club_team_left_button_pressed():
	if choiceState.nationIndices[choiceState.continentIndex] < 0:
		return
	
	choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] -= 1
	if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] < 0:
		choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] = gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].league.size() - 1
		
	clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
				nations[choiceState.nationIndices[choiceState.continentIndex]].\
				league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName


func _on_club_team_right_button_pressed():
	if choiceState.nationIndices[choiceState.continentIndex] < 0:
		return
	
	choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] += 1
	if choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] > gameWorld.continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].league.size() - 1:
		choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]] = 0
	
	clubTeamLabel.text = gameWorld.continents[choiceState.continentIndex].\
				nations[choiceState.nationIndices[choiceState.continentIndex]].\
				league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]].teamName
