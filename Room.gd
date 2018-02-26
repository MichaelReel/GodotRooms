extends TileMap

var BaseLayout = load("res://RoguishGenerator.gd")

var resource
var tile_size
var room_size


func _init(resource, exits = [], gen_seed = OS.get_time().second):
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	self.set_tileset(self.resource.tileset)
	self.set_cell_size(self.tile_size)

	var baseLayout = BaseLayout.new(self.room_size, gen_seed)

	add_exits()

	draw_with_tiles(baseLayout)

func add_exits():
	pass

# scale should be no less than 3
func draw_with_tiles(baseLayout, scale = 4):
	# For each tile in the base layout draw walls and empty spaces
	# The empty space and the walls should add up the scale
	for y in self.room_size.y:
		for x in self.room_size.x:
			var base_cell = Vector2(x, y)
			var dest_cell = Rect2(base_cell * 4, Vector2(scale, scale))
			# Draw the corner and wall cells based on the surrounding base cells
			# TODO:
			#
			
			# Fill the rest with path squares
			for ry in range(dest_cell.position.y, dest_cell.end.y):
				for rx in range(dest_cell.position.x, dest_cell.end.x):
					if baseLayout.get_cellv(base_cell) != TileMap.INVALID_CELL:
						self.set_cell(rx, ry, self.resource.walls[0])

