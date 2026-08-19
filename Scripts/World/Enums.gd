extends Node

enum Phase {
	PreMatch,
	PreSet,
	PreServe,
	Serve,
	Receive,
	Set,
	Attack,
	Block,
	CelebrateOrCommiserate
}


enum ClubOrInternational {
NotSelected,
Club,
International
}

enum Gender {
NotSelected,
Male,
Female
}

enum HomeTeam {
NotSelected,
TeamA,
TeamB
}

#Weird bug when setter was the first element, couldn't be set, so to say...
enum Role{
UNDEFINED,
Setter,
Outside,
Opposite,
Middle,
Libero
}

enum NameCardState{
	UNDEFINED,
	Substitutable
	}
