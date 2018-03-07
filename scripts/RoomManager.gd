extends Node2D

var Room = load("res://scripts/Room.gd")
var rooms = []

var resource
var current_room

var nav_node
var player_node
var cam_node

func _ready():
	print("readying room manager")
	
	# Get the defining root game attributes
	resource = $RoomResource
	var world_seed = hash(resource.map_name)
	seed(world_seed)

	# Get the navigation and view nodes
	nav_node    = get_node("../Navigation2D/navpoly")
	player_node = get_node("../Navigation2D/Robot")
	cam_node    = get_node("../Navigation2D/Robot/Camera2D")
	
	create_room_set()

func create_room_set():
	# Need a group of rooms arranged with maps to other rooms
	# Create map/maze of rooms first, then create each "room"

	# TODO: For now just creating 4 interconnected rooms to help prototype the teleport mechanism
	var ry_limit = 1
	var rx_limit = 1
	for ry in ry_limit + 1:
		rooms.append([])
		for rx in rx_limit + 1:
			# Exit flags are (1:top, 2:bottom, 3:left, 4:right, 5: up, 6: down)
			var exit_flag = 0
			if ry > 0:        exit_flag |= 1 << Room.EXIT_TOP
			if ry < ry_limit: exit_flag |= 1 << Room.EXIT_BOTTOM
			if rx > 0:        exit_flag |= 1 << Room.EXIT_LEFT
			if rx < rx_limit: exit_flag |= 1 << Room.EXIT_RIGHT
			var new_room = Room.new(resource, exit_flag, randi())
			rooms[ry].append(new_room)
			add_child(new_room, true)

	# Connect rooms by exits
	# TODO: This is still based on the above prototype
	#TL   y  x                                   y  x         y  x
	rooms[0][0].set_exit(Room.EXIT_BOTTOM, rooms[1][0], rooms[1][0].exits[Room.EXIT_TOP])
	rooms[0][0].set_exit(Room.EXIT_RIGHT,  rooms[0][1], rooms[0][1].exits[Room.EXIT_LEFT])
	#TR
	rooms[0][1].set_exit(Room.EXIT_BOTTOM, rooms[1][1], rooms[1][1].exits[Room.EXIT_TOP])
	rooms[0][1].set_exit(Room.EXIT_LEFT,   rooms[0][0], rooms[0][0].exits[Room.EXIT_RIGHT])
	#BL
	rooms[1][0].set_exit(Room.EXIT_TOP,    rooms[0][0], rooms[0][0].exits[Room.EXIT_BOTTOM])
	rooms[1][0].set_exit(Room.EXIT_RIGHT,  rooms[1][1], rooms[1][1].exits[Room.EXIT_LEFT])
	#BR
	rooms[1][1].set_exit(Room.EXIT_TOP,    rooms[0][1], rooms[0][1].exits[Room.EXIT_BOTTOM])
	rooms[1][1].set_exit(Room.EXIT_LEFT,   rooms[1][0], rooms[1][0].exits[Room.EXIT_RIGHT])
	
	for ry in ry_limit + 1:
		for rx in rx_limit + 1:
			rooms[ry][rx].enable_room(false)

	# Set starting room:
	var new_room = rooms[0][0]
	set_current_room(new_room, new_room.spawn)

func set_current_room(room, entrance):
	print (current_room, "->", room)
	if current_room: current_room.enable_room(false)
	current_room = room
	current_room.enable_room(true)

	# Get the navigation for the room
	nav_node.navpoly = current_room.nav
	nav_node.enabled = false
	nav_node.enabled = true

	# Set the camera bounds (top and left are set to 0)
	cam_node.limit_right = int(current_room.limit_right)
	cam_node.limit_bottom = int(current_room.limit_bottom)

	# Put the player character in the correct place
	player_node.position = entrance

func change_room(exit):
	var room = exit.room
	var entrance = exit.destination
	set_current_room(room, entrance)
