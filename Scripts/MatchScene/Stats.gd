extends Node
class_name Stats

var firstName:String
var lastName:String

var serve:float
var reception:float
var set:float
var dump:float
var spike:float
var block:float
var shirtNumber:int
var imageID:int = 0


var speed:float
var height:float
var digHeight:float
var verticalJump:float

var reactionTime:float
var gameRead:float

var power:float
var spikeHeight:float

var standingSetHeight:float
var jumpSetHeight:float
var blockHeight:float

var nation
#var role

var dob = Time.get_datetime_dict_from_system(true) 
var floatServe:float

#public int age(System.DateTime timeNow)
#return (int)(timeNow - dob).TotalDays/365;

func SetterEvaluation()->float:
	var eval = set
	
	if blockHeight > 2.43:
		eval += block / 5
	
	eval += serve / 10
	return eval
	
func LiberoEvaluation()->float:
	var eval = reception
	eval += set / 10

	return eval

func MiddleEvaluation()->float:
	var eval = blockHeight * 10 + block
	if blockHeight < 3:
		eval -= (300 - blockHeight*100)

	eval += serve / 10
	eval += spike / 4
#Debug.Log("MiddleEvaluation " + eval + " " + lastName);

	return eval
	
func OppositeEvaluation()->float:
	var eval = spike
	if spikeHeight < 2.9:
		eval -= 100
	eval += serve / 10
	eval += block / 10

	return eval

func OutsideEvaluation()->float:
	var eval = spike
	if spikeHeight < 2.9:
		eval -= (300 - spikeHeight * 100)
	eval += serve / 10
	eval += block / 10
	eval += reception / 2

	return eval

func SkillTotal()->float:
	return spike + block + set + reception + serve + spikeHeight*100
