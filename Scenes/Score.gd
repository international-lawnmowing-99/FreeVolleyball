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

func _ready():
	mManager = get_tree().root.get_node("MatchScene")
	mManager.GameOver(false)
	teamAScoreText.text = str(teamAScore)
	teamASetsText.text = str(teamASetScore)
	teamBScoreText.text = str(teamBScore)
	teamBSetsText.text = str(teamBSetScore)

func PointToTeamA():
	teamAScore += 1
	
	if teamAScore > 24 && teamAScore > teamBScore + 1:
		teamASetScore += 1
		teamAScore = 0
		
		if teamASetScore > 2:
			for i in range(40):
				Console.AddNewLine("game over. Team A won", Color(randf(), randf(), randf(), randf()*255))
			mManager.GameOver(true)
		
		else:
			mManager.SetToTeamA()
			teamBScore = 0
			teamBScoreText.text = str(teamBScore)
			
	teamAScoreText.text = str(teamAScore)
	teamASetsText.text = str(teamASetScore)
	
func PointToTeamB():
	teamBScore += 1
	
	if teamBScore > 24 && teamBScore > teamAScore + 1:
		teamBSetScore += 1
		teamBScore = 0
		
		if teamBSetScore > 2:
			for i in range(40):
				Console.AddNewLine("game over. team B won well done chaps", Color(randf(), randf(), randf(), 1.0))
			mManager.GameOver(false)
			
		else:
			mManager.SetToTeamB()
			teamAScore = 0
			teamAScoreText.text = str(teamAScore)
			
	teamBScoreText.text = str(teamBScore)
	teamBSetsText.text = str(teamBSetScore)
