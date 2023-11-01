extends Control

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
	spikeHeight.text = str(athlete.stats.spikeHeight)
	blockHeight.text = str(athlete.stats.blockHeight)
	
	
