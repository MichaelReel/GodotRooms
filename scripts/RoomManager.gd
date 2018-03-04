extends Node2D

var Room = load("res://scripts/Room.gd")

var resource
var current_room

var nav_node
var player_node
var cam_node

func _ready():
	print("readying room manager")
	
	# Get the defining root game attributes
	self.resource = $RoomResource
	var world_seed = hash(resource.map_name)
	seed(world_seed)

	# Get the navigation and view nodes
	self.nav_node    = get_node("../Navigation2D/navpoly")
	self.player_node = get_node("../Navigation2D/Robot")
	self.cam_node    = get_node("../Navigation2D/Robot/Camera2D")
	
	# Create new rooms
	var new_room = Room.new(resource, 15, randi())
	self.add_child(new_room, true)
	new_room.visible = false

	# Set the starter room
	set_current_room(new_room, new_room.spawn)


func set_current_room(room, entrance):
	if self.current_room: self.current_room.visible = false
	self.current_room = room
	self.current_room.visible = true

	# Get the navigation for the room
	self.nav_node.navpoly = self.current_room.nav
	self.nav_node.enabled = false
	self.nav_node.enabled = true

	# Set the camera bounds (top and left are set to 0)
	self.cam_node.limit_right = int(self.current_room.limit_right)
	self.cam_node.limit_bottom = int(self.current_room.limit_bottom)

	# Put the player character in the correct place
	self.player_node.position = entrance
