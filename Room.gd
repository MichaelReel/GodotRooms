extends Node2D

var resource
var tile_size
var room_size

var base_map
var base_vertices = []

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
	for corner_x in range(self.room_size.x + 1):
		self.base_vertices.append([])
		for corner_y in range(self.room_size.y + 1):
			var b1 = resource.base_fbm.fractal2d(3, 1.2, corner_x, corner_y, 0, 8)
			self.base_vertices[corner_x].append(b1)

func set_tiles_from_vertices():
	var limit = -1
	var diff_limit = 0.5
	while limit <= 1:
		print (limit)
	
		for tile_y in range(self.room_size.y):
			for tile_x in range(self.room_size.x):
				if self.base_map.get_cell(tile_x, tile_y) == TileMap.INVALID_CELL:
					var base_score = get_corner_score(self.base_vertices, limit, tile_x, tile_y)
					if (base_score < 15):
						self.base_map.set_cell(tile_x, tile_y, resource.walls[base_score])
		limit += diff_limit

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
