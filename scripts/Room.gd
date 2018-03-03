extends TileMap

var BaseLayout = load("res://scripts/RoguishGenerator.gd")

var resource
var tile_size
var room_size
var limit_right
var limit_bottom

var nav
var exits = []
var spawn

func _init(resource, exit_dirs = [], gen_seed = OS.get_time().second, scale = 2):
	self.exits = exit_dirs
	seed(gen_seed)
	
	self.resource = resource
	self.tile_size = resource.tile_size
	self.room_size = resource.average_room_size
	self.limit_right = self.room_size.x * scale * self.tile_size.x
	self.limit_bottom = self.room_size.y * scale * self.tile_size.y

	self.set_tileset(self.resource.tileset)
	self.set_cell_size(self.tile_size)
	var baseLayout = BaseLayout.new(self.room_size, gen_seed)

	var path_tile = self.resource.walls[0]
	draw_path(baseLayout, scale, path_tile)
	add_exits()
	create_navigation(scale)
	draw_walls(baseLayout, scale, path_tile)

	var pois = create_POIs(baseLayout, scale)
	populate_POIs(pois)

	# setup_debug_draw()

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
			
			# Fill the path squares
			if baseLayout.get_cellv(base_cell) != TileMap.INVALID_CELL:
				for ry in range(dest_cell.position.y, dest_cell.end.y):
					for rx in range(dest_cell.position.x, dest_cell.end.x):
							self.set_cell(rx, ry, path_tile)

func draw_walls(baseLayout, scale, path_tile):
	for y in self.room_size.y * scale:
		for x in self.room_size.x * scale:
			var dest_cell = Vector2(x, y)
			# Score and set walls
			if get_cellv(dest_cell) == TileMap.INVALID_CELL:
				var score = get_corner_scores(self, dest_cell, path_tile)
				if score == 0: continue
				self.set_cellv(dest_cell, self.resource.walls[score])


func create_navigation(scale):
	self.nav = NavigationPolygon.new()
	# Get a list of top left corners
	var start_cells = get_start_cells(scale)

	# while start_cells.size() > 0:
	while not start_cells.empty():
		var outlines = PoolVector2Array()
		var start_cell = start_cells.pop_front()
		self.dir = 0
		outlines.push_back(Vector2(start_cell.x * self.tile_size.x, start_cell.y * self.tile_size.y))
		var cellv = travel(start_cell, get_cellv(start_cell))
		while start_cell.distance_to(cellv) > 0.1:
			# check we don't have an extra start point for this polygon
			if start_cells.has(cellv): start_cells.erase(cellv)
			# add cell to the current polygon
			outlines.push_back(Vector2(cellv.x * self.tile_size.x, cellv.y * self.tile_size.y))
			cellv = travel(cellv, get_cellv(start_cell))
		nav.add_outline(outlines)

	nav.make_polygons_from_outlines()

func get_start_cells(scale):
	# This will collect all potential start cells
	# There may be more than one per area, but we'll deal with that later
	var start_cells = []
	var left_mod = Vector2(-1,0)
	var up_mod = Vector2(0,-1)

	for y in self.room_size.y * scale:
		for x in self.room_size.x * scale:
			# We're looking for top-left corners
			var cellv = Vector2(x, y)
			var cell = get_cellv(cellv)
			var left = get_cellv(cellv + left_mod)
			var up = get_cellv(cellv + up_mod)
			var up_left = get_cellv(cellv + left_mod + up_mod)
			if left == up_left && up_left == up && left != cell:
				start_cells.append(cellv)
	return start_cells

var dir
var dirs = [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]
#                               *                         a b 
#                 a             |[]       b                ^  
#             *-->              v          <--*            |  
#              [] b            b a        a    []          *  
#                                                           []
# a - populated => anti-clockwise => dir_ind --
# a - empty, b - populated => ahead => dir_ind ==
# a - empty, b - empty => clockwise => dir_ind ++

func travel(last_cell, path_tile):
	# We're going in the direction of 'dir' anyway
	var next_cell = last_cell + dirs[dir]
	# Figure out where we're going after that
	var a
	var b
	match dir:
		0: # Right
			a = next_cell + dirs[3]
			b = next_cell
		1: # Down
			a = next_cell
			b = next_cell + dirs[2]
		2: # Left
			a = next_cell + dirs[2]
			b = a + dirs[3]
		3: # Up
			b = next_cell + dirs[3]
			a = b + dirs[2]

	if self.get_cellv(a) == path_tile:
		dir = (dir + 3) % 4
	elif self.get_cellv(b) == path_tile:
		pass
	else:
		dir = (dir + 1) % 4
	return next_cell


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

func setup_debug_draw():
	var debug_polys = []
	for i in self.nav.get_outline_count():
		debug_polys.append(self.nav.get_outline(i))

	var DebugDrawer = load("res://scripts/DebugPolys.gd")
	var debug = DebugDrawer.new(debug_polys)

	self.add_child(debug)

func create_POIs(baseLayer, scale):
	var pois = []
	# Create one random spot in each box
	for box in baseLayer.boxes:
		var vec = Vector2()
		vec.x = ((randi() % int(box.size.x - 2)) + box.position.x + 1) * self.tile_size.x
		vec.y = ((randi() % int(box.size.y - 2)) + box.position.y + 1) * self.tile_size.y
		pois.append(vec * scale)
	return pois

func populate_POIs(pois):
	var templates = self.resource.get_node("SpritePool")
	var default = templates.get_node("Default")

	while not pois.empty():
		# Create a random resource, base, spawn, etc.
		var poi = pois.pop_back()
		if not spawn:
			if pois.size() == 0 || randi() % pois.size() == pois.size():
				spawn = poi
				continue

		var s = default.duplicate()
		s.position = poi
		add_child(s)
		s.visible = true