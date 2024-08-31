extends Node2D

const cell_size: int = 64
const half_cell_size: int = cell_size / 2
const vertical_cell_offset = Vector2i(half_cell_size, cell_size)
const horizontal_cell_offset = Vector2i(cell_size, half_cell_size)
const rule_cell_offset = Vector2i(half_cell_size, half_cell_size)

const row_count: int = 6
const col_count: int = 5

const grid_size = cell_size * Vector2i(col_count, row_count)
const offset = -grid_size / 2

const row_lines_count = row_count + 1
const col_lines_count = col_count + 1

const hard_line_color = Color(0.6, 0.6, 0.6, 1.0)
const hard_line_width = 4.0
const soft_line_color = Color(0.6, 0.6, 0.6, 0.2)
const soft_line_width = 2.0

var dot_values: Array[Array]
var rules: Array[Array]

func _init() -> void:
	dot_values = []
	rules = []
	for row in range(row_count):
		dot_values.append([])
		rules.append([])
		for col in range(col_count):
			dot_values[row].append(null)
			rules[row].append(null)

func _draw() -> void:
	var row_from_x = 0
	var row_to_x =  col_count * cell_size
	var col_from_y = 0
	var col_to_y = row_count * cell_size
	for row in range(row_lines_count):
		var hard_row_y = cell_size * row
		draw_line(offset + Vector2i(row_from_x, hard_row_y), offset + Vector2i(row_to_x, hard_row_y), hard_line_color, hard_line_width)
		if (row < row_lines_count - 1):
			var soft_row_y = cell_size + cell_size * row - half_cell_size
			draw_line(offset + Vector2i(row_from_x, soft_row_y), offset + Vector2i(row_to_x, soft_row_y), soft_line_color, soft_line_width)
	for col in range(col_lines_count):
		var hard_col_x = cell_size * col
		draw_line(offset + Vector2i(hard_col_x, col_from_y), offset + Vector2i(hard_col_x, col_to_y), hard_line_color, hard_line_width)
		if (col < col_lines_count - 1):
			var soft_col_x = cell_size + cell_size * col - half_cell_size
			draw_line(offset + Vector2i(soft_col_x, col_from_y), offset + Vector2i(soft_col_x, col_to_y), soft_line_color, soft_line_width)

func get_closest_grid_position(screen_position: Vector2i) -> Vector2i:
	var viewport_size = get_viewport().size
	var offset_position = screen_position - (viewport_size - grid_size) / 2 
	var grid_position = Vector2i(floor(float(offset_position.x) / cell_size), floor(float(offset_position.y) / cell_size))
	return grid_position
	
func get_grid_screen_position(grid_position: Vector2i) -> Vector2i:
	var grid_screen_position = grid_position * cell_size - grid_size / 2
	return grid_screen_position

func update_dot_values(domino: Domino) -> void:
	var primary_position = domino.grid_position
	var primary_dot_value = domino.get_dot_value(true)
	dot_values[primary_position.y][primary_position.x] = primary_dot_value
	var secondary_position = domino.get_secondary_grid_position()
	var secondary_dot_value = domino.get_dot_value(false)
	dot_values[secondary_position.y][secondary_position.x] = secondary_dot_value

func remove_dot_values(domino: Domino) -> void:
	var primary_position = domino.grid_position
	dot_values[primary_position.y][primary_position.x] = null
	var secondary_position = domino.get_secondary_grid_position()
	dot_values[secondary_position.y][secondary_position.x] = null

func update_rules(rule: GridRule) -> void:
	var grid_position = rule.grid_position
	rules[grid_position.y][grid_position.x] = rule.dots
	print('todo')
	for r in rules:
		print(r)

func is_in_bounds(grid_position: Vector2i) -> bool:
	return 0 <= grid_position.x && grid_position.x < col_count && 0 <= grid_position.y && grid_position.y < row_count
