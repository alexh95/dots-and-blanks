class_name Domino
extends Node2D

var dots_primary: int = 0
var dots_secondary: int = 0

var grid_position: Vector2i
var grid_rotation: int

func put_dots(primary: int, secondary: int) -> void:
	dots_primary = primary
	dots_secondary = secondary
	$DotsPrimary.region_rect = Rect2(16 * dots_primary, 0, 16, 16)
	$DotsSecondary.region_rect = Rect2(16 * dots_secondary, 0, 16, 16)
