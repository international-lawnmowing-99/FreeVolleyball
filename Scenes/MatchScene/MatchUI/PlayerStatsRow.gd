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

func DisplayPlayer(athlete:Athlete):
	firstName.text = athlete.stats.firstName
	lastName.text = athlete.stats.lastName
	spikeHeight.text = str(int(athlete.stats.spikeHeight * 100))
	blockHeight.text = str(int(athlete.stats.blockHeight * 100))
	serve.text = str(int(athlete.stats.serve))
	spike.text = str(int(athlete.stats.spike))
	receive.text = str(int(athlete.stats.reception))
	set.text = str(int(athlete.stats.set))
	stamina.text = str(int(athlete.stats.serve))
	
	selected.button_pressed = true
