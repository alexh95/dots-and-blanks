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
	elif otherGridPosition == getSecondaryGridPosition():
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

func getSecondaryGridPosition():
	var offset = Vector2i(0, 1) if self.gridRotation % 2 == 0 else Vector2i(1, 0)
	return gridPosition + offset
