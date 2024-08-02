extends Node2D

const cellSize = 64
const rowCount = 10
const colCount = 9

const rowLinesCount = rowCount + 1
const colLinesCount = colCount + 1

const halfCellSize = cellSize / 2
const hardLineColor = Color(0.6, 0.6, 0.6, 1.0)
const hardLineWidth = 4.0
const softLineColor = Color(0.6, 0.6, 0.6, 0.2)
const softLineWidth = 2.0

func _draw():
	var viewportSize = get_viewport().size
	var offset = Vector2i(viewportSize.x - colLinesCount * cellSize, viewportSize.y - rowLinesCount * cellSize) / 2
	var rowFromX = halfCellSize
	var rowToX =  colLinesCount * cellSize - halfCellSize
	var colFromY = halfCellSize
	var colToY = rowLinesCount * cellSize - halfCellSize
	
	for row in range(rowLinesCount):
		var hardRowY = halfCellSize + cellSize * row
		draw_line(offset + Vector2i(rowFromX, hardRowY), offset + Vector2i(rowToX, hardRowY), hardLineColor, hardLineWidth)
		if (row < rowLinesCount - 1):
			var softRowY = cellSize + cellSize * row
			draw_line(offset + Vector2i(rowFromX, softRowY), offset + Vector2i(rowToX, softRowY), softLineColor, softLineWidth)
	for col in range(colLinesCount):
		var hardColX = halfCellSize + cellSize * col
		draw_line(offset + Vector2i(hardColX, colFromY), offset + Vector2i(hardColX, colToY), hardLineColor, hardLineWidth)
		if (col < colLinesCount - 1):
			var softColX = cellSize + cellSize * col
			draw_line(offset + Vector2i(softColX, colFromY), offset + Vector2i(softColX, colToY), softLineColor, softLineWidth)

func getClosestCell(x: int, y: int, vertical: bool):
	var viewportSize = get_viewport().size
	var offset = Vector2i(viewportSize.x - colLinesCount * cellSize, viewportSize.y - rowLinesCount * cellSize) / 2
	
	var gridX
	var gridY
	var alignedX
	var alignedY
	if (vertical):
		gridX = (x - offset.x + halfCellSize) / cellSize
		gridY = (y - offset.y) / cellSize
		alignedX = offset.x + cellSize * gridX
		alignedY = offset.y + halfCellSize + cellSize * gridY
	else:
		gridX = (x - offset.x) / cellSize
		gridY = (y - offset.y + halfCellSize) / cellSize
		alignedX = offset.x + halfCellSize + cellSize * gridX
		alignedY = offset.y + cellSize * gridY
	return Vector2i(alignedX, alignedY)
