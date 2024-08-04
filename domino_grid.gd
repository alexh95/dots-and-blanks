extends Node2D

const cellSize = 64
const halfCellSize = cellSize / 2
const verticalCellOffset = Vector2i(halfCellSize, cellSize)
const horizontalCellOffset = Vector2i(cellSize, halfCellSize)

const rowCount = 6
const colCount = 5
#const gridCenter = Vector2i(colCount, rowCount) / 2

const gridSize = cellSize * Vector2i(colCount, rowCount)
const offset = -gridSize / 2

const rowLinesCount = rowCount + 1
const colLinesCount = colCount + 1

const hardLineColor = Color(0.6, 0.6, 0.6, 1.0)
const hardLineWidth = 4.0
const softLineColor = Color(0.6, 0.6, 0.6, 0.2)
const softLineWidth = 2.0

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

func getClosestGridPosition(screenPosition: Vector2i):
	var viewportSize = get_viewport().size
	var offsetPosition = screenPosition - (viewportSize - gridSize) / 2 
	var gridPosition = Vector2i(floor(float(offsetPosition.x) / cellSize), floor(float(offsetPosition.y) / cellSize))
	return gridPosition
	
func getGridScreenPosition(gridPosition: Vector2i):
	var viewportSize = get_viewport().size
	var screenPosition = gridPosition * cellSize - gridSize / 2
	return screenPosition
	
func isInsideGrid(gridPosition: Vector2i, vertical: bool):
	if vertical:
		return gridPosition.x >= 0 && gridPosition.x < colCount  && gridPosition.y >= 0 && gridPosition.y < rowCount - 1
	else:
		return gridPosition.x >= 0 && gridPosition.x < colCount - 1  && gridPosition.y >= 0 && gridPosition.y < rowCount
 
