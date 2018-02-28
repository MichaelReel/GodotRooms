extends Node2D

var Room = load("res://Room.gd")

var resource
var current_room

func _ready():
	print("readying room manager")
	
	self.resource = $RoomResource
	
	self.current_room = Room.new(resource)
	self.add_child(self.current_room, true)

	var navNode = self.get_parent().get_node("Navigation2D/navpoly")
	print ("navNode: ", navNode)
	# navNode.navpoly_add(self.current_room.nav, Transform2D(0, Vector2(0,0)))
	navNode.navpoly = self.current_room.nav
	navNode.enabled = false
	navNode.enabled = true
