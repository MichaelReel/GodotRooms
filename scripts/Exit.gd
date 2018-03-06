extends StaticBody2D

var resource
var cellv

# Set these to determine where this exit goes
var room_x
var room_y
var destination

func _init(resource):
	self.resource = resource
	# Create Sprite
	var templates = resource.get_node("SpritePool")
	var exit_sprite = templates.get_node("Exit")
	var sprite = exit_sprite.duplicate()
	sprite.visible = true
	add_child(sprite)

	# Add collsion body
	var collision = CollisionShape2D.new()
	collision.position = Vector2(8, 8)
	collision.shape = RectangleShape2D.new()
	collision.shape.extents = Vector2(8, 8)
	add_child(collision)


