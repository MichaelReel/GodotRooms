extends TileMap

var BaseLayout = load("res://scripts/RoguishGenerator.gd")
var Exit = load("res://scripts/Exit.gd")

var resource
var tile_size
var base_size
var room_size
var limit_right
var limit_bottom
var templates

const EXIT_TOP = 0
const EXIT_BOTTOM = 1
const EXIT_LEFT = 2
const EXIT_RIGHT = 3
const EXIT_UP = 4
const EXIT_DOWN = 5

const EXIT_DIRS = ["top", "bottom", "left", "right", "up", "down"]
var exits = [null, null, null, null, null, null]
var spawn

var nav

func _init(resource, exit_flags = 0, gen_seed = OS.get_time().second, scale = 2):
	seed(gen_seed)
	
	self.resource = resource
	self.tile_size = resource.tile_size
	self.base_size = resource.average_base_size
	self.room_size = self.base_size * scale
	self.limit_right = self.room_size.x * self.tile_size.x
	self.limit_bottom = self.room_size.y * self.tile_size.y

	self.templates = resource.get_node("SpritePool")

	self.set_tileset(resource.tileset)
	self.set_cell_size(self.tile_size)
	var baseLayout = BaseLayout.new(self.base_size, gen_seed)

	var path_tile = resource.walls[0]
	draw_path(baseLayout, scale, path_tile)
	add_exits(exit_flags)
	create_navigation(scale)
	draw_walls(baseLayout, scale, path_tile)

	var pois = create_POIs(baseLayout, scale)
	populate_POIs(pois)

	# setup_debug_draw()

func add_exits(exit_flags):
	for i in EXIT_DIRS.size():
		var flag = int(pow(2, i))
		if flag & exit_flags:
			self.exits[i] = Exit.new(self.resource)

			# Need to add a sprite for the exit
			add_child(self.exits[i])
			# Find the exit position
			var cellv = get_exit_pos(i)
			self.exits[i].cellv = cellv
			var position = Vector2(cellv.x * self.tile_size.x, cellv.y * self.tile_size.y)
			self.exits[i].position = position

	var exit_strs = ""
	for e in exits:
		exit_strs += e.details() + ", " if e else str(e) + ", "
	exit_strs = exit_strs.substr(0, exit_strs.length() - 2)
	print(self, " has exits: ", exit_strs)


func set_exit(exit_ind, target_room, target_exit_ind):
	# Set the destination room and position
	var exit = exits[exit_ind]
	exit.room = target_room
	var target_exit = target_room.exits[target_exit_ind]
	# TODO: This'll likely suck for up and down connections
	var dest_inc = exit_incursion(target_exit_ind)
	exit.destination = target_exit.position + Vector2(dest_inc.x * tile_size.x, dest_inc.y * tile_size.y)
	print (exit, ":", EXIT_DIRS[exit_ind], " connected to exit ", target_exit, " in room ", exit.room, " position ", exit.destination)


func get_exit_pos(i):
	var cellv = exit_start(i)
	var inc = exit_incursion(i)
	# add inc to start until we find a suitable tile
	# TODO: This likely sucks for UP and DOWN portals
	var limit = 10
	while get_cellv(cellv) == TileMap.INVALID_CELL and limit: 
		cellv += inc
		limit -= 1
	return cellv

func exit_start(i):
	var cellv
	match i:
		EXIT_TOP:
			cellv = Vector2(int(room_size.x / 2), 0)
		EXIT_BOTTOM:
			cellv = Vector2(int(room_size.x / 2), room_size.y)
		EXIT_LEFT:
			cellv = Vector2(0, int(room_size.y / 2))
		EXIT_RIGHT:
			cellv = Vector2(room_size.x, int(room_size.y / 2))
		EXIT_UP:
			cellv = Vector2(int(room_size.x / 2), int(room_size.y / 2) - 1)
		EXIT_DOWN:
			cellv = Vector2(int(room_size.x / 2), int(room_size.y / 2) + 1)
	return cellv

func exit_incursion(i):
	var inc
	match i:
		EXIT_TOP:
			inc = Vector2(0, 1)
		EXIT_BOTTOM:
			inc = Vector2(0, -1)
		EXIT_LEFT:
			inc = Vector2(1, 0)
		EXIT_RIGHT:
			inc = Vector2(-1, 0)
		EXIT_UP:
			inc = Vector2(0, -1)
		EXIT_DOWN:
			inc = Vector2(0, 1)
	return inc

# scale should be no less than 2
func draw_path(baseLayout, scale, path_tile):
	# For each tile in the base layout draw walls and empty spaces
	# The empty space and the walls should add up the scale
	for y in self.base_size.y:
		for x in self.base_size.x:
			var base_cell = Vector2(x, y)
			var dest_cell = Rect2(base_cell * scale, Vector2(scale, scale))
			
			# Fill the path squares
			if baseLayout.get_cellv(base_cell) != TileMap.INVALID_CELL:
				for ry in range(dest_cell.position.y, dest_cell.end.y):
					for rx in range(dest_cell.position.x, dest_cell.end.x):
							self.set_cell(rx, ry, path_tile)

func draw_walls(baseLayout, scale, path_tile):
	for y in self.room_size.y:
		for x in self.room_size.x:
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

	for y in self.room_size.y:
		for x in self.room_size.x:
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
	var default = self.templates.get_node("Default")

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

func enable_room(enable):
	var pre = ("en" if enable else "dis")
	print (pre, "abling room ", self)
	visible = enable
	for exit in exits:
		if exit:
			exit.set_collision_layer_bit(0, enable)
			print (pre, "abling exit ", exit, " : ", exit.get_collision_layer_bit(0))