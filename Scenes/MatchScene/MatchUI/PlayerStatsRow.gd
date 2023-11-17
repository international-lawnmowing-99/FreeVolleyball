extends Control
class_name PlayerStatsRow

@onready var firstName:Label = $AllItems/FirstName
@onready var lastName:Label = $AllItems/LastName
@onready var spikeHeight:Label = $AllItems/SpikeHeight
@onready var blockHeight:Label = $AllItems/BlockHeight
@onready var serve:Label = $AllItems/Serve
@onready var spike:Label = $AllItems/Spike
@onready var receive:Label = $AllItems/Receive
@onready var set:Label = $AllItems/Set
@onready var stamina:Label = $AllItems/Stamina

@onready var selected:CheckBox = $AllItems/Selected

var athlete:Athlete
var playerStatsTable:PlayerStatsTable

func DisplayPlayer(_athlete:Athlete):
	athlete = _athlete
	firstName.text = athlete.stats.firstName
	lastName.text = athlete.stats.lastName
	spikeHeight.text = str(int(athlete.stats.spikeHeight * 100))
	blockHeight.text = str(int(athlete.stats.blockHeight * 100))
	serve.text = str(int(athlete.stats.serve))
	spike.text = str(int(athlete.stats.spike))
	receive.text = str(int(athlete.stats.reception))
	set.text = str(int(athlete.stats.set))
	stamina.text = str(int(athlete.stats.serve))
	
	selected.button_pressed = athlete.uiSelected



func _on_selected_pressed():
	if selected.button_pressed && playerStatsTable.selectedPlayers.size() >= 12:
		selected.button_pressed = false
		Console.AddNewLine("Too many players selected already!")
		return
		
	if athlete: 
		athlete.uiSelected = selected.button_pressed
		playerStatsTable.SelectUnelectAthlete(athlete)
