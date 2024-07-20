extends Control
class_name PlayerStatsRow

@onready var firstName:Label = $AllItems/FirstName
@onready var lastName:Label = $AllItems/LastName
@onready var spikeHeight:Label = $AllItems/SpikeHeight
@onready var blockHeight:Label = $AllItems/BlockHeight
@onready var serve:Label = $AllItems/Serve
@onready var spike:Label = $AllItems/Spike
@onready var receive:Label = $AllItems/Receive
@onready var setLabel:Label = $AllItems/Set
@onready var stamina:Label = $AllItems/Stamina

@onready var selected:CheckBox = $AllItems/Selected

var athlete:AthleteStats
var playerStatsTable:PlayerStatsTable
var clubOrInternational:Enums.ClubOrInternational = Enums.ClubOrInternational.NotSelected

func DisplayPlayer(_athlete:AthleteStats):
	athlete = _athlete
	firstName.text = athlete.firstName
	lastName.text = athlete.lastName
	spikeHeight.text = str(int(athlete.spikeHeight * 100))
	blockHeight.text = str(int(athlete.blockHeight * 100))
	serve.text = str(int(athlete.serve))
	spike.text = str(int(athlete.spike))
	receive.text = str(int(athlete.reception))
	setLabel.text = str(int(athlete.set))
	stamina.text = str(int(athlete.serve))

	selected.button_pressed = athlete.uiSelected



func _on_selected_pressed():
	var maxPlayers = 12
	if clubOrInternational == Enums.ClubOrInternational.International:
		maxPlayers = 14
	if selected.button_pressed && playerStatsTable.selectedPlayers.size() >= maxPlayers:
		selected.button_pressed = false
		if clubOrInternational == Enums.ClubOrInternational.International:
			Console.AddNewLine("14 players selected already!")
		else:
			Console.AddNewLine("12 players selected already!")
		return

	if athlete:
		athlete.uiSelected = selected.button_pressed
		playerStatsTable.SelectUnselectAthlete(athlete)
