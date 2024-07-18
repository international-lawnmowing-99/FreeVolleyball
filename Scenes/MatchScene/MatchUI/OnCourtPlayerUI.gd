extends ColorRect

var athlete:Athlete
@onready var nameTextHolder = $VBoxContainer/Name
@onready var roleTextHolder = $VBoxContainer/Role
@onready var rotationPositionTextHolder = $VBoxContainer/RotationPosition


func UpdateFields():
	nameTextHolder.text = athlete.stats.lastName
	roleTextHolder.text = Enums.Role.keys()[athlete.stats.role]

	if athlete.rotationPosition && athlete.rotationPosition > 0 && athlete.rotationPosition <= 6:
		rotationPositionTextHolder.text = str(athlete.rotationPosition)

	else:
		rotationPositionTextHolder.text = ""
