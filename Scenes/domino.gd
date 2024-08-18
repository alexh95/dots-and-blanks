class_name Domino
extends Node2D

var dotsTop: int = 0
var dotsBot: int = 0

var gridPosition: Vector2i
var gridRotation: int

func putDots(top: int, bot: int):
	dotsTop = top
	dotsBot = bot
	$DominoBlank/DominoDotsTop.region_rect = Rect2(16 * dotsTop, 0, 16, 16)
	$DominoBlank/DominoDotsBot.region_rect = Rect2(16 * dotsBot, 0, 16, 16)

func getDominoSideAtPosition(otherGridPosition: Vector2i):
	if otherGridPosition == gridPosition:
		return DominoSide.PRIMARY
	elif otherGridPosition == get_secondary_grid_position():
		return DominoSide.SECONDARY
	return DominoSide.NULL

func getDotValue(primary: bool):
	if self.gridRotation <= 1:
		return dotsTop if primary else dotsBot
	else:
		return dotsBot if primary else dotsTop

func getDotValueAtSide(side: int):
	if side == DominoSide.PRIMARY:
		return getDotValue(true)
	elif side == DominoSide.SECONDARY:
		return getDotValue(false)
	return -1

func get_secondary_grid_position() -> Vector2i:
	var offset = Vector2i.DOWN if gridRotation % 2 == 0 else Vector2i.RIGHT
	return gridPosition + offset
	
func contains_point(screen_position: Vector2i) -> bool:
	var viewport_size = get_viewport().size
	var domino_space_position = Vector2(screen_position - viewport_size / 2)
	var to_position = position - domino_space_position
	var to_position_scaled = to_position / scale
	return $DominoBlank.get_rect().has_point(to_position_scaled)
