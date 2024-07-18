extends Panel

func Populate(athlete:Athlete):
	$Name.text = athlete.stats.firstName + " " + athlete.stats.lastName
	$Serve.text = "Serve: " + str(int(athlete.stats.serve))
	$Receive.text = "Receive: " + str(int(athlete.stats.reception))
	$Set.text = "Set: " + str(int(athlete.stats.set))
	$Block.text = "Block: " + str(int(athlete.stats.block))
	$Spike.text = "Spike: " + str(int(athlete.stats.spike))
	$Speed.text = "Speed: " + str(int(athlete.stats.speed))
	$SpikeHeight.text = "Spike Height: " + str(int(athlete.stats.spikeHeight*100))
	$BlockHeight.text = "Block Height: " + str(int(athlete.stats.blockHeight*100))

