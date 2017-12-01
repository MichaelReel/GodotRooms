extends Node2D

var resource
var tile_size
var room_size

var base_map

var path_length = 2

var frontier = []
var dirs = [Vector2(-path_length, 0), Vector2(path_length, 0), Vector2(0, -path_length), Vector2(0, path_length)]

func init_map():
	var map = TileMap.new()
	
	map.set_tileset(self.resource.tileset)
	map.set_cell_size(self.tile_size)
	
	self.add_child(map, true)
	
	return map

func _init(resource, gen_seed = OS.get_time().second):
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	
	self.base_map = init_map()
	seed(gen_seed)
	self.generate_content()

func generate_content():
	self.room_create()

func set_all_tiles(tile):
	for tile_y in range(self.room_size.y):
		for tile_x in range(self.room_size.x):
			self.base_map.set_cell(tile_x, tile_y, tile)

func room_create():
	# Start with no walls
	set_all_tiles(resource.walls[1])
	prims_algorithm(resource.walls[0])

func prims_algorithm(tile):
	var start_x = (randi() % int(self.room_size.x / self.path_length)) * self.path_length + int(self.path_length / 2)
	var start_y = (randi() % int(self.room_size.y / self.path_length)) * self.path_length + int(self.path_length / 2)
	var pos = Vector2(start_x, start_y)
	self.base_map.set_cellv(pos, tile)
	add_frontiers(pos, tile)
	while frontier.size() > 0:
		var ind = randi() % frontier.size()
		visit(frontier[ind], tile)
		add_frontiers(frontier[ind], tile)
		frontier.remove(ind)

func add_frontiers(pos, tile):
	for dpos in get_dirs_rand_order():
		var new_pos = pos + dpos
		var cell_at = self.base_map.get_cellv(new_pos)
		if cell_at != TileMap.INVALID_CELL && cell_at != tile && not frontier.has(new_pos):
			frontier.append(new_pos)

func get_dirs_rand_order():
	var dirs = [] + self.dirs
	var new_dirs = []
	while dirs.size()  > 0:
		var ind = randi() % dirs.size()
		new_dirs.append(dirs[ind])
		dirs.remove(ind)
	return new_dirs

func visit(pos, tile):
	self.base_map.set_cellv(pos, tile)
	for dpos in get_dirs_rand_order():
		var new_pos = pos + dpos
		var cell_at = self.base_map.get_cellv(new_pos)
		if cell_at == tile:
			# draw path to cell and stop
			while (new_pos - pos).length() >= 1:
				self.base_map.set_cellv(new_pos, tile)
				new_pos -= dpos.normalized()
			return

func _exit_tree():
	self.base_map.queue_free();
