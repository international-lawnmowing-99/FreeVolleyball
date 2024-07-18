extends Node2D
func _ready() -> void:
	randomize()
	var attack:int = 50
	var defence:int = 100

	for i in range (10):
		#probabilities(float(i + 1)*10, float(defence))
		print(str(i))
		probabilities((float(i + 1)*10) *(float(i + 1)*10), float (defence * defence))

##	for j in range(5):
##		attack = 20 * (j + 1)
##		print(str(attack) + " attack")
#	for k in range (10):
#		defence = 10 * (k + 1)
#		print(str(defence) + " defence")
#
#		var awins = 0
#		var bwins = 0
#		var draws = 0
#
#		for i in range(10000):
#			var aroll = randi()%attack + 1
#			var broll = randi()%defence + 1
#			if aroll>broll:
#				awins+= 1
#			elif broll > aroll:
#				bwins += 1
#			else:
#				draws += 1
#
#		print ("attack wins: " + str(awins) + "   def: " + str(bwins) + "   draws: " + str(draws))
#		print ("Attack %: " + str(float(awins)/(awins + bwins + draws)*100))

func _on_ButtonMode_pressed() -> void:
	if $ColorRect/ModeLabel/ModeText.text == "International":
		$ColorRect/ModeLabel/ModeText.text = "Club"
		$ColorRect/ClubLabel.show()
	else:
		$ColorRect/ModeLabel/ModeText.text = "International"
		$ColorRect/ClubLabel.hide()

func probabilities(attack:float, defence:float):
	var tie:float
	var attackWins:float
	var defWins:float

	if attack >= defence:
		tie = 1/float(attack)
		defWins = (float(defence) - 1) / (2 * attack)
		attackWins = (2*attack - defence - 1) / (2 * attack)

	else:
		tie = 1/float(attack)
		attackWins = (float(attack) - 1) / (2 * defence)
		defWins = (2*defence - attack - 1) / (2 * defence)
	print ("attack wins: " + str(attackWins) + "   def: " + str(defWins) + "   draws: " + str(tie))

