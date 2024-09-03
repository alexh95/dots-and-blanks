class_name Domino
extends Node2D

var dots_top: int = 0
var dots_bot: int = 0

var grid_position: Vector2i
var grid_rotation: int

func put_dots(top: int, bot: int) -> void:
	dots_top = top
	dots_bot = bot
	$DotsTop.region_rect = Rect2(16 * dots_top, 0, 16, 16)
	$DotsBot.region_rect = Rect2(16 * dots_bot, 0, 16, 16)
