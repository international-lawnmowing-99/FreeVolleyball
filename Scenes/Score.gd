extends TextureRect
class_name Score

var mManager:MatchManager

@onready var teamANameText = $ScoreTeamAText
@onready var teamBNameText = $ScoreTeamBText
@onready var teamAScoreText = $ScoreTeamAPointScore
@onready var teamBScoreText = $ScoreTeamBPointScore
@onready var teamASetsText = $ScoreTeamASetScore
@onready var teamBSetsText = $ScoreTeamBSetScore

var teamAScore:int = 0
var teamBScore:int = 0
var teamASetScore:int = 0
var teamBSetScore:int = 0

var teamAPreviousScores:Array = []
var teamBPreviousScores:Array = []

func _ready():
	mManager = get_tree().root.get_node("MatchScene")
	teamAScoreText.text = str(teamAScore)
	teamASetsText.text = str(teamASetScore)
	teamBScoreText.text = str(teamBScore)
	teamBSetsText.text = str(teamBSetScore)

func PointToTeamA():
	teamAScore += 1

	# Set 5
	if teamASetScore == 2 && teamBSetScore == 2:
		if teamAScore > 14 && teamAScore > teamBScore + 1:
			teamAPreviousScores.append(teamAScore)
			teamBPreviousScores.append(teamBScore)

			teamASetScore += 1
			teamAScore = 0

			TeamAWon()


	# Sets 1 - 4
	elif teamAScore > 24 && teamAScore > teamBScore + 1:
		teamASetScore += 1

		teamAPreviousScores.append(teamAScore)
		teamBPreviousScores.append(teamBScore)

		teamAScore = 0

		if teamASetScore > 2:
			TeamAWon()

		else:
			mManager.NewSet()
			teamBScore = 0
			teamBScoreText.text = str(teamBScore)

	teamAScoreText.text = str(teamAScore)
	teamASetsText.text = str(teamASetScore)

func PointToTeamB():
	teamBScore += 1
	# Set 5
	if teamASetScore == 2 && teamBSetScore == 2:
		if teamBScore > 14 && teamBScore > teamAScore + 1:
			teamAPreviousScores.append(teamAScore)
			teamBPreviousScores.append(teamBScore)

			teamBSetScore += 1
			teamBScore = 0

			TeamBWon()

	# Sets 1 - 4
	elif teamBScore > 24 && teamBScore > teamAScore + 1:

		teamAPreviousScores.append(teamAScore)
		teamBPreviousScores.append(teamBScore)

		teamBSetScore += 1
		teamBScore = 0

		if teamBSetScore > 2:
			TeamBWon()

		else:
			mManager.NewSet()
			teamAScore = 0
			teamAScoreText.text = str(teamAScore)

	teamBScoreText.text = str(teamBScore)
	teamBSetsText.text = str(teamBSetScore)


func TeamAWon():
	for i in range(40):
		Console.AddNewLine("game over. Team A won", Color(randf(), randf(), randf(), randf()*255))

	teamBScore = 0
	teamBScoreText.text = str(teamBScore)
	mManager.GameOver(true)

func TeamBWon():
	for i in range(40):
		Console.AddNewLine("game over. team B won well done chaps", Color(randf(), randf(), randf(), 1.0))

	teamAScore = 0
	teamAScoreText.text = str(teamAScore)
	mManager.GameOver(false)
