extends ColorRect
var Enums = preload("res://Scripts/World/Enums.gd")
var selectable:bool

func DisplayStats(athlete:Athlete):
	$FirstName.text = athlete.stats.firstName
	$LastName.text = athlete.stats.lastName
	var skill = (athlete.stats.set + athlete.stats.spike + athlete.stats.block + athlete.stats.reception)/4
	var skillText = $Skill
	skillText.text = str("%.0f" % skill)
#	if skill < 50:
#		skillText.modulate(Color.crimson)
#	elif skill < 60:
#		skillText.modulate(Color.aquamarine)
#	else:
#		skillText.modulate(Color.chartreuse)
	$Height.text = str("%.0f" % (athlete.stats.height *100)) + "cm"
	$Role.text = Enums.Role.keys()[athlete.role]

func DisplayEssentials():
	$LiberoIcon.hide()
	$CaptainIcon.hide()
	$SubstituteButton.hide()
	$CaptainButton.hide()

func ChangeColour(colour = Color(.75,0,0)):
	self.color = colour


func _on_NameCard_mouse_entered() -> void:
	ChangeColour(Color(0,1,1))
	selectable = true
	pass # Replace with function body.


func _on_NameCard_mouse_exited() -> void:
	selectable = false
	ChangeColour(Color(0,0,0))
	pass # Replace with function body.
