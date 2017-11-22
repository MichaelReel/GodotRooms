extends Node2D

var resource
var tile_size
var room_size

var base_map
var base_vertices = []
var base_vert_min
var base_vert_max

func init_map():
	var map = TileMap.new()
	
	map.set_tileset(self.resource.tileset)
	map.set_cell_size(self.tile_size)
	
	self.add_child(map, true)
	
	return map

func _init(resource):
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	
	self.base_map = init_map()
	self.generate_content()

func generate_content():
	self.basic_perlin_fill()
	self.set_tiles_from_vertices()

func basic_perlin_fill():
	var min_b1 = 0
	var max_b1 = 0
	
	for corner_x in range(self.room_size.x + 1):
		self.base_vertices.append([])
		for corner_y in range(self.room_size.y + 1):
			var b1 = resource.base_fbm.fractal2d(3, 1.2, corner_x, corner_y, 0, 8)
			min_b1 = min(min_b1, b1)
			max_b1 = max(max_b1, b1)
			self.base_vertices[corner_x].append(b1)
	
	print ("min_b1 = " + str(min_b1))
	print ("max_b1 = " + str(max_b1))
	
	self.base_vert_min = min_b1
	self.base_vert_max = max_b1

func set_tiles_from_vertices():
	var total_cells_set = 0
	for limit in [(self.base_vert_min / 2), 0, (self.base_vert_max / 2), 1]:
		print ("limit = " + str(limit))
		var cells_set = 0
		for tile_y in range(self.room_size.y):
			for tile_x in range(self.room_size.x):
				if self.base_map.get_cell(tile_x, tile_y) == TileMap.INVALID_CELL:
					var base_score = get_corner_score(self.base_vertices, limit, tile_x, tile_y)
					if (base_score < 15):
						cells_set += 1
						self.base_map.set_cell(tile_x, tile_y, resource.walls[base_score])
		print ("cells_set = " + str(cells_set))
		total_cells_set += cells_set
	print ("total_cells_set = " + str(total_cells_set))

func get_corner_score(grid, limit, x, y):
	var score = 0
	
	# Bottom right
	if grid[x + 1][y + 1] > limit:
		score += 1 
	
	# Bottom left
	if grid[x][y + 1] > limit:
		score += 2
	
	# Top right
	if grid[x + 1][y] > limit:
		score += 4
	
	# Top left
	if grid[x][y] > limit:
		score += 8
	
	return score

func _exit_tree():
	self.base_map.queue_free();
