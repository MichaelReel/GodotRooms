extends Node2D

var Room = load("res://Room.gd")

var resource
var current_room

func _ready():
	print("readying room manager")
	
	self.resource = find_node("RoomResource", false)
	
	self.current_room = Room.new(resource)
	self.add_child(self.current_room, true)
	
func _exit_tree():
	self.current_room.queue_free()