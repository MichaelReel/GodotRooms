extends TileMap

# This can be used to create the basis of a rogue style map
# In the created map the squares marked 0 are considered to
# be path and -1 are considered impassible

var map_bounds

var connected_cells = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
var dirs = [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]

func _init(room_size, gen_seed = OS.get_time().second):

	self.map_bounds = Rect2(Vector2(), room_size)

	draw_random_boxes(1)
	generate_mazes(2)
	connect_areas(1, 2, 0)
	remove_dead_ends()

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
	var roomExtraSize = 1 # Increasing this allows some rooms to be larger.
	var roomMin = 1 # Increasing this makes all rooms bigger (and fewer)

	var size = (roomMin + randi() % (3 + roomExtraSize)) * 2 + 1
	var rectangularity = randi() % (roomMin + int(size / 2)) * 2
	var width = size
	var height = size
	if randi() % 2 == 0:
	  width += rectangularity
	else:
	  height += rectangularity
	
	var x = randi() % int((self.map_bounds.size.x - width) / 2) * 2 + 1
	var y = randi() % int((self.map_bounds.size.y - height) / 2) * 2 + 1

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
			self.set_cellv(new_pos, tile)

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
	self.set_cellv(start, tile)
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
		var cell_at = self.get_cellv(new_pos)
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
	self.set_cellv(pos, tile)
	for dpos in get_dirs_rand_order():
		var new_pos = pos + dpos
		var cell_at = self.get_cellv(new_pos)
		if cell_at == tile:
			# draw path to cell and stop
			while 1 <= (new_pos - pos).length():
				self.set_cellv(new_pos, tile)
				new_pos -= dpos.normalized()
			return
	
func find_next_empty():
	# Find an odd vector starting position
	for y in range(1,self.map_bounds.size.y,2):
		for x in range(1,self.map_bounds.size.x,2):
			if self.get_cell(x, y) == -1:
				return Vector2(x, y)
	return null

#####################################
# connect all the unconnected areas #
#####################################

func connect_areas(box_tile, maze_tile, tile):
	var connectors = find_connection_tiles(box_tile, maze_tile)
	var fill_frontier = []
	var connector_frontier = []

	# Set the first random maze tile to be in the final region
	var pos = Vector2(randi() % int(self.map_bounds.size.x), randi() % int(self.map_bounds.size.y))
	while self.get_cellv(pos) != maze_tile:
		pos.x = randi() % int(self.map_bounds.size.x)
		pos.y = randi() % int(self.map_bounds.size.y)
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
	self.set_cellv(pos, tile)
	for dpos in self.connected_cells:
		var new_pos = pos + dpos
		var cell_at = self.get_cellv(new_pos)
		if cell_at != TileMap.INVALID_CELL && cell_at != tile:
			fill_frontier.append(new_pos)
		elif connectors.has(new_pos) && not is_already_connected(new_pos, tile):
			# As long as the new connector is not being surrounded by cells already
			connector_frontier.append(new_pos)

func find_connection_tiles(box_tile, maze_tile):
	var connections = []
	for y in range(1, self.map_bounds.size.y - 1):
		for x in range(1, self.map_bounds.size.x - 1):
			# If the tile isn't empty, it's not a connector
			var pos = Vector2(x, y)
			if self.get_cellv(pos) != TileMap.INVALID_CELL: continue
			# Only collect areas that join a box to another box or maze
			if can_make_connection_to_region(pos, box_tile, maze_tile):
				connections.append(pos)
	return connections

func can_make_connection_to_region(pos, tile, region_tile):
	var loose_cells = 0
	var region_cells = 0
	for dpos in self.connected_cells:
		var cell_at = self.get_cellv(pos + dpos)
		if cell_at == tile: loose_cells += 1
		if cell_at == region_tile: region_cells += 1
	if loose_cells >= 1 && loose_cells + region_cells > 1:
		return true
	return false

func is_already_connected(connector, region_tile):
	var region_cells = 0
	for dpos in self.connected_cells:
		var cell_at = self.get_cellv(connector + dpos)
		if cell_at == region_tile: region_cells += 1
	if region_cells > 1:
		return true
	return false

########################
# Remove the dead ends #
########################

func remove_dead_ends():
	var removed_count = 1
	while removed_count > 0:
		removed_count = 0
		for y in self.map_bounds.size.y:
			for x in self.map_bounds.size.x:
				# If this cell isn't a path, ignore
				var cell = Vector2(x, y)
				if self.get_cellv(cell) == TileMap.INVALID_CELL:
					continue
				# Count the "walls" of this cell
				var walls = 0
				for dpos in self.connected_cells:
					var possible_wall = cell + dpos
					if self.get_cellv(possible_wall) == TileMap.INVALID_CELL:
						walls += 1
				# Clear (and count) all cells that are surrounded on 3 sides
				if walls >= 3:
					self.set_cellv(cell, TileMap.INVALID_CELL)
					removed_count += 1
