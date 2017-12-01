extends Node2D

var resource
var tile_size
var room_size

var base_map

func init_map():
	var map = TileMap.new()
	
	map.set_tileset(self.resource.tileset)
	map.set_cell_size(self.tile_size)
	
	self.add_child(map, true)
	
	return map

func _init(resource, gen_seed = 1):
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	
	self.base_map = init_map()
	seed(gen_seed)
	self.generate_content()

func generate_content():
	self.room_create()

func room_create():
	for tile_y in range(self.room_size.y):
		for tile_x in range(self.room_size.x):
			# Start with no walls
			self.base_map.set_cell(tile_x, tile_y, resource.walls[0])
	var border = Rect2(0,0,self.room_size.x - 1,self.room_size.y - 1)
	for bounds in random_rect_breakdown(border):
		var rand = randi()%3
		if rand < 2:
			draw_rect_feature(self.base_map, bounds, (rand == 1))
	draw_rect_feature(self.base_map, border, true)

func draw_rect_feature(room, bounds, dropped = true):
	room.set_cell(bounds.pos.x, bounds.pos.y, resource.walls[14 if dropped else 01])
	room.set_cell(bounds.pos.x, bounds.end.y, resource.walls[11 if dropped else 04])
	room.set_cell(bounds.end.x, bounds.pos.y, resource.walls[13 if dropped else 02])
	room.set_cell(bounds.end.x, bounds.end.y, resource.walls[07 if dropped else 08])
	for tile_y in range(bounds.pos.y + 1, bounds.end.y):
		room.set_cell(bounds.pos.x, tile_y, resource.walls[10 if dropped else 05])
		room.set_cell(bounds.end.x, tile_y, resource.walls[05 if dropped else 10])
	for tile_x in range(bounds.pos.x + 1, bounds.end.x):
		room.set_cell(tile_x, bounds.pos.y, resource.walls[12 if dropped else 03])
		room.set_cell(tile_x, bounds.end.y, resource.walls[03 if dropped else 12])

func random_rect_breakdown(bounds, choice = 1):
	var bounds_list = [bounds]
	# if any of the bounds are too small already, don't split further
	if bounds.size.x > 5 and bounds.size.y > 5:
#		# Split, Horizontal (1) or vertical (2), or don't split at all (0)
#		var choice = randi()%2 + 1 # %3
		if choice == 1:
			var split_x_line = randi() % int(bounds.size.x - 4) + 2
			bounds_list += random_rect_breakdown(Rect2(bounds.pos.x + 1, bounds.pos.y + 1, split_x_line - 1, bounds.size.y - 2), 2)
			bounds_list += random_rect_breakdown(Rect2(bounds.pos.x + split_x_line + 1, bounds.pos.y + 1, bounds.size.x - split_x_line - 2, bounds.size.y  - 2), 2)
		elif choice == 2:
			var split_y_line = randi() % int(bounds.size.y - 4) + 2
			bounds_list += random_rect_breakdown(Rect2(bounds.pos.x + 1, bounds.pos.y + 1, bounds.size.x - 2, split_y_line - 1), 1)
			bounds_list += random_rect_breakdown(Rect2(bounds.pos.x + 1, bounds.pos.y + split_y_line + 1, bounds.size.x - 2, bounds.size.y - split_y_line - 2), 1)
	
	return bounds_list

func _exit_tree():
	self.base_map.queue_free();
