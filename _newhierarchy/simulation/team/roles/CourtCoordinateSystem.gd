extends RefCounted
class_name CourtCoordinateSystem

## Neutral legal rotation anchors shared by tactical consumers. Coordinates are
## local to the receiving/defending half: +X away from the net, Z across court.
const ROTATION_ANCHORS := {
	1: Vector3(4.2, 0.0, -3.0),
	2: Vector3(1.4, 0.0, -3.0),
	3: Vector3(1.1, 0.0, 0.0),
	4: Vector3(1.4, 0.0, 3.0),
	5: Vector3(4.2, 0.0, 3.0),
	6: Vector3(4.0, 0.0, 0.0)
}

static func is_front_court(position: int) -> bool:
	return position >= 2 and position <= 4
