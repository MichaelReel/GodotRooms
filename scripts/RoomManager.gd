extends Node2D

var Room = load("res://scripts/Room.gd")
var Exit = load("res://scripts/Exit.gd")
var rooms = []

var resource
var current_room

var nav_node
var player_node
var cam_node
var overlay

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
	overlay     = get_node("../TransitionOverlay")
	
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
			if ry > 0:        exit_flag |= 1 << Exit.EXIT_TOP
			if ry < ry_limit: exit_flag |= 1 << Exit.EXIT_BOTTOM
			if rx > 0:        exit_flag |= 1 << Exit.EXIT_LEFT
			if rx < rx_limit: exit_flag |= 1 << Exit.EXIT_RIGHT
			var new_room = Room.new(resource, exit_flag, randi())
			rooms[ry].append(new_room)
			add_child(new_room, true)

	# Connect rooms by exits
	# TODO: This is still based on the above prototype
	#TL   y  x                                   y  x         y  x
	rooms[0][0].set_exit(Exit.EXIT_BOTTOM, rooms[1][0], Exit.EXIT_TOP)
	rooms[0][0].set_exit(Exit.EXIT_RIGHT,  rooms[0][1], Exit.EXIT_LEFT)
	#TR
	rooms[0][1].set_exit(Exit.EXIT_BOTTOM, rooms[1][1], Exit.EXIT_TOP)
	rooms[0][1].set_exit(Exit.EXIT_LEFT,   rooms[0][0], Exit.EXIT_RIGHT)
	#BL
	rooms[1][0].set_exit(Exit.EXIT_TOP,    rooms[0][0], Exit.EXIT_BOTTOM)
	rooms[1][0].set_exit(Exit.EXIT_RIGHT,  rooms[1][1], Exit.EXIT_LEFT)
	#BR
	rooms[1][1].set_exit(Exit.EXIT_TOP,    rooms[0][1], Exit.EXIT_BOTTOM)
	rooms[1][1].set_exit(Exit.EXIT_LEFT,   rooms[1][0], Exit.EXIT_RIGHT)
	
	for ry in ry_limit + 1:
		for rx in rx_limit + 1:
			rooms[ry][rx].enable_room(false, 0)
			print("[", ry, "][", rx, "] = ", rooms[ry][rx])

	# Set starting room:
	var new_room = rooms[0][0]
	set_current_room(new_room, new_room.spawn, Vector2())

func set_current_room(room, entrance, dir):
	# Setup overlay transition
	var fade_time = 0.2
	overlay.setup_transition(dir, cam_node, fade_time)

	# Change the current room
	if current_room: current_room.enable_room(false, fade_time)
	current_room = room
	current_room.enable_room(true, fade_time)

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
	var dir = exit.dir_v
	set_current_room(room, entrance, dir)

# var debug_timer = 1.0

# func _process(delta):
# 	debug_timer -= delta
# 	if debug_timer <= 0.0:
# 		var active_cam = cam_node
# 		var over_cam = overlay.get_node("Camera2D")
# 		if over_cam and over_cam.current: active_cam = over_cam
# 		print ("debug_timer: ", debug_timer)
# 		print ("Camera position: ", active_cam.get_camera_position())
# 		print ("Camera screen center: ", active_cam.get_camera_screen_center())
# 		debug_timer += 1.0