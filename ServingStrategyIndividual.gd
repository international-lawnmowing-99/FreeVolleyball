extends Resource
class_name ServingStrategyIndividual
enum HighLevelServePlan{
	UNDEFINED,
	TARGETLIBERO
	}


@export var serveType:AthleteHumanServeState.ServeType = AthleteHumanServeState.ServeType.UNDEFINED
@export var serveAggression:AthleteHumanServeState.ServeAggression = AthleteHumanServeState.ServeAggression.UNDEFINED
@export var highLevelPlan:HighLevelServePlan = HighLevelServePlan.UNDEFINED
