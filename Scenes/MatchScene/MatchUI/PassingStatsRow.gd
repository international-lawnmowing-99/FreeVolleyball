extends HBoxContainer

class_name PassingStatsRow

@onready var recordNumberLabel:Label = $RecordNumber
@onready var playerNameLabel:Label = $Nama
@onready var attemptsLabel:Label = $AttemptsLabel
@onready var perfectLabel:Label = $PerfectLabel
@onready var goodLabel:Label = $GoodLabel
@onready var poorLabel:Label = $PoorLabel
@onready var errorLabel:Label = $ErrorLabel
@onready var percentageLabel:Label = $PercentageLabel

func UpdateRowDisplay(rowNumber, athlete:Athlete, setsExamined:Array[int] = [1,1,1,1,1]):
	recordNumberLabel.text = str(rowNumber)
	playerNameLabel.text = athlete.stats.firstName + " " + athlete.stats.lastName

	var attempts:int = 0
	var perfect:int = 0
	var good:int = 0
	var poor:int = 0
	var error:int = 0
	var percentage:float = 0

	for i in range(setsExamined.size()):
		perfect += athlete.stats.matchPassingStats.perfect[i] * setsExamined[i]
		good += athlete.stats.matchPassingStats.good[i] * setsExamined[i]
		poor += athlete.stats.matchPassingStats.poor[i] * setsExamined[i]
		error += athlete.stats.matchPassingStats.error[i] * setsExamined[i]

	attempts = perfect + good + poor + error
	if attempts == 0:
		percentage = 0
	else:
		percentage = (perfect * 3.0 + good * 2.0 + poor)/(attempts as float)
		#Console.AddNewLine(str(attempts))




	attemptsLabel.text = str(attempts)
	perfectLabel.text = str(perfect)
	goodLabel.text = str(good)
	poorLabel.text = str(poor)
	errorLabel.text = str(error)
	percentageLabel.text = str("%.3f" % percentage)
