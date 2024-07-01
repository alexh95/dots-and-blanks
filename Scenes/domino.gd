extends Node2D

var dotsTop: int = 0
var dotsBot: int = 0

func putDots(top: int, bot: int):
	dotsTop = top
	dotsBot = bot
	$DominoBlank/DominoDotsTop.region_rect = Rect2(16 * dotsTop, 0, 16, 16)
	$DominoBlank/DominoDotsBot.region_rect = Rect2(16 * dotsBot, 0, 16, 16)
