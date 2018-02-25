extends Node2D

var resource
var tile_size
var room_size

var base_map
var map_bounds

var connected_cells = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
var dirs = [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]

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
	self.map_bounds = Rect2(Vector2(), self.room_size)

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
	# Start with nothing
	# draw some random boxes on the tile map

	# From http://journal.stuffwithstuff.com/2014/12/21/rooms-and-mazes/ and 
	# https://github.com/munificent/hauberk/blob/db360d9efa714efb6d937c31953ef849c7394a39/lib/src/content/dungeon.dart
	# The random dungeon generator.
	#
	# Starting with a stage of solid walls, it works like so:
	#
	# 1. Place a number of randomly sized and positioned rooms. If a room
	#    overlaps an existing room, it is discarded. Any remaining rooms are
	#    carved out.

	draw_random_boxes(resource.walls[2])

	# 2. Any remaining solid areas are filled in with mazes. The maze generator
	#    will grow and fill in even odd-shaped areas, but will not touch any
	#    rooms.

	generate_mazes(resource.walls[1])

	# 3. The result of the previous two steps is a series of unconnected rooms
	#    and mazes. We walk the stage and find every tile that can be a
	#    "connector". This is a solid tile that is adjacent to two unconnected
	#    regions.
	# 4. We randomly choose connectors and open them or place a door there until
	#    all of the unconnected regions have been joined. There is also a slight
	#    chance to carve a connector between two already-joined regions, so that
	#    the dungeon isn't single connected.

	connect_areas(resource.walls[2], resource.walls[1], resource.walls[0])

	# 5. The mazes will have a lot of dead ends. Finally, we remove those by
	#    repeatedly filling in any open tile that's closed on three sides. When
	#    this is done, every corridor in a maze actually leads somewhere.
	# 
	# The end result of this is a multiply-connected dungeon with rooms and lots
	# of winding corridors.

#####################
# Box area creation #
#####################

func draw_random_boxes(tile):
	# randomize()
	var boxes = []
	for i in 1000:
		var box = get_random_box()
		if not box_collides(boxes, box):
			boxes.append(box)
			draw_simple_tile_box(box, tile)

func get_random_box():
	var roomExtraSize = 3 # Increasing this allows some rooms to be larger.
	var roomMin = 2 # Increasing this makes all rooms bigger (and fewer)

	var size = (roomMin + randi() % (3 + roomExtraSize)) * 2 + 1
	var rectangularity = randi() % (roomMin + int(size / 2)) * 2
	var width = size
	var height = size
	if randi() % 2 == 0:
	  width += rectangularity
	else:
	  height += rectangularity
	
	var x = randi() % int((self.room_size.x - width) / 2) * 2 + 1
	var y = randi() % int((self.room_size.y - height) / 2) * 2 + 1

	var box = Rect2(x, y, width, height)
	return box

func box_collides(boxes, box):
	for b in boxes:
		if box.intersects(b):
			return true
	return false

func draw_simple_tile_box(box, tile):
	var new_pos = Vector2()
	for y in box.size.y:
		for x in box.size.x:
			new_pos.x = box.position.x + x
			new_pos.y = box.position.y + y
			self.base_map.set_cellv(new_pos, tile)

###################
# Maze Generation #
###################

func generate_mazes(tile):
	var next_empty = find_next_empty()
	while next_empty != null:
		propagate_maze(next_empty, tile)
		next_empty = find_next_empty()

func propagate_maze(start, tile):
	var frontier = []
	self.base_map.set_cellv(start, tile)
	add_frontiers(start, tile, frontier)
	while frontier.size() > 0:
		# could favour newer or older frontier cells to affect the windiness:
		var ind = randi() % frontier.size()
		visit(frontier[ind], tile)
		add_frontiers(frontier[ind], tile, frontier)
		frontier.remove(ind)

func add_frontiers(pos, tile, frontier):
	for dpos in get_dirs_rand_order():
		var new_pos = pos + dpos
		var cell_at = self.base_map.get_cellv(new_pos)
		if cell_at == TileMap.INVALID_CELL && not frontier.has(new_pos) && map_bounds.has_point(new_pos):
			frontier.append(new_pos)

func get_dirs_rand_order():
	var dirs = [] + self.dirs
	var new_dirs = []
	while dirs.size() > 0:
		var ind = randi() % dirs.size()
		new_dirs.append(dirs[ind])
		dirs.remove(ind)
	return new_dirs

func visit(pos, tile):
	# This links a part of the existing maze path to the current cell
	self.base_map.set_cellv(pos, tile)
	for dpos in get_dirs_rand_order():
		var new_pos = pos + dpos
		var cell_at = self.base_map.get_cellv(new_pos)
		if cell_at == tile:
			# draw path to cell and stop
			while 1 <= (new_pos - pos).length():
				self.base_map.set_cellv(new_pos, tile)
				new_pos -= dpos.normalized()
			return
	
func find_next_empty():
	# Find an odd vector starting position
	for y in range(1,self.room_size.y,2):
		for x in range(1,self.room_size.x,2):
			if self.base_map.get_cell(x, y) == -1:
				return Vector2(x, y)
				# self.base_map.set_cell(x, y, tile)
	return null

#####################################
# connect all the unconnected areas #
#####################################

func connect_areas(box_tile, maze_tile, tile):
	var connectors = find_connection_tiles(box_tile, maze_tile)
	var fill_frontier = []
	var connector_frontier = []

	## DEBUG ##
	# for c in connectors:
	# 	self.base_map.set_cellv(c, resource.walls[4])
	## ----- ##
	
	# Set the first random maze tile to be in the final region
	var pos = Vector2(randi() % int(self.room_size.x), randi() % int(self.room_size.y))
	while self.base_map.get_cellv(pos) != maze_tile:
		pos.x = randi() % int(self.room_size.x)
		pos.y = randi() % int(self.room_size.y)
	fill_frontier.append(pos)

	# Work from the frontier, add any connecting tiles to the frontier.
	# Add any connecting connectors to the connection frontier

	# While we're still creating new frontiers
	while fill_frontier.size() + connectors.size() + connector_frontier.size() > 0:
		# Clear any already regionally connected squares
		# From both the connector pool and the connector frontier
		strip_regions_connected(connectors, tile)
		strip_regions_connected(connector_frontier, tile)
		
		# Flood fill using the current frontier list
		# (we actually start the loop here)
		while fill_frontier.size() > 0:
			fill_visit(fill_frontier, connectors, connector_frontier, tile)

		# Modify one (or some) of the frontier connectors to become the new frontier
		if connector_frontier.size() > 1:
			var connector = connector_frontier[randi() % connector_frontier.size()]
			fill_frontier.append(connector)
			fill_visit(fill_frontier, connectors, connector_frontier, tile)
		
func strip_regions_connected(list, region_tile):
	for c in list:
		if is_already_connected(c, region_tile):
			list.erase(c)

func fill_visit(fill_frontier, connectors, connector_frontier, tile):
	var pos = fill_frontier.pop_back()
	self.base_map.set_cellv(pos, tile)
	for dpos in self.connected_cells:
		var new_pos = pos + dpos
		var cell_at = self.base_map.get_cellv(new_pos)
		if cell_at != TileMap.INVALID_CELL && cell_at != tile:
			fill_frontier.append(new_pos)
		elif connectors.has(new_pos) && not is_already_connected(new_pos, tile):
			# As long as the new connector is not being surrounded by cells already
			connector_frontier.append(new_pos)
			# connectors.erase(new_pos)


func find_connection_tiles(box_tile, maze_tile):
	var connections = []
	for y in range(1, self.room_size.y - 1):
		for x in range(1, self.room_size.x - 1):
			# If the tile isn't empty, it's not a connector
			var pos = Vector2(x, y)
			if self.base_map.get_cellv(pos) != TileMap.INVALID_CELL: continue
			# Only collect areas that join a box to another box or maze
			if can_make_connection_to_region(pos, box_tile, maze_tile):
				connections.append(pos)
	return connections

func can_make_connection_to_region(pos, tile, region_tile):
	var loose_cells = 0
	var region_cells = 0
	for dpos in self.connected_cells:
		var cell_at = self.base_map.get_cellv(pos + dpos)
		if cell_at == tile: loose_cells += 1
		if cell_at == region_tile: region_cells += 1
	if loose_cells >= 1 && loose_cells + region_cells > 1:
		return true
	return false

func is_already_connected(connector, region_tile):
	var region_cells = 0
	for dpos in self.connected_cells:
		var cell_at = self.base_map.get_cellv(connector + dpos)
		if cell_at == region_tile: region_cells += 1
	if region_cells > 1:
		return true
	return false

# TODO: Don't recall why I'm doing this, better look at the documentation:
func _exit_tree():
	self.base_map.queue_free()
