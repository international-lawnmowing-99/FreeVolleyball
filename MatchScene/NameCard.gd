extends ColorRect
var Enums = preload("res://Scripts/World/Enums.gd")


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
