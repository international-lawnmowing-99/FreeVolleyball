extends Resource
class_name Stats

@export var firstName:String
@export var lastName:String

@export var serve:float
@export var reception:float
@warning_ignore("shadowed_variable_base_class")
@export var set:float
@export var dump:float
@export var spike:float
@export var block:float
@export var shirtNumber:int
@export var imageID:int = 0


@export var speed:float
@export var height:float
@export var digHeight:float
@export var verticalJump:float

@export var reactionTime:float
@export var gameRead:float

@export var power:float
@export var spikeHeight:float

@export var standingSetHeight:float
@export var jumpSetHeight:float
@export var blockHeight:float

@export var nation:Nation
#var role

@export var dob:Dictionary = Time.get_datetime_dict_from_system(true)
@export var floatServe:float

@export var role:Enums.Role

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
