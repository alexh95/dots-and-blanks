extends Node2D

const cellSize: int = 64
const halfCellSize: int = cellSize / 2
const verticalCellOffset = Vector2i(halfCellSize, cellSize)
const horizontalCellOffset = Vector2i(cellSize, halfCellSize)

const rowCount: int = 6
const colCount: int = 5
#const gridCenter = Vector2i(colCount, rowCount) / 2

const gridSize = cellSize * Vector2i(colCount, rowCount)
const offset = -gridSize / 2

const rowLinesCount = rowCount + 1
const colLinesCount = colCount + 1

const hardLineColor = Color(0.6, 0.6, 0.6, 1.0)
const hardLineWidth = 4.0
const softLineColor = Color(0.6, 0.6, 0.6, 0.2)
const softLineWidth = 2.0

var dotValues: Array[Array] = []

func _init():
	for row in range(rowCount):
		dotValues.append([])
		for col in range(colCount):
			dotValues[row].append(-1)

func _draw():
	var rowFromX = 0
	var rowToX =  colCount * cellSize
	var colFromY = 0
	var colToY = rowCount * cellSize
	
	for row in range(rowLinesCount):
		var hardRowY = cellSize * row
		draw_line(offset + Vector2i(rowFromX, hardRowY), offset + Vector2i(rowToX, hardRowY), hardLineColor, hardLineWidth)
		if (row < rowLinesCount - 1):
			var softRowY = cellSize + cellSize * row - halfCellSize
			draw_line(offset + Vector2i(rowFromX, softRowY), offset + Vector2i(rowToX, softRowY), softLineColor, softLineWidth)
	for col in range(colLinesCount):
		var hardColX = cellSize * col
		draw_line(offset + Vector2i(hardColX, colFromY), offset + Vector2i(hardColX, colToY), hardLineColor, hardLineWidth)
		if (col < colLinesCount - 1):
			var softColX = cellSize + cellSize * col - halfCellSize
			draw_line(offset + Vector2i(softColX, colFromY), offset + Vector2i(softColX, colToY), softLineColor, softLineWidth)

func get_closest_grid_position(screenPosition: Vector2i):
	var viewport_size = get_viewport().size
	var offset_position = screenPosition - (viewport_size - gridSize) / 2 
	var grid_position = Vector2i(floor(float(offset_position.x) / cellSize), floor(float(offset_position.y) / cellSize))
	return grid_position
	
func get_grid_screen_position(grid_position: Vector2i) -> Vector2i:
	var grid_screen_position = grid_position * cellSize - gridSize / 2
	return grid_screen_position

func update_dot_values(domino: Domino):
	var primary_position = domino.gridPosition
	var primary_dot_value = domino.getDotValue(true)
	dotValues[primary_position.y][primary_position.x] = primary_dot_value
	var secondary_position = domino.get_secondary_grid_position()
	var secondary_dot_value = domino.getDotValue(false)
	dotValues[secondary_position.y][secondary_position.x] = secondary_dot_value

func remove_dot_values(domino: Domino):
	var primary_position = domino.gridPosition
	dotValues[primary_position.y][primary_position.x] = -1
	var secondary_position = domino.get_secondary_grid_position()
	dotValues[secondary_position.y][secondary_position.x] = -1

func isInBounds(grid_position: Vector2i) -> bool:
	return 0 <= grid_position.x && grid_position.x < colCount && 0 <= grid_position.y && grid_position.y < rowCount
