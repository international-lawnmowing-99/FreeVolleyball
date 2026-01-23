extends ColorRect
class_name OnCourtPlayer

var athlete:Athlete
@onready var nameTextHolder = $VBoxContainer/Name
@onready var roleTextHolder = $VBoxContainer/Role
@onready var rotationPositionTextHolder = $VBoxContainer/RotationPosition
@onready var freshnessBar:FreshnessBar = $VBoxContainer/FreshnessBar


func UpdateFields():
	nameTextHolder.text = athlete.stats.lastName
	roleTextHolder.text = Enums.Role.keys()[athlete.stats.role]

	if athlete.stats.rotationPosition && athlete.stats.rotationPosition > 0 && athlete.stats.rotationPosition <= 6:
		rotationPositionTextHolder.text = str(athlete.stats.rotationPosition)

	else:
		rotationPositionTextHolder.text = ""

	UpdateFreshnessBar(athlete.stats.freshness)

func UpdateFreshnessBar(freshness):
	freshnessBar.UpdateBar(freshness)
