extends Node2D

var resource
var tile_size
var room_size
var min_area_size = Vector2(3,3)

var base_map

var path_length = 2

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

	draw_random_boxes(resource.walls[0])

	# 2. Any remaining solid areas are filled in with mazes. The maze generator
	#    will grow and fill in even odd-shaped areas, but will not touch any
	#    rooms.
	# 3. The result of the previous two steps is a series of unconnected rooms
	#    and mazes. We walk the stage and find every tile that can be a
	#    "connector". This is a solid tile that is adjacent to two unconnected
	#    regions.
	# 4. We randomly choose connectors and open them or place a door there until
	#    all of the unconnected regions have been joined. There is also a slight
	#    chance to carve a connector between two already-joined regions, so that
	#    the dungeon isn't single connected.
	# 5. The mazes will have a lot of dead ends. Finally, we remove those by
	#    repeatedly filling in any open tile that's closed on three sides. When
	#    this is done, every corridor in a maze actually leads somewhere.
	# 
	# The end result of this is a multiply-connected dungeon with rooms and lots
	# of winding corridors.

func draw_random_boxes(tile):
	# randomize()
	var boxes = []
	for i in 1000:
		var box = get_random_box()
		if not box_collides(boxes, box):
			boxes.append(box)
			draw_simple_tile_box(box, tile)

func get_random_box():
	# var box = Rect2()
	# box.position.x = randi() % (int(self.room_size.x) - 3) + 1
	# box.size.x = randi() % (int(self.room_size.x) - int(box.position.x) - 1) 
	# box.position.y = randi() % (int(self.room_size.y) - 3) + 1
	# box.size.y = randi() % (int(self.room_size.y) - int(box.position.y) - 1)
	# return box

	var roomExtraSize = 5 # Increasing this allows some rooms to be larger.
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
	var footprint = box.grow(1)
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


func _exit_tree():
	self.base_map.queue_free();
