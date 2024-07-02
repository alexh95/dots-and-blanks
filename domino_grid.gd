extends Node2D

const cellSize = 64
const halfCellSize = cellSize / 2
const hardLineColor = Color(0.6, 0.6, 0.6, 1.0)
const hardLineWidth = 4.0
const softLineColor = Color(0.6, 0.6, 0.6, 0.2)
const softLineWidth = 2.0

func _draw():
	var viewportSize = get_viewport().size
	var rowCount = 1 + (viewportSize.y - cellSize) / cellSize;
	var colCount = 1 + (viewportSize.x - cellSize) / cellSize;
	
	for row in range(rowCount):
		var hardLineY = halfCellSize + cellSize * row
		draw_line(Vector2(halfCellSize, hardLineY), Vector2(colCount * cellSize - halfCellSize, hardLineY), hardLineColor, hardLineWidth)
		if (row < rowCount - 1):
			var softLineY = cellSize + cellSize * row
			draw_line(Vector2(halfCellSize, softLineY), Vector2(colCount * cellSize - halfCellSize, softLineY), softLineColor, softLineWidth)
	for col in range(colCount):
		var hardLineX = halfCellSize + cellSize * col
		draw_line(Vector2(hardLineX, halfCellSize), Vector2(hardLineX, rowCount * cellSize - halfCellSize), hardLineColor, hardLineWidth)
		if (col < colCount - 1):
			var softLineX = cellSize + cellSize * col
			draw_line(Vector2(softLineX, halfCellSize), Vector2(softLineX, rowCount * cellSize - halfCellSize), softLineColor, softLineWidth)

func getClosestCell(x: int, y: int, vertical: bool):
	var viewportSize = get_viewport().size
	var gridX
	var gridY
	var alignedX
	var alignedY
	if (vertical):
		gridX = (x + halfCellSize) / cellSize
		gridY = y / cellSize
		alignedX = cellSize * gridX
		alignedY = halfCellSize + cellSize * gridY
	else:
		gridX = x / cellSize
		gridY = (y + halfCellSize) / cellSize
		alignedX = halfCellSize + cellSize * gridX
		alignedY = cellSize * gridY
	return Vector2i(alignedX, alignedY)
