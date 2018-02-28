extends TileMap

var BaseLayout = load("res://RoguishGenerator.gd")

var resource
var tile_size
var room_size

var nav

func _init(resource, exits = [], gen_seed = OS.get_time().second):
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	self.set_tileset(self.resource.tileset)
	self.set_cell_size(self.tile_size)
	var baseLayout = BaseLayout.new(self.room_size, gen_seed)
	add_exits()

	var path_tile = self.resource.walls[0]
	var scale = 2
	draw_path(baseLayout, scale, path_tile)
	create_navigation(path_tile)
	draw_walls(baseLayout, scale, path_tile)

func add_exits():
	pass

# scale should be no less than 2
func draw_path(baseLayout, scale, path_tile):
	# For each tile in the base layout draw walls and empty spaces
	# The empty space and the walls should add up the scale
	for y in self.room_size.y:
		for x in self.room_size.x:
			var base_cell = Vector2(x, y)
			var dest_cell = Rect2(base_cell * scale, Vector2(scale, scale))
			
			for ry in range(dest_cell.position.y, dest_cell.end.y):
				for rx in range(dest_cell.position.x, dest_cell.end.x):
					# Fill the path squares
					if baseLayout.get_cellv(base_cell) != TileMap.INVALID_CELL:
						self.set_cell(rx, ry, path_tile)

func draw_walls(baseLayout, scale, path_tile):
	for y in self.room_size.y * scale:
		for x in self.room_size.x * scale:
			var dest_cell = Vector2(x, y)
			# Score and set walls
			if get_cellv(dest_cell) == TileMap.INVALID_CELL:
				var score = get_corner_scores(self, dest_cell, path_tile)
				if score == 0: continue
				# print (dest_cell, " : ", score)
				self.set_cellv(dest_cell, self.resource.walls[score])

func create_navigation(path_tile):
	# TODO: Do this properly
	var outlines = [PoolVector2Array([32.0, 32.0, 640.0, 32.0, 640.0, 704.0, 32.0, 704.0])]
	self.nav = NavigationPolygon.new()
	nav.add_outline(outlines)
	nav.make_polygons_from_outlines()

#                  
#   3  2      7    
#    []    6 [] 5  
#   1  0      4    
#                  

var adjoining = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1), Vector2(0,1), Vector2(1,0), Vector2(-1,0), Vector2(0,-1)]
var scorings = {
	14: [6,7], # 3 is optional
	13: [5,7], # 2 is optional
	12: [7],   # 2,3 are optional
	11: [4,6], # 1 is optional
	10: [6],   # 1,3 are option;
	9:  [0,3],
	8:  [3],
	7:  [4,5], # 0 is optional
	6:  [1,2],
	5:  [5],   # 0,2 are optional
	4:  [2],
	3:  [4],   # 0,1 are optional
	2:  [1],
	1:  [0]
}

func get_corner_scores(map, pos, tile):
	for i in scorings.keys():
		var matches = 0
		for j in scorings[i]:
			var corner = pos + adjoining[j]
			if map.get_cellv(corner) == tile:
				matches += 1
		if matches == scorings[i].size():
			return i
	return 0


