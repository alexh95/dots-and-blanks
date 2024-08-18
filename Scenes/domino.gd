class_name Domino
extends Node2D

var dots_top: int = 0
var dots_bot: int = 0

var grid_position: Vector2i
var grid_rotation: int

func put_dots(top: int, bot: int) -> void:
	dots_top = top
	dots_bot = bot
	$DominoBlank/DominoDotsTop.region_rect = Rect2(16 * dots_top, 0, 16, 16)
	$DominoBlank/DominoDotsBot.region_rect = Rect2(16 * dots_bot, 0, 16, 16)

func get_domino_side_at_position(other_grid_position: Vector2i) -> int:
	if other_grid_position == grid_position:
		return DominoSide.PRIMARY
	elif other_grid_position == get_secondary_grid_position():
		return DominoSide.SECONDARY
	return DominoSide.NULL

func get_dot_value(primary: bool) -> int:
	if self.grid_rotation <= 1:
		return dots_top if primary else dots_bot
	else:
		return dots_bot if primary else dots_top

func get_dot_value_at_side(side: int) -> int:
	if side == DominoSide.PRIMARY:
		return get_dot_value(true)
	elif side == DominoSide.SECONDARY:
		return get_dot_value(false)
	return -1

func get_secondary_grid_position() -> Vector2i:
	var offset = Vector2i.DOWN if grid_rotation % 2 == 0 else Vector2i.RIGHT
	return grid_position + offset
	
func contains_point(screen_position: Vector2i) -> bool:
	var viewport_size = get_viewport().size
	var domino_space_position = Vector2(screen_position - viewport_size / 2)
	var to_position = position - domino_space_position
	var to_position_scaled = to_position / scale
	return $DominoBlank.get_rect().has_point(to_position_scaled)
