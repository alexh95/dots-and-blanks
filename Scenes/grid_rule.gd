class_name GridRule
extends Node2D

var grid_position: Vector2i
var dots: int = 0

func put_dots(value: int) -> void:
	dots = value
	$Rule/Dots.region_rect = Rect2(16 * value, 0, 16, 16)
